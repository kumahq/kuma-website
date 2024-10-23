---
title: MeshTCPRoute
---

{% warning %}
This policy uses a new policy matching algorithm.
Do **not** combine with [TrafficRoute](/docs/{{ page.version }}/policies/traffic-route) except for the default `route-all` route, which should be kept.
{% endwarning %}

The `MeshTCPRoute` policy allows you to alter and redirect TCP requests
depending on where the request is coming from and where it's going to.

{% if_version lte:2.5.x %}
{% warning %}
`MeshTCPRoute` doesn't support cross zone traffic before version 2.6.0.
{% endwarning %}
{% endif_version %}

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                             |
| ----------------------- | --------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
| `to[].targetRef.kind`   | `Mesh`                                                    |
{% endtab %}

{% tab targetRef Delegated Gateway %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endtab %}
{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ❌   | ❌    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |

{% endif_version %}

For more information, see the [matching docs](/docs/{{ page.version }}/policies/introduction).

## Configuration

Unlike other outbound policies, `MeshTCPRoute` doesn't contain `default`
directly in the `to` array. The `default` section is nested inside `rules`,
so the policy structure looks like the following:

```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|MeshSubset|MeshService|MeshServiceSubset 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```

### Default configuration

The following describes the default configuration settings of the `MeshTCPRoute` policy:

- **`backendRefs`**: (Optional) List of destinations for the request to be redirected to
  - **`kind`**: One of `MeshService`, `MeshServiceSubset`{% if_version gte:2.9.x %}, `MeshExtenalService`{% endif_version %}
  - **`name`**: The service name
  - **`tags`**: Service tags. These must be specified if the `kind` is 
    `MeshServiceSubset`.
  - **`weight`**: When a request matches the route, the choice of an upstream
    cluster is determined by its weight. Total weight is a sum of all weights
    in the `backendRefs` list.

## Interactions with `MeshHTTPRoute`

[`MeshHTTPRoute`](../meshhttproute) takes priority over `MeshTCPRoute` when both are defined for the same service, and the matching `MeshTCPRoute` is ignored.

## Examples

{% if_version lte:2.8.x %}
### Traffic split

You can use `MeshTCPRoute` to split TCP traffic between services with
different tags and implement A/B testing or canary deployments.

Here's an example of a `MeshTCPRoute` that splits the traffic from 
`frontend_kuma-demo_svc_8080` to `backend_kuma-demo_svc_3001` between versions:

{% policy_yaml traffic-split %}
```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: backend_kuma-demo_svc_3001
      rules:
        - default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "v0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "v1"
                weight: 10
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.9.x %}
### Traffic split
We can use `MeshTCPRoute` to split an TCP traffic between different MeshServices
implementing A/B testing or canary deployments.
If we want to split traffic between `v1` and `v2` versions of the same service,
first we have to create MeshServices `backend-v1` and `backend-v2` that select
backend application instances according to the version.

{% policy_yaml traffic-split-29x %}
```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: backend_kuma-demo_svc_3001
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: backend-v0
                port: 3001
                weight: 90
              - kind: MeshService
                name: backend-v1
                port: 3001
                weight: 10
```
{% endpolicy_yaml %}
{% endif_version %}

### Traffic redirection

You can use `MeshTCPRoute` to redirect outgoing traffic from one service to
another.

Here's an example of a `MeshTCPRoute` that redirects outgoing traffic 
originating at `frontend_kuma-demo_svc_8080` from `backend_kuma-demo_svc_3001`
to `external-backend`:

{% tabs modifications useUrlFragment=false %}
{% tab modifications Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTCPRoute
metadata:
  name: tcp-route-1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: external-backend
```
You can apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab modifications Universal %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: external-backend
```

You can apply the configuration with `kumactl apply -f [..]` or use
the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

## Route policies with different types targeting the same destination

If multiple route policies with different types (`MeshTCPRoute` and `MeshHTTPRoute`
for example) target the same destination, only a single route type with the highest
specificity will be applied.

In this example, both `MeshTCPRoute` and `MeshHTTPRoute` target the same destination:

**MeshTCPRoute**:
```yaml
# [...]
targetRef:
  kind: MeshService
  name: frontend
to:
  - targetRef:
      kind: MeshService
      name: backend
    rules:
      - default:
          backendRefs:
            - kind: MeshService
              name: other-tcp-backend
```

**MeshHTTPRoute**:
```yaml
# [...]
targetRef:
  kind: MeshService
  name: frontend
to:
  - targetRef:
      kind: MeshService
      name: backend
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: "/"
        default:
          backendRefs:
            - kind: MeshService
              name: other-http-backend
```

Depending on the `backend`'s protocol:
- `MeshHTTPRoute` will be applied if `http`, `http2`, or `grpc` are specified
- `MeshTCPRoute` will be applied if `tcp` or `kafka` is specified, or when nothing is specified 
 
## All policy configuration settings

{% json_schema MeshTCPRoutes %}
