---
title: MeshTCPRoute
description: Route and redirect TCP traffic between services with traffic splitting for A/B testing and canary deployments.
keywords:
  - TCP routing
  - traffic splitting
  - canary
content_type: reference
category: policy
---
<!-- markdownlint-disable-file MD024 -->

{% warning %}
This policy uses new policy matching algorithm.
It's recommended to migrate from [TrafficRoute](/docs/{{ page.release }}/policies/traffic-route). See "Interactions with `TrafficRoute`" section for more information.
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
{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.8.x %}

| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                 |
| --------------------- | --------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
| `to[].targetRef.kind` | `MeshService`                                 |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}

| `targetRef`             | Allowed kinds                                             |
| ----------------------- | --------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
| `to[].targetRef.kind`   | `Mesh`                                                    |
{% endtab %}

{% tab Delegated Gateway %}
{% if_version lte:2.8.x %}

| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `MeshService`                                            |
{% endif_version %}
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

For more information, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

Unlike other outbound policies, `MeshTCPRoute` doesn't contain `default`
directly in the `to` array. The `default` section is nested inside `rules`,
so the policy structure looks like the following:

[//]: # (TODO: https://github.com/kumahq/kuma-website/issues/2020)

{% if_version lte:2.8.x %}

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

{% endif_version %}

{% if_version eq:2.9.x %}

```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|MeshSubset 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```

{% endif_version %}

{% if_version gte:2.10.x %}

```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|Dataplane 
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - default: # configuration applied for the matched TCP traffic
            backendRefs: [...]
```

{% endif_version %}

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

### Gateways

In order to route TCP traffic for a MeshGateway, you need to target the
MeshGateway in `spec.targetRef` and set `spec.to[].targetRef.kind: Mesh`.

### Interactions with `MeshHTTPRoute`

[`MeshHTTPRoute`](../meshhttproute) takes priority over `MeshTCPRoute` when both are defined for the same service, and the matching `MeshTCPRoute` is ignored.

### Interactions with `TrafficRoute`

`MeshTCPRoute` takes priority over [`TrafficRoute`](../traffic-route) when a proxy is targeted by both policies.

All legacy policies like `Retry`, `TrafficLog`, `Timeout` etc. only match on routes defined by `TrafficRoute`.
All new recommended policies like `MeshRetry`, `MeshAccessLog`, `MeshTimeout` etc. match on routes defined by `MeshTCPRoute` and `TrafficRoute`.

If you don't use legacy policies, it's recommended to remove any existing `TrafficRoute`.
Otherwise, it's recommended to migrate to new policies and then removing `TrafficRoute`.

## Examples

{% if_version lte:2.8.x %}

### Traffic split

You can use `MeshTCPRoute` to split TCP traffic between services with
different tags and implement A/B testing or canary deployments.

Here's an example of a `MeshTCPRoute` that splits the traffic from
`frontend_kuma-demo_svc_8080` to `backend_kuma-demo_svc_3001` between versions:

{% policy_yaml %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
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

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: backend
                namespace: kuma-demo
                port: 3001
                _version: v0
                weight: 90
              - kind: MeshService
                name: backend
                namespace: kuma-demo
                port: 3001
                _version: v1
                weight: 10
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: backend
                namespace: kuma-demo
                port: 3001
                _version: v0
                weight: 90
              - kind: MeshService
                name: backend
                namespace: kuma-demo
                port: 3001
                _version: v1
                weight: 10
```

{% endpolicy_yaml %}
{% endif_version %}

{% endif_version %}

### Traffic redirection

You can use `MeshTCPRoute` to redirect outgoing traffic from one service to
another.

Here's an example of a `MeshTCPRoute` that redirects outgoing traffic
originating at `frontend_kuma-demo_svc_8080` from `backend_kuma-demo_svc_3001`
to `external-backend`:

{% if_version lte:2.8.x %}
{% policy_yaml %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: external-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: external-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshTCPRoute
name: tcp-route-1
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: external-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% endif_version %}

## Route policies with different types targeting the same destination

If multiple route policies with different types (`MeshTCPRoute` and `MeshHTTPRoute`
for example) target the same destination, only a single route type with the highest
specificity will be applied.

In this example, both `MeshTCPRoute` and `MeshHTTPRoute` target the same destination:

{% if_version lte:2.8.x %}
**MeshTCPRoute**:

```yaml
# [...]
targetRef:
  kind: MeshSubset
  tags:
    app: frontend
to:
  - targetRef:
      kind: MeshService
      name: backend_kuma-demo_svc_3001
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
  kind: MeshSubset
  tags:
    app: frontend
to:
  - targetRef:
      kind: MeshService
      name: backend_kuma-demo_svc_3001
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: "/"
        default:
          backendRefs:
            - kind: MeshService
              name: other-http-backend_kuma-demo_svc_8080
```

{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshHTTPRoute
name: simple-http
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: other-tcp-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshHTTPRoute
name: simple-http
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - matches:
          path:
              type: PathPrefix
              value: "/"
          default:
            backendRefs:
              - kind: MeshService
                name: other-http-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshHTTPRoute
name: simple-http
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: other-tcp-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}

```yaml
type: MeshHTTPRoute
name: simple-http
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      rules:
        - matches:
          path:
              type: PathPrefix
              value: "/"
          default:
            backendRefs:
              - kind: MeshService
                name: other-http-backend
                namespace: kuma-demo
                port: 8080
                _port: 8080
```

{% endpolicy_yaml %}
{% endif_version %}

Depending on the `backend`'s protocol:

- `MeshHTTPRoute` will be applied if `http`, `http2`, or `grpc` are specified
- `MeshTCPRoute` will be applied if `tcp` or `kafka` is specified, or when nothing is specified

## See also

- [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute) - Route HTTP/grpc traffic between services
- [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout) - Configure TCP connection timeouts
- [MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck) - Health checking for TCP connections

## All policy configuration settings

{% if_version gte:2.13.x %}
{% schema_viewer MeshTCPRoutes exclude.targetRef=tags,proxyTypes,mesh targetRef.kind=Mesh,Dataplane exclude.to.targetRef=tags,proxyTypes,mesh to.targetRef.kind=MeshService,MeshMultiZoneService,MeshExternalService %}
{% endif_version %}
{% if_version lte:2.12.x %}
{% schema_viewer MeshTCPRoutes %}
{% endif_version %}
