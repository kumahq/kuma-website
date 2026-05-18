---
title: MeshService
description: Define service destinations with MeshService for traffic routing, hostname assignment, and policy targeting.
keywords:
  - MeshService
  - service discovery
  - traffic routing
---

{% if_version lte:2.8.x %}
{% warning %}
This resource is experimental.
In Kubernetes, to take advantage of the automatic generation described below,
you need to set both [control plane configuration variables](/docs/{{ page.release }}/reference/kuma-cp/) `KUMA_EXPERIMENTAL_SKIP_PERSISTED_VIPS`
and `KUMA_EXPERIMENTAL_GENERATE_MESH_SERVICES` to `"true"` on the zone control
planes that use `MeshServices`.
{% endwarning %}
{% endif_version %}

MeshService is a new [resource](/docs/{{ page.release }}/introduction/concepts#resource) that represents what was previously expressed by
the `Dataplane` tag `kuma.io/service` within a [mesh](/docs/{{ page.release }}/introduction/concepts#mesh). Kubernetes users should think about it as
the analog of a Kubernetes `Service`.

A basic example follows to illustrate the structure:

{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshService
name: redis
mesh: default
labels:
  team: db-operators
spec:
  selector:
    dataplaneTags: # tags in Dataplane object, see below
      app: redis
      k8s.kuma.io/namespace: kuma-demo # added automatically
  ports:
  - port: 6739
    targetPort: 6739
    appProtocol: tcp
  - name: some-port
    port: 16739
    targetPort: target-port-from-container # name of the inbound
    appProtocol: tcp
status:
  addresses:
  - hostname: redis.mesh
    origin: HostnameGenerator
    hostnameGeneratorRef:
      coreName: kmy-hostname-generator
  vips:
  - ip: 10.0.1.1 # kuma VIP or Kubernetes cluster IP
```
{% endpolicy_yaml %}

The MeshService represents a destination for traffic from elsewhere in the mesh.
It defines which `Dataplane` objects serve this traffic as well as what ports
are available. It also holds information about which IPs and hostnames can be used
to reach this destination.

## Zone types

How users interact with `MeshServices` will depend on the type of zone.
{% if_version gte:2.9.x %}
In both cases, the resource is generated automatically.
{% endif_version %}

### Kubernetes

On Kubernetes, `Service` already provides a number of the features provided by
MeshService. For this reason, Kuma generates `MeshServices` from `Services` and:

- reuses VIPs in the form of cluster IPs
- uses Kubernetes DNS names

{% if_version lte:2.8.x %}
{% tip %}
You need to set the `kuma.io/mesh` label on any `Services` from which
a `MeshService` should be generated.
{% endtip %}
{% endif_version %}

In the vast majority of cases, Kubernetes users do not create `MeshServices`.

### Universal

{% if_version lte:2.8.x %}
In universal zones, `MeshServices` need to be created manually for now. A
strategy of
automatically generating `MeshService` objects from `Dataplanes` is planned for
the future.
{% endif_version %}

{% if_version gte:2.9.x %}
In universal zones, `MeshServices` are generated based on the `kuma.io/service`
value of the `Dataplane` `inbounds`. The name of the generated `MeshService`
is derived from the value of the `kuma.io/service` tag and it has one port that
corresponds to the given inbound. If the inbound doesn't have a name, one is
generated from the `port` value.

The only restriction in this case is that
the port numbers match. For example an inbound:

```
      inbound:
      - name: main
        port: 80
        tags:
          kuma.io/service: test-server
```

would result in a `MeshService`:

```
type: MeshService
name: test-server
spec:
  ports:
  - port: 80
    targetPort: 80
    name: main
  selector:
    dataplaneTags:
      kuma.io/service: test-server
```

but you can't also have on a different `Dataplane`:

```
      inbound:
      - name: main
        port: 8080
        tags:
          kuma.io/service: test-server
```

since there's no way to create a coherent `MeshService`
for `test-server` from these two inbounds.
{% endif_version %}

{% if_version gte:2.14.x %}
#### Label propagation

Non-reserved `Dataplane` inbound tags and `Dataplane` resource labels are
propagated into the generated `MeshService`'s `metadata.labels`. This lets you
select generated `MeshServices` (for example with
[`MeshMultiZoneService`](/docs/{{ page.release }}/networking/meshmultizoneservice/))
by custom labels such as `team` or `version` without patching each
`MeshService` manually.

This is opt-in. Enable it via the control plane configuration:

```yaml
experimental:
  meshServiceLabelPropagation:
    enabled: true
    # optional allow-list; when set, only these keys are propagated
    allowedLabelKeys: []
```

Rules:

- `kuma.io/*` and `k8s.kuma.io/*` keys are never propagated. System labels
  (`kuma.io/mesh`, `kuma.io/display-name`, `kuma.io/managed-by`, `kuma.io/env`,
  `kuma.io/zone`, `kuma.io/origin`) are always set by the generator and win.
- Invalid label keys or values are skipped and logged. They do not fail
  `Dataplane` validation.
- Label removal propagates: removing a tag or label from the backing
  `Dataplanes` removes it from the generated `MeshService`.

##### Conflict resolution

When the `Dataplanes` backing one `MeshService` disagree on the value of a
non-reserved key:

- **Within a single `Dataplane`** (inbounds disagree on a tag): the key is
  dropped, a warning is logged, and a metric is bumped. Inbounds of the same
  `Dataplane` disagreeing is a configuration error.
- **Across different `Dataplanes`**: per-key **majority wins**. The value
  carried by the most `Dataplanes` is used.
- **Ties** (for example exactly two `Dataplanes` with different values, one
  vote each): the **newest `Dataplane` wins**, compared by creation time. If
  creation times are identical, the value is chosen by lexicographic sort.

{% warning %}
With only two backing `Dataplanes`, every key conflict is a tie, so the
propagated value tracks whichever `Dataplane` was created most recently and can
flip when a `Dataplane` is replaced. During a rolling deploy the value switches
at the ~50% crossover point. If you use these labels as `MeshMultiZoneService`
selectors, update the selectors in lockstep, or give workloads that must be
routed separately distinct `kuma.io/service` values so they generate separate
`MeshServices`.
{% endwarning %}
{% endif_version %}

## hostnames

Because of various shortcomings, the existing `VirtualOutbound` does not work
with `MeshService` and is planned for phasing out. A [new `HostnameGenerator`
resource was introduced to manage hostnames for
`MeshServices`](/docs/{{ page.release }}/networking/hostnamegenerator/).

## Ports

The `ports` field lists the ports exposed by the `Dataplanes` that
the `MeshService` matches. `targetPort` can refer to a port directly or by the
name of the `Dataplane` port.

```
  ports:
  - name: redis-non-tls
    port: 16739
    targetPort: 6739
    appProtocol: tcp
```

{% if_version gte:2.9.x %}
## Multizone

The main difference at the data plane level between `kuma.io/service` and
`MeshService` is that traffic to a `MeshService` always goes to some particular zone.
It may be the local zone or it may be a remote zone.

With `kuma.io/service`, this behavior depends on
[`localityAwareLoadBalancing`](/docs/{{ page.release }}/policies/locality-aware).
If this _is not_ enabled, traffic is load balanced equally between zones.
If it _is_ enabled, destinations in the local zone are prioritized.

So when moving to `MeshService`, the choice needs to be made between:

* keeping this behavior, which means moving to [`MeshMultiZoneService`](/docs/{{ page.release }}/networking/meshmultizoneservice/).
* using `MeshService` instead, either from the local zone or one synced from
  a remote zone.

This is noted in the [migration outline](#migration).

## Targeting

### Policy `targetRef`

A `MeshService` resource can be used as the destination target of a policy by
putting it in a `to[].targetRef` entry. For example:

```
spec:
  to:
  - targetRef:
      kind: MeshService
      name: test-server
      namespace: test-app
      sectionName: main
```

This would target the policy to requests to the given `MeshService` and port with the name
`main`.
Only Kubernetes zones can reference using `namespace`, which always selects
resources in the local zone.

### Route `.backendRefs`

In order to direct traffic to a given `MeshService`, it must be used as a
`backendRefs` entry.
In `backendRefs`, ports are optionally referred to by their number:

```
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: test-server
        namespace: test-app
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /v2
          default:
            backendRefs:
              - kind: MeshService
                name: test-server-v2
                namespace: test-app
                port: 80
```

As opposed to `targetRef`, in `backendRefs` `port` can be omitted.

### Labels

In order to select `MeshServices` from other zones as well as multiple
`MeshServices`, you must set `labels`.
Note that with `backendRefs` only one resource is allowed to be selected.

If this field is set, resources are selected via their `labels`.

```
- kind: MeshService
  labels:
    kuma.io/display-name: test-server-v2
    k8s.kuma.io/namespace: test-app
    kuma.io/zone: east
```

In this case, the entry selects any resource with the display name
`test-server-v2` from the `east` zone in the `test-app` namespace.
Only one resource will be selected.

But if we leave out the namespace, _any_ resource named `test-server-v2` in the
`east` zone is selected, regardless of its namespace.

```
- kind: MeshService
  labels:
    kuma.io/display-name: test-server-v2
    kuma.io/zone: east
```

## Migration

MeshService is opt-in and involves a migration process. Every `Mesh` must enable
`MeshServices` in some form:

```
spec:
  meshServices:
    mode: Disabled # or Everywhere, ReachableBackends, Exclusive
```

The biggest change with `MeshService` is that traffic is no longer
load-balanced between all zones. Traffic sent to a `MeshService` is only ever
sent to a single zone.

The goal of migration is to stop using `kuma.io/service` entirely and instead
use `MeshService` resources as destinations and as `targetRef` in policies
and `backendRef` in routes.

After enabling `MeshServices`, the control plane generates additional resources.
There are a few ways to manage this.

### Options

#### `Everywhere`

This enables `MeshService` resource generation everywhere.
Both `kuma.io/service` and `MeshService` are used to generate the Envoy resources
Envoy Clusters and ClusterLoadAssignments. So having both enabled means roughly
twice as many resources which in turn means potentially
hitting the resource limits of the control plane and memory usage in the
data plane, before reachable backends
would otherwise be necessary. Therefore, consider trying `ReachableBackends` as
described below.

#### `ReachableBackends`

This enables automatic generation of the Kuma `MeshServices` resource but
does not include the corresponding resources for every data plane proxy.
The intention is for users to explicitly and gradually introduce
relevant `MeshServices` via [`reachableBackends`](/docs/{{ page.release }}/production/dp-config/transparent-proxying#reachable-backends).

#### `Exclusive`

This is the end goal of the migration. Destinations in the mesh are managed
solely with `MeshService` resources and no longer via `kuma.io/service` tags and
`Dataplane` inbounds. In the future this will become the default.

### Steps

1. Decide whether you want to set `mode: Everywhere` or whether you
   enable `MeshService` consumer by consumer with `mode: ReachableBackends`.
1. For every usage of a `kuma.io/service`, decide how it should be consumed:
- as `MeshService`: only ever from one single zone
  - these are created automatically
- as `MeshMultiZoneService`: combined with all "same" services in other zones
  - these have to be created manually
1. Update your MeshHTTPRoutes/MeshTCPRoutes to refer to
   `MeshService`/`MeshMultiZoneService` directly.
  - this is required
1. Set `mode: Exclusive` to stop receiving configuration based on
   `kuma.io/service`.
1. Update `targetRef.kind: MeshService` references to use the real name of the
   `MeshService` as opposed to the `kuma.io/service`.
  - this is not strictly required

{% endif_version %}
