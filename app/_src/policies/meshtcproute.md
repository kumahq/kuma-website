---
title: MeshTCPRoute (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [TrafficRoute](../traffic-route).
{% endwarning %}

The `MeshTCPRoute` policy allows altering and redirecting TCP requests
depending on where the request coming from and where it's going to.

## TargetRef support matrix

| TargetRef type    | top level | to | from |
|-------------------|-----------|----|------|
| Mesh              | ✅         | ❌  | ❌    |
| MeshSubset        | ✅         | ❌  | ❌    |
| MeshService       | ✅         | ✅  | ❌    |
| MeshServiceSubset | ✅         | ❌  | ❌    |
| MeshGatewayRoute  | ❌         | ❌  | ❌    |

If you don't understand this table you should read 
[matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

Unlike others outbound policies `MeshTCPRoute` doesn't contain `default`
directly in the `to` array. The `default` section is nested inside`rules`,
so the policy structure looks like this:

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

### Default conf

- **`backendRefs`** - (optional) - list of destination for request to be
  redirected to
  - **`kind`** - one of `MeshService`, `MeshServiceSubset`
  - **`name`** - service name
  - **`tags`** - service tags, must be specified if the `kind` is 
    `MeshServiceSubset`
  - **`weight`** - when a request matches the route, the choice of an upstream
    cluster is determined by its weight. Total weight is a sum of all weights
    in `backendRefs` list.


## Examples

### Traffic split

We can use `MeshTCPRoute` to split a TCP traffic between services with
different tags implementing A/B testing or canary deployments.

Here is an example of a `MeshTCPRoute` that splits the traffic from 
`frontend_kuma-demo_svc_8080` to `backend_kuma-demo_svc_3001` between versions.

{% tabs split useUrlFragment=false %}
{% tab split Kubernetes %}

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
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab split Universal %}

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
        - matches:
            - path:
                type: PathPrefix
                value: /api
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```

We will apply the configuration with `kumactl apply -f [..]` or via
the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

### Traffic redirection


We can use `MeshTCPRoute` to redirect outgoing traffic from one service to
another.

Here is an example of a `MeshTCPRoute` that redirects outgoing traffic 
originated at `frontend_kuma-demo_svc_8080` from `backend_kuma-demo_svc_3001`
to `external-backend`. 

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
We will apply the configuration with `kubectl apply -f [..]`.
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

We will apply the configuration with `kumactl apply -f [..]` or via
the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

## Route policies with different types targeting the same destination

If multiple route policies with different types (`MeshTCPRoute`, `MeshHTTPRoute`
etc.) target the same destination, only a single route type will be applied.

> Writing in progress...

## All policy options

{% policy_schema MeshTCPRoute %}
