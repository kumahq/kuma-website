---
title: Policies
---
{% if_version gte:2.9.x %}
## What is a policy?

A policy is a set of configuration that will be used to generate the data plane proxy configuration.
{{ site.mesh_product_name }} combines policies with the `Dataplane` resource to generate the Envoy configuration of a
data plane proxy.

## What do policies look like?

Like all [resources](/docs/{{ page.release }}/introduction/concepts#resource) in {{ site.mesh_product_name }}, there are
two parts to a policy: the metadata and the spec.

### Metadata

Metadata identifies the policies by its `name`, `type` and what `mesh` it's part of:

{% tabs metadata %}
{% tab metadata Kubernetes %}

In Kubernetes all our policies are implemented
as [custom resource definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
in the group `kuma.io/v1alpha1`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
spec: ... # spec data specific to the policy kind
```

By default the policy is created in the `default` mesh.
You can specify the mesh by using the `kuma.io/mesh` label.

For example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: "my-mesh"
spec: ... # spec data specific to the policy kind
```

{% endtab %}
{% tab metadata Universal %}

```yaml
type: ExamplePolicy
name: my-policy-name
mesh: default
spec: ... # spec data specific to the policy kind
```

{% endtab %}
{% endtabs %}

### Spec

The `spec` field contains the actual configuration of the policy.

Some policies apply to only a subset of the configuration of the proxy.

{% if_version gte:2.10.x %}

- **Inbound policies** apply only to incoming traffic. Most inbound policies now use `spec.rules[]` to define their
  configuration.
  However, [`MeshTrafficPermission`](../meshtrafficpermission) and [`MeshFaultInjection`](../meshfaultinjection) still
  use the `spec.from[].targetRef` field,
  which defines the subset of clients that are going to be impacted by this policy.
- **Outbound policies** apply only to outgoing traffic. The `spec.to[].targetRef` field defines the outbounds that are
  going to be impacted by this policy
{% endif_version %}
{% if_version eq:2.9.x %}
- **Inbound policies** apply only to incoming traffic. The `spec.from[].targetRef` field defines the subset of clients
  that are going to be impacted by this policy.
- **Outbound policies** apply only to outgoing traffic. The `spec.to[].targetRef` field defines the outbounds that are
  going to be impacted by this policy
{% endif_version %}

The actual configuration is defined under the `default` field.

For example:

{% if_version gte:2.10.x %}
{% policy_yaml base-example %}

```yaml
type: ExampleOutboundPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Mesh # policy applies to all proxies in the mesh
  to:
    - targetRef:
        kind: MeshService # only for requests destined for 'my-service'
        name: my-service
      default: # configuration that applies to selected requests on selected proxies
        key: value
---
type: ExampleInboundPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Dataplane # policy applies to proxies with 'app: my-app' label
    labels:
      app: my-app
    sectionName: httpport # only for inbound listener named 'httpport'
  rules:
    - default: # configuration that applies to selected inbound listeners on selected proxies
        key: value
```

{% endpolicy_yaml %}
{% endif_version %}
{% if_version eq:2.9.x %}
{% policy_yaml base-example-290 %}

```yaml
type: ExamplePolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default: # Configuration that applies to outgoing traffic
        key: value
  from:
    - targetRef:
        kind: Mesh
      default: # Configuration that applies to incoming traffic
        key: value
```

{% endpolicy_yaml %}
{% endif_version %}

Some policies are not directional and will not have `to` and `rules`. Some examples of such policies are [`MeshTrace`](
/docs/{{ page.release }}/policies/meshtrace) or [`MeshProxyPatch`](/docs/{{ page.release }}/policies/meshproxypatch).
For example

{% policy_yaml non-directional %}
```yaml
type: NonDirectionalPolicy
name: my-example
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    key: value
```
{% endpolicy_yaml %}

All specs have a **top level `targetRef`** which identifies which proxies this policy applies to.
In particular, it defines which proxies have their Envoy configuration modified.

{% tip %}
One of the benefits of `targetRef` policies is that the spec is always the same between Kubernetes and Universal.

This means that converting policies between Universal and Kubernetes only means rewriting the metadata.
{% endtip %}

{% if_version gte:2.10.x %}

## Writing a `targetRef`

`targetRef` is a concept borrowed from [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).
Its goal is to reference resources in a cluster.

It looks like:

```yaml
targetRef:
  kind: Mesh | Dataplane | MeshService | MeshExternalService | MeshMultiZoneService | MeshGateway
  name: my-name # On Kubernetes resources can be selected by name/namespace
  namespace: ns
  labels: # Alternative to name/namespace, labels can be used to select a group of resources
    key: value
  sectionName: ASection # This is used when trying to attach to a specific part of a resource (for example an inbound port of a `Dataplane`)
  tags: # Only for kind MeshGateway to select a set of listeners
    key: value
  proxyTypes: [ Sidecar, Gateway ] # Only for kind Mesh to apply to all proxies of a specific type
```

Consider the two example policies below:

{% policy_yaml accesslog_outbound_example use_meshservice=true %}

```yaml
type: MeshAccessLog
name: example-outbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: Dataplane
    tags:
      app: web-frontend
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
        namespace: kuma-demo
        sectionName: httpport
        _port: 8080
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}
{% policy_yaml accesslog_inbound_example %}

```yaml
type: MeshAccessLog
name: example-inbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: Dataplane
    tags:
      app: web-frontend
  rules:
    - default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```

{% endpolicy_yaml %}

Using `spec.targetRef`, this policy targets all proxies that have a label `app:web-frontend`.
It defines the scope of this policy as applying to traffic either from or to data plane proxies with the tag
`app:web-frontend`.

The `spec.to[].targetRef` section enables logging for any traffic going to `web-backend`.
The `spec.rules[]` section enables logging for any traffic coming on inbound listeners of the `web-frontend` proxies.

### Omitting `targetRef`

When a `spec.targetRef` is not present, it is semantically equivalent to `spec.targetRef.kind: Mesh` and refers to
everything inside the `Mesh`.

### Applying to specific proxy types

The top level `targetRef` field can select a specific subset of data plane proxies. The field named `proxyTypes` can
restrict policies to specific types of data plane proxies:

- `Sidecar`: Targets data plane proxies acting as sidecars to applications (including [delegated gateways](/docs/{{
  page.release }}/using-mesh/managing-ingress-traffic/delegated/)).
- `Gateway`: Applies to data plane proxies operating in [built-in Gateway](/docs/{{ page.release
  }}/using-mesh/managing-ingress-traffic/builtin/) mode.
- Empty list: Defaults to targeting all data plane proxies.

#### Example

The following policy will only apply to gateway data-planes:
{% policy_yaml proxytypes %}

```yaml
type: MeshTimeout
name: gateway-only-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [ "Gateway" ]
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

### Targeting gateways

Given a MeshGateway:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge
  namespace: {{site.mesh_namespace}}
conf:
  listeners:
    - port: 80
      protocol: HTTP
      tags:
        port: http-80
    - port: 443
      protocol: HTTPS
      tags:
        port: https-443
```

Policies can attach to all listeners:

{% policy_yaml alllisteners %}

```yaml
type: MeshTimeout
name: timeout-all
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

so that requests to either port 80 or 443 will have an idle timeout of 10 seconds,
or just some listeners:

{% policy_yaml somelisteners %}

```yaml
type: MeshTimeout
name: timeout-8080
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
    tags:
      port: http-80
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```

{% endpolicy_yaml %}

So that only requests to port 80 will have the idle timeout.

Note that depending on the policy,
there may be restrictions on whether or not specific listeners can be selected.

#### Routes

Read the [MeshHTTPRoute docs](/docs/{{ page.release }}/policies/meshhttproute/#gateways)
and [MeshTCPRoute docs](/docs/{{ page.release }}/policies/meshtcproute/#gateways) for more
on how to target gateways for routing traffic.

### Target kind support for different policies

Not every policy supports `to` and `rules` levels. Additionally, not every resource can
appear at every supported level. The specified top level resource can also affect which
resources can appear in `to` or `rules`.

To help users, each policy documentation includes tables indicating which `targetRef` kinds is supported at each level.
For each type of proxy, sidecar or builtin gateway, the table indicates for each
`targetRef` level, which kinds are supported.

#### Example tables

These are just examples, remember to check the docs specific to your policy.

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`             | Allowed kinds |
| ----------------------- | -------------------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `Dataplane`, `MeshGateway`                                   |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService`, `MeshMultiZoneService` |

The table above show that we can select sidecar proxies via `Mesh`, `Dataplane`, `MeshGateway`

We can use the policy as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` which will apply to all traffic originating at the sidecar _to_ anywhere
* `to[].tagerRef.kind: MeshService` which will apply to all traffic _to_ specific services
* `to[].tagerRef.kind: MeshExternalService` which will apply to all traffic _to_ specific external services
* `to[].tagerRef.kind: MeshMultiZoneService` which will apply to all traffic _to_ specific multi-zone services

{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`           | Allowed kinds |
| --------------------- | ------------------------------------------------ |
| `targetRef.kind`      | `Mesh`, `MeshGateway`, `MeshGateway` with `tags` |
| `to[].targetRef.kind` | `Mesh`                                           |

The table above indicates that we can select builtin gateway via `Mesh`, `MeshGateway` or even specific listeners with
`MeshGateway` using tags.

We can use the policy only as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` all traffic from the gateway _to_ anywhere.

{% endtab %}
{% endtabs %}

{% endif_version %}

{% if_version eq:2.9.x %}

## Writing a `targetRef`

`targetRef` is a concept borrowed from [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).
Its goal is to select subsets of proxies with maximum flexibility.

It looks like:

```yaml
targetRef:
  kind: Mesh | MeshSubset | MeshService | MeshGateway
  name: "my-name" # For kinds MeshService, and MeshGateway a name has to be defined
  tags:
    key: value # For kinds MeshSubset and MeshGateway a list of matching tags can be used
  proxyTypes: [ "Sidecar", "Gateway" ] # For kinds Mesh and MeshSubset a list of matching Dataplanes types can be used
  labels:
    key: value # In the case of policies that apply to labeled resources you can use these to apply the policy to each resource
  sectionName: ASection # This is used when trying to attach to a specific part of a resource (for example a port of a `MeshService`)
  namespace: ns # valid when the policy is applied by a Kubernetes control plane 
```

Here's an explanation of each kinds and their scope:

- Mesh: applies to all proxies running in the mesh
- MeshSubset: same as Mesh but filters only proxies who have matching `targetRef.tags`
- MeshService: all proxies with a tag `kuma.io/service` equal to `targetRef.name`. This can
  work differently when
  using [explicit services](#using-policies-with-meshservice-meshmultizoneservice-and-meshexternalservice).
- MeshGateway: targets proxies matched by the named MeshGateway
- MeshServiceSubset: same as `MeshService` but further refine to proxies that have matching `targetRef.tags`. ⚠️This is
  deprecated from version 2.9.x ⚠️.

Consider the two example policies below:

{% policy_yaml accesslog_outbound_example use_meshservice=true %}
```yaml
type: MeshAccessLog
name: example-outbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: MeshSubset
    tags:
      app: web-frontend
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
        namespace: kuma-demo
        sectionName: httpport
        _port: 8080
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```
{% endpolicy_yaml %}
{% policy_yaml accesslog_inbound_example %}
```yaml
type: MeshAccessLog
name: example-inbound
mesh: default
spec:
  targetRef: # top level targetRef
    kind: MeshSubset
    tags:
      app: web-frontend
  from:
    - targetRef: # from level targetRef
        kind: Mesh
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
```
{% endpolicy_yaml %}

Using `spec.targetRef`, this policy targets all proxies that have a tag `app:web-frontend`.
It defines the scope of this policy as applying to traffic either from or to data plane proxies with the tag
`app:web-frontend`.

The `spec.to[].targetRef` section enables logging for any traffic going to `web-backend`.
The `spec.from[].targetRef` section enables logging for any traffic coming from _anywhere_ in the `Mesh`.

### Omitting `targetRef`

When a `targetRef` is not present, it is semantically equivalent to `targetRef.kind: Mesh` and refers to everything
inside the `Mesh`.

### Applying to specific proxy types

The top level `targetRef` field can select a specific subset of data plane proxies. The field named `proxyTypes` can
restrict policies to specific types of data plane proxies:

- `Sidecar`: Targets data plane proxies acting as sidecars to applications (including [delegated gateways](/docs/{{
  page.release }}/using-mesh/managing-ingress-traffic/delegated/)).
- `Gateway`: Applies to data plane proxies operating in [built-in Gateway](/docs/{{ page.release
  }}/using-mesh/managing-ingress-traffic/builtin/) mode.
- Empty list: Defaults to targeting all data plane proxies.

#### Example

The following policy will only apply to gateway data-planes:
{% policy_yaml proxytypes %}
```yaml
type: MeshTimeout
name: gateway-only-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [ "Gateway" ]
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```
{% endpolicy_yaml %}

### Targeting gateways

Given a MeshGateway:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge
  namespace: {{site.mesh_namespace}}
conf:
  listeners:
    - port: 80
      protocol: HTTP
      tags:
        port: http-80
    - port: 443
      protocol: HTTPS
      tags:
        port: https-443
```

Policies can attach to all listeners:

{% policy_yaml alllisteners %}
```yaml
type: MeshTimeout
name: timeout-all
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```
{% endpolicy_yaml %}

so that requests to either port 80 or 443 will have an idle timeout of 10 seconds,
or just some listeners:

{% policy_yaml somelisteners %}
```yaml
type: MeshTimeout
name: timeout-8080
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge
    tags:
      port: http-80
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 10s
```
{% endpolicy_yaml %}

So that only requests to port 80 will have the idle timeout.

Note that depending on the policy,
there may be restrictions on whether or not specific listeners can be selected.

#### Routes

Read the [MeshHTTPRoute docs](/docs/{{ page.release }}/policies/meshhttproute/#gateways)
and [MeshTCPRoute docs](/docs/{{ page.release }}/policies/meshtcproute/#gateways) for more
on how to target gateways for routing traffic.

### Target kind support for different policies

Not every policy supports `to` and `from` levels. Additionally, not every resource can
appear at every supported level. The specified top level resource can also affect which
resources can appear in `to` or `from`.

To help users, each policy documentation includes tables indicating which `targetRef` kinds is supported at each level.
For each type of proxy, sidecar or builtin gateway, the table indicates for each
`targetRef` level, which kinds are supported.

#### Example tables

These are just examples, remember to check the docs specific to your policy.

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`             | Allowed kinds |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
| `from[].targetRef.kind` | `Mesh`                                                   |

The table above show that we can select sidecar proxies via `Mesh`, `MeshSubset`

We can use the policy as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` which will apply to all traffic originating at the sidecar _to_ anywhere
* `to[].tagerRef.kind: MeshService` which will apply to all traffic _to_ specific services

We can also apply policy as an _inbound_ policy with:

* `from[].targetRef.kind: Mesh` which will apply to all traffic received by the sidecar _from_ anywhere in the mesh
  {% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`           | Allowed kinds |
| --------------------- | ------------------------------------------------ |
| `targetRef.kind`      | `Mesh`, `MeshGateway`, `MeshGateway` with `tags` |
| `to[].targetRef.kind` | `Mesh`                                           |

The table above indicates that we can select builtin gateway via `Mesh`, `MeshGateway` or even specific listeners with
`MeshGateway` using tags.

We can use the policy only as an _outbound_ policy with:

* `to[].targetRef.kind: Mesh` all traffic from the gateway _to_ anywhere.

{% endtab %}
{% endtabs %}
{% endif_version %}

{% if_version gte:2.10.x %}
## Merging configuration

A proxy can be targeted by multiple `targetRef`'s, to define how policies are merged together the following strategy is
used:

We define a total order of policy priority. The table below defines the sorting order for resources in the cluster. 
Sorting is applied sequentially by attribute, with ties broken using the next attribute in the list.

|   | Attribute                                       | Order                                                                                                                                                                                                                            |
|---|-------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `spec.targetRef`                                | * `Mesh` (less priority)<br>* `MeshGateway`<br>* `Dataplane`<br>* `Dataplane` with `name/namespace/sectionName`<br>* `Dataplane` with `name/namespace`<br>* `Dataplane` with `labels/sectionName`<br>* `Dataplane` with `labels` |
| 2 | Origin<br>Label `kuma.io/origin`                | * `global` (less priority)<br>* `zone`                                                                                                                                                                                           |
| 3 | Policy Role<br>Label `kuma.io/policy-role`      | * `system` (less priority)<br>* `producer`<br>* `consumer`<br>* `workload-owner`                                                                                                                                                 |
| 4 | Display Name<br>Label `kuma.io/display-name`    | Inverted lexicographical order, i.e;<br>* `zzzzz` (less priority)<br>* `aaaaa1`<br>* `aaaaa`<br>* `aaa`                                                                                                                          |


For `to` and `rules` policies we concatenate the array for each matching policies.
For `to` policies we sort concatenated arrays again based on the `spec.to[].targetRef` field:

|   | Attribute             | Order                                                                                                                                   |
|---|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `spec.to[].targetRef` | * `Mesh` (less priority)<br>* `MeshService`<br>* `MeshService` with `sectionName`<br>* `MeshExternalService`<br>* `MeshMultiZoneService` |

We then build configuration by merging each level using [JSON patch merge](https://www.rfc-editor.org/rfc/rfc7386).

For example if I have 2 `default` ordered this way:

```yaml
default:
  conf: 1
  sub:
    array: [ 1, 2, 3 ]
    other: 50
    other-array: [ 3, 4, 5 ]
---
default:
  sub:
    array: [ ]
    other: null
    other-array: [ 5, 6 ]
    extra: 2
```

The merge result is:

```yaml
default:
  conf: 1
  sub:
    array: [ ]
    other-array: [ 5, 6 ]
    extra: 2
```
{% endif_version %}
{% if_version eq:2.9.x %}
## Merging configuration

A proxy can be targeted by multiple `targetRef`'s, to define how policies are merged together the following strategy is used:

We define a total order of policy priority:

- `MeshServiceSubset` > `MeshService` > `MeshSubset` > `Mesh` (the more a `targetRef` is focused the higher priority it has)
- If levels are equal the lexicographic order of policy names is used

{% tip %}
Remember: the broader a `targetRef`, the lower its priority.
{% endtip %}

For `to` and `from` policies we concatenate the array for each matching policies.
We then build configuration by merging each level using [JSON patch merge](https://www.rfc-editor.org/rfc/rfc7386).

For example if I have 2 `default` ordered this way:

```yaml
default:
  conf: 1
  sub:
    array: [1, 2, 3]
    other: 50
    other-array: [3, 4, 5]
---
default:
  sub:
    array: []
    other: null
    other-array: [5, 6]
    extra: 2
```

The merge result is:

```yaml
default:
  conf: 1
  sub:
    array: []
    other-array: [5, 6]
    extra: 2
```
{% endif_version %}

## Using policies with `MeshService`, `MeshMultizoneService` and `MeshExternalService`.

[`MeshService`](/docs/{{ page.release }}/networking/meshservice) is a feature to define services explicitly in {{
site.mesh_product_name }}.
It can be selectively enabled and disable depending on the value of [meshServices.mode](/docs/{{ page.release
}}/networking/meshservice/#migration) on your Mesh object.

When using explicit services, `MeshServiceSubset` is no longer a valid kind and `MeshService` can only be used to select
an actual `MeshService` resource (it can no longer select a `kuma.io/service`).

In the following example we'll assume we have a `MeshService`:

{% policy_yaml ms-1 namespace=kuma-demo %}
```yaml
type: MeshService
name: my-service
labels:
  k8s.kuma.io/namespace: kuma-demo
  kuma.io/zone: my-zone
  app: redis
spec:
  selector:
    dataplaneTags:
      app: redis
      k8s.kuma.io/namespace: kuma-demo
  ports:
    - port: 6739
      targetPort: 6739
      appProtocol: tcp
```
{% endpolicy_yaml %}

There are 2 ways to select a `MeshService`:

If you are in the same namespace (or same zone in Universal) you can select one specific service by using its explicit
name:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        name: redis
      default:
        connectionTimeout: 10s
```

Selecting all matching `MeshServices` by labels:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: all-in-my-namespace
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/namespace: kuma-demo
      default:
        connectionTimeout: 10s
```

In this case this is equivalent to writing a specific policy for each service that matches this label (in our example
for each service in this namespace in each zones).

{% tip %}
When `MeshService` have multiple ports, you can use `sectionName` to restrict policy to a single port.
{% endtip %}

{% if_version gte:2.10.x %}
### Global, zonal, producer and consumer policies

Policies can be applied to a zone or to a namespace when using Kubernetes.
Policies will always impact at most the scope at which they are defined.
In other words:

1. a policy applied to the global control plane will apply to all proxies in all zones.
2. a policy applied to a zone will only apply to proxies inside this zone. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: Dataplane
       labels:
         kuma.io/zone: "my-zone"
   ```
3. a policy applied to a namespace will only apply to proxies inside this namespace. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: Dataplane
       labels:
         kuma.io/zone: "my-zone"
         kuma.io/namespace: "my-ns"
   ```

There is however, one exception to this when using `MeshService` with **outbound** policies (policies with
`spec.to[].targetRef`).
In this case, if you define a policy in the same namespace as the `MeshService` it is defined in, that policy will be
considered a **producer** policy.
This means that all clients of this service (even in different zones) will be impacted by this policy.

An example of a producer policy is:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        name: redis
      default:
        connectionTimeout: 10s
```

The other type of policy is a consumer policy which most commonly use labels to match a service.

An example of a consumer policy which would override the previous producer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis-consumer
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: redis
      default:
        connectionTimeout: 10s
```

{% tip %}
Remember that `labels` on a `MeshService` applies to _each_ matching `MeshService`. To communicate to services
named the same way in different namespaces or zones with different configuration use a more specific set of labels.
{% endtip %}

{{ site.mesh_product_name }} adds a label `kuma.io/policy-role` to identify the type of the policy. The values of the
label are:

- **system**: Policies defined on global or in the zone's system namespace
- **workload-owner**: Policies defined in a non system namespaces that do not have `spec.to` entries, or have only
  `spec.rules`
- **consumer**: Policies defined in a non system namespace that have `spec.to` which either do not use `name` or have a
  different `namespace`
- **producer**: Policies defined in the same namespace as the services identified in the `spec.to[].targetRef`
{% endif_version %}
{% if_version eq:2.9.x %}
### Global, zonal, producer and consumer policies

Policies can be applied to a zone or to a namespace when using Kubernetes.
Policies will always impact at most the scope at which they are defined.
In other words:

1. a policy applied to the global control plane will apply to all proxies in all zones.
2. a policy applied to a zone will only apply to proxies inside this zone. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: MeshSubset
       tags:
         kuma.io/zone: "my-zone"
   ```
3. a policy applied to a namespace will only apply to proxies inside this namespace. It is equivalent to having:
   ```yaml
   spec:
     targetRef: 
       kind: MeshSubset
       tags:
         kuma.io/zone: "my-zone"
         kuma.io/namespace: "my-ns"
   ```

There is however, one exception to this when using `MeshService` with **outbound** policies (policies with `spec.to[].targetRef`).
In this case, if you define a policy in the same namespace as the `MeshService` it is defined in, that policy will be considered a **producer** policy.
This means that all clients of this service (even in different zones) will be impacted by this policy.

An example of a producer policy is:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis
  namespace: kuma-demo
spec:
  to:
  - targetRef:
      kind: MeshService
      name: redis
    default:
      connectionTimeout: 10s
```

The other type of policy is a consumer policy which most commonly use labels to match a service.

An example of a consumer policy which would override the previous producer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-to-redis-consumer
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: redis
      default:
        connectionTimeout: 10s
```

{% tip %}
Remember that `labels` on a `MeshService` applies to _each_ matching `MeshService`. To communicate to services
named the same way in different namespaces or zones with different configuration use a more specific set of labels.
{% endtip %}

{{ site.mesh_product_name }} adds a label `kuma.io/policy-role` to identify the type of the policy. The values of the label are:

- **system**: Policies defined on global or in the zone's system namespace
- **workload-owner**: Policies defined in a non system namespaces that do not have `spec.to` entries, or have only `spec.from`
- **consumer**: Policies defined in a non system namespace that have `spec.to` which either do not use `name` or have a different `namespace`
- **producer**: Policies defined in the same namespace as the services identified in the `spec.to[].targetRef`

The merging order of the different policy scopes is: **workload-owner > consumer > producer > zonal > global**.
{% endif_version %}

### Example

We have 2 clients client1 and client2 they run in different namespaces respectively ns1 and ns2.

{% mermaid %}
flowchart LR
subgraph ns1
    client1(client)
end
subgraph ns2
  client2(client)
  server(MeshService: server)
end
client1 --> server
client2 --> server
{% endmermaid %}

We're going to define a producer policy first:
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: producer-policy
  namespace: ns2
spec:
  to:
    - targetRef:
        kind: MeshService
        name: server
      default:
        idleTimeout: 20s
```

We know it's a producer policy because it is defined in the same namespace as the `MeshService: server` and names this
server in its `spec.to[].targetRef`.
So both client1 and client2 will receive the timeout of 20 seconds.

We now create a consumer policy:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: consumer-policy
  namespace: ns1
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: server
      default:
        idleTimeout: 30s
```

Here the policy only impacts client1 as client2 doesn't run in ns1. As consumer policies have a higher priority over
producer policies, client1 will have a `idleTimeout: 30s`.

We can define another policy to impact client2:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: consumer-policy
  namespace: ns2
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          k8s.kuma.io/service-name: server
      default:
        idleTimeout: 40s
```

Note that the only different here is the namespace, we now define a consumer policy inside `ns2`.

{% tip %}
Use labels for consumer policies and name for producer policies.
It will be easier to differentiate between producer and consumer policies.
{% endtip %}

## Examples

#### Applying a global default

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        key: value
```

All traffic from any proxy (top level `targetRef`) going to any proxy (to `targetRef`) will have this policy applied
with value `key=value`.

#### Recommending to users

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: my-service
      default:
        key: value
```

All traffic from any proxy (top level `targetRef`) going to the service "my-service" (to `targetRef`) will have this
policy applied with value `key=value`.

This is useful when a service owner wants to suggest a set of configurations to its clients.

{% if_version gte:2.10.x %}
#### Configuring all proxies of a team

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      team: "my-team"
  rules:
    - default:
        key: value
```

All traffic that's going to any proxy with the tag `team=my-team` (top level `targetRef`) will have this policy applied with value `key=value`.

This is a useful way to define coarse-grained rules for example.
{% endif_version %}

{% if_version eq:2.9.x %}
#### Configuring all proxies of a team

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      team: "my-team"
  from:
    - targetRef:
        kind: Mesh
      default:
        key: value
```

All traffic from any proxies (from `targetRef`) going to any proxy that has the tag `team=my-team` (top level `targetRef`) will have this policy applied with value `key=value`.

This is a useful way to define coarse-grained rules for example.
{% endif_version %}

{% if_version gte:2.10.x %}
#### Configuring all proxies in a zone

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      kuma.io/zone: "east"
  default:
    key: value
```

All proxies in zone `east` (top level `targetRef`) will have this policy configured with `key=value`.

This can be very useful when observability stores are different for each zone for example.
{% endif_version %}
{% if_version eq:2.9.x %}
#### Configuring all proxies in a zone

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: "east"
  default:
    key: value
```

All proxies in zone `east` (top level `targetRef`) will have this policy configured with `key=value`.

This can be very useful when observability stores are different for each zone for example.
{% endif_version %}

#### Configuring all gateways in a Mesh

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [ "Gateway" ]
  default:
    key: value
```

All gateway proxies in mesh `default` will have this policy configured with `key=value`.

This can be very useful when timeout configurations for gateways need to differ from those of other proxies.
{% endif_version %}
{% if_version lte:2.8.x %}
Here you can find the list of Policies that {{site.mesh_product_name}} supports.

Going forward from version 2.0, {{site.mesh_product_name}} is transitioning from [source/destination policies](/docs/{{
page.release }}/policies/general-notes-about-kuma-policies) to [`targetRef` policies](/docs/{{ page.release
}}/policies/targetref).

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                                                   | `targetRef` policy                                                                                                                                                                   |
|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [CircuitBreaker](/docs/{{ page.release }}/policies/circuit-breaker)         | [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker)                                                                                                           |
| [FaultInjection](/docs/{{ page.release }}/policies/fault-injection)         | [MeshFaultInjection](/docs/{{ page.release }}/policies/meshfaultinjection)                                                                                                           |
| [HealthCheck](/docs/{{ page.release }}/policies/health-check)               | [MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck)                                                                                                                 |
| [RateLimit](/docs/{{ page.release }}/policies/rate-limit)                   | [MeshRateLimit](/docs/{{ page.release }}/policies/meshratelimit)                                                                                                                     |
| [Retry](/docs/{{ page.release }}/policies/retry)                            | [MeshRetry](/docs/{{ page.release }}/policies/meshretry)                                                                                                                             |
| [Timeout](/docs/{{ page.release }}/policies/timeout)                        | [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout)                                                                                                                         |
| [TrafficLog](/docs/{{ page.release }}/policies/traffic-log)                 | [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog)                                                                                                                     |
| [TrafficMetrics](/docs/{{ page.release }}/policies/traffic-metrics)         | {% if_version lte:2.5.x inline:true %} N/A {% endif_version %} {% if_version inline:true gte:2.6.x %} [MeshMetric](/docs/{{ page.release }}/policies/meshmetric) {% endif_version %} |
| [TrafficPermissions](/docs/{{ page.release }}/policies/traffic-permissions) | [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission)                                                                                                     |
| [TrafficRoute](/docs/{{ page.release }}/policies/traffic-route)             | [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute)                                                                                                                     |
| [TrafficTrace](/docs/{{ page.release }}/policies/traffic-trace)             | [MeshTrace](/docs/{{ page.release }}/policies/meshtrace)                                                                                                                             |
| [ProxyTemplate](/docs/{{ page.release }}/policies/proxy-template)           | [MeshProxyPatch](/docs/{{ page.release }}/policies/meshproxypatch)                                                                                                                   |

{% warning %}
{% if_version lte:2.5.x %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies
together.
{% endif_version %}
{% if_version gte:2.6.x %}
If you are new to Kuma you should only need to use `targetRef` policies.
If you already use source/destination policies you can keep using them. Future versions of Kuma will provide a migration
path.
You can mix targetRef and source/destination policies as long as they are of different types. For example: You can use
`MeshTrafficPermission` with `FaultInjection` but you can't use `MeshTrafficPermission` with `TrafficPermission`.
{% endif_version %}
{% endwarning %}
{% endif_version %}

{% if_version gte:2.7.x %}

## Applying policies in shadow mode

### Overview

The new shadow mode functionality allows users to mark policies with a specific label to simulate configuration changes
without affecting the live environment.
It enables the observation of potential impact on Envoy proxy configurations, providing a risk-free method to test,
validate, and fine-tune settings before actual deployment.
Ideal for learning, debugging, and migrating, shadow mode ensures configurations are error-free,
improving the overall system reliability without disrupting ongoing operations.

### Recommended setup

It's not necessary but CLI tools like [jq](https://jqlang.github.io/jq/) and [jd](https://github.com/josephburnett/jd)
can greatly improve working with {{ site.mesh_product_name }} resources.

### How to use shadow mode

1. Before applying the policy, add a `kuma.io/effect: shadow` label.

2. Check the proxy config with shadow policies taken into account through the {{site.mesh_product_name}} API. By using
   HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true
    ```
   or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow
    ```

3. Check the diff in [JSONPatch](https://jsonpatch.com/) format through the {{site.mesh_product_name}} API. By using
   HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true&include=diff
    ```
   or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow --include=diff
    ```

### Limitations and Considerations

Currently, the {{site.mesh_product_name}} API mentioned above works only on Zone CP.
Attempts to use it on Global CP lead to `405 Method Not Allowed`.
This might change in the future.

### Examples

Apply policy with `kuma.io/effect: shadow` label:

{% policy_yaml example2 use_meshservice=true %}
```yaml
type: MeshTimeout
name: frontend-timeouts
mesh: default
labels:
  kuma.io/effect: shadow
spec:
   targetRef:
     kind: MeshSubset
     tags:
       kuma.io/service: frontend
   to:
   - targetRef:
       kind: MeshService
       name: backend
       namespace: kuma-demo
       sectionName: httpport
       _port: 3001
     default:
       idleTimeout: 23s
```
{% endpolicy_yaml %}

Check the diff using `kumactl`:

```shell
$ kumactl inspect dataplane frontend-dpp --type=config --include=diff --shadow | jq '.diff' | jd -t patch2jd
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
- "3600s"
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
+ "23s"
```

The output not only identifies the exact location in Envoy where the change will occur, but also shows the current
timeout value that we're planning to replace.

{% endif_version %}
