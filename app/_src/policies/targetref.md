---
title: Understanding TargetRef policies
---

## What is a policy?

A policy is a set of configuration that will be used to generate the proxy configuration.
{{ site.mesh_product_name }} combines policies with dataplane configuration to generate the Envoy configuration of a proxy.

## What do `targetRef` policies look like?

There are two parts to a policy:

1. The metadata
2. The spec

### Metadata

Metadata identifies the policies by its `name`, `type` and what `mesh` it's part of:

{% tabs metadata %}
{% tab metadata Universal %}

```yaml
type: ExamplePolicy
name: my-policy-name
mesh: default
spec: ... # spec data specific to the policy kind
```

{% endtab %}
{% tab metadata Kubernetes %}

In Kubernetes all our policies are implemented as [custom resource definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) in the group `kuma.io/v1alpha1`.

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

{% warning %}
Policies are namespaced scope and currently the namespace must be the one the control-plane is running in `{{site.mesh_namespace}}` by default.
{% endwarning %}

{% endtab %}
{% endtabs %}

### Spec

The `spec` field contains the actual configuration of the policy.

All specs have a **top level `targetRef`** which identifies which proxies this policy applies to.
In particular, it defines which proxies have their Envoy configuration modified.

Some policies also support further narrowing.

The `spec.to[].targetRef` field defines rules that applies to outgoing traffic of proxies selected by `spec.targetRef`.
The `spec.from[].targetRef` field defines rules that applies to incoming traffic of proxies selected by `spec.targetRef`.

The actual configuration is defined in a `default` map.

For example:

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

Some policies are not directional and will not have `to` and `from`.
For example

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

{% tip %}
One of the benefits of `targetRef` policies is that the spec is always the same between Kubernetes and Universal.

This means that converting policies between Universal and Kubernetes only means rewriting the metadata.
{% endtip %}

#### Writing a `targetRef`

`targetRef` is a concept borrowed from [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) its usage is fully defined in [MADR 005](https://github.com/kumahq/kuma/blob/master/docs/madr/decisions/005-policy-matching.md).
Its goal is to select subsets of proxies with maximum flexibility.

It looks like:

{% if_version lte:2.5.x %}
```yaml
targetRef:
  kind: Mesh | MeshSubset | MeshService | MeshServiceSubset | MeshGateway
  name: "my-name" # For kinds MeshService, MeshServiceSubset and MeshGateway a name has to be defined
  tags:
    key: value # For kinds MeshServiceSubset, MeshSubset and MeshGateway a list of matching tags can be used
```
{% endif_version %}
{% if_version gte:2.6.x %}
```yaml
targetRef:
  kind: Mesh | MeshSubset | MeshService | MeshServiceSubset | MeshGateway
  name: "my-name" # For kinds MeshService, MeshServiceSubset and MeshGateway a name has to be defined
  tags:
    key: value # For kinds MeshServiceSubset, MeshSubset and MeshGateway a list of matching tags can be used
  proxyTypes: ["Sidecar", "Gateway"] # For kinds Mesh and MeshSubset a list of matching Dataplanes types can be used
```
{% endif_version %}

Here's an explanation of each kind and their scope:

- Mesh: applies to all proxies running in the mesh
- MeshSubset: same as Mesh but filters only proxies who have matching `targetRef.tags`
{% if_version lte:2.8.x %}
- MeshService: all proxies with a tag `kuma.io/service` equal to `targetRef.name`
{% endif_version %}
{% if_version gte:2.9.x %}
- MeshService: all proxies with a tag `kuma.io/service` equal to `targetRef.name` (deprecated) or
- MeshService: all proxies matching `name` and `namespace` (only on kubernetes) or specified `labels`
{% endif_version %}
- MeshServiceSubset: same as `MeshService` but further refine to proxies that have matching `targetRef.tags`
- MeshGateway: targets proxies matched by the named MeshGateway
    - Note that it's very strongly recommended to target MeshGateway proxies using this
      kind, as opposed to MeshService/MeshServiceSubset.

{% if_version gte:2.6.x %}
In {{site.mesh_product_name}} 2.6.x, the `targetRef` field gained the ability to select a specific subset of data plane proxies. To further refine policy enforcement, a new field named `proxyTypes` has been introduced. It allows you to target policies to specific types of data plane proxies:
- `Sidecar`: Targets data plane proxies acting as sidecars to applications.
- `Gateway`: Applies to data plane proxies operating in Gateway mode.
- Empty list: Defaults to targeting all data plane proxies.
{% endif_version %}

Consider the example below:

{% if_version lte:2.8.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: example
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef: # top level targetRef
    kind: MeshService
    name: web-frontend
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
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
{% endif_version %}
{% if_version gte:2.9.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: example
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef: # top level targetRef
    kind: MeshService
    name: web-frontend
    namespace: web
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
        namespace: web
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: "/tmp/logs.txt"
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
{% endif_version %}

Using `spec.targetRef`, this policy targets all proxies that implement the service `web-frontend`.
It defines the scope of this policy as applying to traffic either from or to `web-frontend` services.

The `spec.to.targetRef` section enables logging for any traffic going to `web-backend`.
The `spec.from.targetRef` section enables logging for any traffic coming from _any service_ in the `Mesh`.

### Target resources

Not every policy supports `to` and `from` levels. Additionally, not every resource can
appear at every supported level. The specified top level resource can also affect which
resources can appear in `to` or `from`.

{% if_version gte:2.6.x %}
To help users, each policy documentation includes tables indicating which `targetRef` kinds is supported at each level.
For each type of proxy, sidecar or builtin gateway, the table indicates for each
`targetRef` level, which kinds are supported.

#### Example tables

These are just examples, remember to check the docs specific to your policy!

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`           | Allowed kinds                                    |
| --------------------- | ------------------------------------------------ |
| `targetRef.kind`      | `Mesh`, `MeshGateway`, `MeshGateway` with `tags` |
| `to[].targetRef.kind` | `Mesh`                                           |
{% endtab %}
{% endtabs %}

#### Sidecar

We see that we can select sidecar proxies via any of the kinds that select
sidecars and we can set both `to` and `from`.

We can apply policy to:
* all traffic originating at the sidecar _to_ anywhere (`to[].targetRef.kind: Mesh`)
* traffic _to_ a specific `kuma.io/service` (`to[].targetRef.kind: MeshService`)

We can also apply policy to:
* traffic terminating at the sidecar _from_ anywhere in the mesh (`from[].targetRef.kind: Mesh`)

#### Builtin gateways

We see that we can select gateway proxies via any of the kinds that select
gateways as well as specific gateway listeners and we can set only `to`.

We can only apply policy to:
* all traffic originating at the gateway _to_ anywhere (`to[].targetRef.kind: Mesh`)
{% endif_version %}
{% if_version lte:2.5.x %}
To help users, each policy documentation includes a table indicating which
`targetRef` kinds is supported at each level.

This table looks like:

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ❌   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ❌  | ✅   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |
| `MeshGateway`       | ✅        | ❌  | ❌   |

Here it indicates that the top level can use any targetRef kinds. But in
`targetRef.to` only kind `Mesh` can be used and in `targetRef.from`
only kind `MeshService`.
{% endif_version %}

### Merging configuration

It is necessary to define a policy for merging configuration,
because a proxy can be targeted by multiple `targetRef`'s.

We define a total order of policy priority:

- MeshServiceSubset > MeshService > MeshSubset > Mesh (the more a `targetRef` is focused the higher priority it has)
- If levels are equal the lexicographic order of policy names is used

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

### Examples

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

All traffic from any proxy (top level `targetRef`) going to any proxy (to `targetRef`) will have this policy applied with value `key=value`.

#### Recommending to users

{% if_version lte:2.8.x %}
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
{% endif_version %}
{% if_version gte:2.9.x %}
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
        namespace: demo
      default:
        key: value
```
{% endif_version %}

All traffic from any proxy (top level `targetRef`) going to the service "my-service" (to `targetRef`) will have this policy applied with value `key=value`.

This is useful when a service owner wants to suggest a set of configurations to its clients.

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

This is a useful way to define coarse grain rules for example.

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

{% if_version gte:2.6.x %}
#### Configuring all gateways in a Mesh

```yaml
type: ExamplePolicy
name: example
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Gateway"]
  default:
    key: value
```

All gateway proxies in mesh `default` will have this policy configured with `key=value`.

This can be very useful when timeout configurations for gateways need to differ from those of other proxies.
{% endif_version %}
