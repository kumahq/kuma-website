---
title: MeshService
---

{% if_version lte:2.8.x %}
{% warning %}
This resource is experimental!
In Kubernetes, to take advantage of the automatic generation described below,
you need to set both [control plane configuration variables](/docs/{{ page.version }}/reference/kuma-cp/) `KUMA_EXPERIMENTAL_SKIP_PERSISTED_VIPS`
and `KUMA_EXPERIMENTAL_GENERATE_MESH_SERVICES` to `"true"` on the zone control
planes that use `MeshServices`.
{% endwarning %}
{% endif_version %}

MeshService is a new resource that represents what was previously expressed by
the `Dataplane` tag `kuma.io/service`. Kubernetes users should think about it as
the analog of a Kubernetes `Service`.

A basic example follows to illustrate the structure:

{% policy_yaml meshservice_example %}
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
      k8s.kuma.io/namespace: redis-system # added automatically
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

## Hostnames

Because of various shortcomings, the existing `VirtualOutbound` does not work
with `MeshService` and is planned for phasing out. A [new `HostnameGenerator`
resource was introduced to manage hostnames for
`MeshServices`](/docs/{{ page.version }}/networking/hostnamegenerator/).

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
dataplane, before reachable backends
would otherwise be necessary. Therefore, consider trying `ReachableBackends` as
described below.

#### `ReachableBackends`

This enables automatic generation of the Kuma `MeshServices` resource but
does not include the corresponding resources for every data plane proxy.
The intention is for users to explicitly and gradually introduce
relevant `MeshServices` via `reachableBackends`.

#### `Exclusive`

This is the end goal of the migration. Destinations in the mesh are managed
solely with `MeshService` resources and no longer via `kuma.io/service` tags and
`Dataplane` inbounds.

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

## Multizone

Each MeshService created in a zone is synced to a global control plane which then syncs them to other zones.
The end result is that each zone should contain the same set of MeshServices.
When using MeshService, the client always connects to a MeshService in a specific zone.
Learn about [MeshMultiZoneService](/docs/{{ page.version }}/networking/meshmultizoneservice) to implement failover or load balancing between MeshServices in multiple zones. 
