---
title: MeshTrafficPermission
---

{% warning %}
This policy uses new policy matching algorithm.
Do **not** combine with [TrafficPermission](/docs/{{ page.version }}/policies/traffic-permissions).
{% endwarning %}

## TargetRef support matrix

{% if_version gte:2.7.x %}
{% tabs targetRef27x useUrlFragment=false %}
{% tab targetRef27x Sidecar %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshServiceSubset` |
{% endtab %}
{% tab targetRef27x Builtin Gateway %}
`MeshTrafficPermission` isn't supported on builtin gateways. If applied via
`spec.targetRef.kind: MeshService`, it has no effect.
{% endtab %}

{% tab targetRef27x Delegated Gateway %}
`MeshTrafficPermission` isn't supported on delegated gateways.
{% endtab %}
{% endtabs %}
{% endif_version %}

{% if_version lte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endtab %}
{% tab targetRef Builtin Gateway %}
`MeshTrafficPermission` isn't supported on builtin gateways. If applied via
`spec.targetRef.kind: MeshService`, it has no effect.
{% endtab %}

{% tab targetRef Delegated Gateway %}
`MeshTrafficPermission` isn't supported on delegated gateways.
{% endtab %}
{% endtabs %}
{% endif_version %}

If you don't understand this table you should read [matching docs](/docs/{{ page.version }}/policies/introduction).

## Configuration

### Action

{{ site.mesh_product_name }} allows configuring one of 3 actions for a group of service's clients:

* `Allow` - allows incoming requests matching the from `targetRef`.
* `Deny` - denies incoming requests matching the from `targetRef`
* `AllowWithShadowDeny` - same as `Allow` but will log as if request is denied, this is useful for rolling new restrictive policies without breaking things.

## Examples

### Service 'payments' allows requests from 'orders'

{% tabs allow-orders useUrlFragment=false %}
{% tab allow-orders Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: allow-orders
spec:
  targetRef: # 1
    kind: MeshService
    name: payments
  from:
    - targetRef: # 2
        kind: MeshSubset
        tags:
           kuma.io/service: orders
      default: # 3
        action: Allow
```


{% endtab %}
{% tab allow-orders Universal %}

```yaml
type: MeshTrafficPermission
name: allow-orders
mesh: default
spec:
  targetRef: # 1
    kind: MeshService
    name: payments
  from:
    - targetRef: # 2
        kind: MeshSubset
        tags: 
          kuma.io/service: orders
      default: # 3
        action: Allow
```

{% endtab %}
{% endtabs %}

#### Explanation

1. Top level `targetRef` selects data plane proxies that implement `payments` service.
    MeshTrafficPermission `allow-orders` will be configured on these proxies.

    ```yaml
    targetRef: # 1
      kind: MeshService
      name: payments
    ```

2. `TargetRef` inside the `from` array selects proxies that implement `order` service.
    These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 2
        kind: MeshSubset
        tags: 
          kuma.io/service: orders
    ```

3. The action is `Allow`. All requests from service `orders` will be allowed on service `payments`.

    ```yaml
    default: # 3
      action: Allow
    ```

### Deny all

{% tabs deny-all useUrlFragment=false %}
{% tab deny-all Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: deny-all
spec:
  targetRef: # 1
    kind: Mesh
  from:
    - targetRef: # 2
        kind: Mesh
      default: # 3
        action: Deny
```


{% endtab %}
{% tab deny-all Universal %}

```yaml
type: MeshTrafficPermission
name: deny-all
mesh: default
spec:
  targetRef: # 1
    kind: Mesh
  from:
    - targetRef: # 2
        kind: Mesh
      default: # 3
        action: Deny
```

{% endtab %}
{% endtabs %}

#### Explanation

1. Top level `targetRef` selects all proxies in the mesh.

    ```yaml
    targetRef: # 1
      kind: Mesh
    ```

2. `TargetRef` inside the `from` array selects all clients.

    ```yaml
    - targetRef: # 2
        kind: Mesh
    ```

3. The action is `Deny`. All requests from all services will be denied on all proxies in the `default` mesh.

    ```yaml
    default: # 3
      action: Deny
    ```

### Allow all

{% policy_yaml allow-all %}
```yaml
type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  targetRef: # 1
    kind: Mesh
  from:
    - targetRef: # 2
        kind: Mesh
      default: # 3
        action: Allow
```
{% endpolicy_yaml %}

#### Explanation

1. Top level `targetRef` selects all proxies in the mesh.

    ```yaml
    targetRef: # 1
      kind: Mesh
    ```

2. `targetRef` inside the element of the `from` array selects all clients within the mesh.

    ```yaml
    - targetRef: # 2
        kind: Mesh
    ```

3. The action is `Allow`. All requests from all services will be allow on all proxies in the `default` mesh.

    ```yaml
    default: # 3
      action: Allow
    ```

### Allow requests from zone 'us-east', deny requests from 'dev' environment

{% tabs tags useUrlFragment=false %}
{% tab tags Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: example-with-tags
spec:
  targetRef: # 1
    kind: Mesh
  from:
    - targetRef: # 2
        kind: MeshSubset
        tags:
          kuma.io/zone: us-east
      default: # 3
        action: Allow
    - targetRef: # 4
        kind: MeshSubset
        tags:
          env: dev
      default: # 5
        action: Deny
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab tags Universal %}

```yaml
type: MeshTrafficPermission
name: example-with-tags
mesh: default
spec:
  targetRef: # 1
    kind: Mesh
  from:
    - targetRef: # 2
        kind: MeshSubset
        tags:
          kuma.io/zone: us-east
      default: # 3
        action: Allow
    - targetRef: # 4
        kind: MeshSubset
        tags:
          env: dev
      default: # 5
        action: Deny
```
Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

#### Explanation

1. Top level `targetRef` selects all proxies in the mesh.

    ```yaml
    targetRef: # 1
      kind: Mesh
    ```

2. `TargetRef` inside the `from` array selects proxies that have label `kuma.io/zone: us-east`.
    These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 2
        kind: MeshSubset
        tags:
          kuma.io/zone: us-east
    ```

3. The action is `Allow`. All requests from the zone `us-east` will be allowed on all proxies.

    ```yaml
    default: # 3
      action: Allow
    ```

4. `TargetRef` inside the `from` array selects proxies that have tags `kuma.io/zone: us-east`.
   These proxies will be subjected to the action from `default.action`.

    ```yaml
    - targetRef: # 4
        kind: MeshSubset
        tags:
          env: dev
    ```

5. The action is `Deny`. All requests from the env `dev` will be denied on all proxies.

    ```yaml
    default: # 5
      action: Deny
    ```

{% tip %}
Order of rules inside the `from` array matters. 
Request from the proxy that has both `kuma.io/zone: east` and `env: dev` will be denied. 
This is because the rule with `Deny` is later in the `from` array than any `Allow` rules.
{% endtip %}

## All policy options

{% json_schema MeshTrafficPermissions %}
