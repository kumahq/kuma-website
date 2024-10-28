---
title: Configuring built-in routes
---

For configuring how traffic is forwarded from a listener to your mesh services,
use [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) and
[`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute).

Using these route resources with a gateway requires [using `spec.targetRef` to target
gateway data plane proxies](/docs/{{ page.version }}/policies/introduction).
Otherwise, [filtering and routing traffic](/docs/{{ page.version }}/policies/meshhttproute) is
configured as outlined in the docs.

Note that when using [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) and [`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute) with builtin gateways, `spec.to[].targetRef` is restricted to `kind: Mesh`.

### `MeshHTTPRoute`

{% if_version lte:2.8.x %}
{% policy_yaml mesh-http-route-example %}
```yaml
type: MeshHTTPRoute
name: edge-gateway-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags: # optional, for selecting specific listeners
      port: http-8080
  to:
    - targetRef:
        kind: Mesh
      hostnames: # optional, limit rules to specific domains
        - example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: demo-app_kuma-demo_svc_5000
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.9.x %}
{% policy_yaml mesh-http-route-example-29x use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: edge-gateway-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags: # optional, for selecting specific listeners
      port: http-8080
  to:
    - targetRef:
        kind: Mesh
      hostnames: # optional, limit rules to specific domains
        - example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: demo-app
                namespace: kuma-demo
                port: 5000
```
{% endpolicy_yaml %}
{% endif_version %}

#### Listener hostname

Remember that `MeshGateway` listeners have an optional `hostname` field that limits the
traffic accepted by the listener depending on the protocol:

- HTTP: Host header must match
- TLS: SNI must match
- HTTPS: Both SNI and Host must match

When attaching routes to specific listeners the routes are _isolated_ from each
other. If we consider the following listeners:

```yaml
conf:
  listeners:
  - port: 8080
    protocol: HTTP
    hostname: foo.example.com
    tags:
      hostname: foo
  - port: 8080
    protocol: HTTP
    hostname: *.example.com
    tags:
      hostname: wild
```

along with the following [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) rule, the only one present in the mesh:

{% if_version lte:2.8.x %}
{% policy_yaml mesh-http-route-example-2 %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags:
      hostname: wild
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example_app_svc_8080
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml mesh-http-route-example-2-29x use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags:
      hostname: wild
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example
                namespace: app
                port: 8080
```
{% endpolicy_yaml %}
{% endif_version %}

This route explicitly attaches to the second listener with `hostname: *.example.com`.

This means that requests to `foo.example.com`, which match the first listener
because it's more specific,
will return a 404 because there are no routes attached for that listener.

#### `MeshHTTPRoute` hostnames

[`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) rules can themselves specify an additional list of hostnames to further
limit the traffic handled by those rules. Consider the following example:

{% if_version lte:2.8.x %}
{% policy_yaml mesh-http-route-example-3 %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v1_app_svc_8080
    - targetRef:
        kind: Mesh
      hostnames:
        - dev.example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v2_app_svc_8080
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml mesh-http-route-example-3-29x use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: http-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v1
                namespace: app
                port: 8080
    - targetRef:
        kind: Mesh
      hostnames:
        - dev.example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: example-v2
                namespace: app
                port: 8080
```
{% endpolicy_yaml %}
{% endif_version %}

This route would send all traffic to `dev.example.com` to the `v2` backend but
other traffic to `v1`.

### `MeshTCPRoute`

If your traffic isn't HTTP, you can use [`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute) to balance traffic
between services.

{% if_version lte:2.8.x %}
{% policy_yaml mesh-tcp-route-example %}
```yaml
type: MeshTCPRoute
name: tcp-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - default:
            backendRefs:
              - kind: MeshServiceSubset
                name: example-v1_app_svc_8080
                weight: 90
              - kind: MeshServiceSubset
                name: example-v2_app_svc_8080
                weight: 10
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml mesh-tcp-route-example-29x use_meshservice=true %}
```yaml
type: MeshTCPRoute
name: tcp-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
  to:
    - targetRef:
        kind: Mesh
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: example-v1
                namespace: app
                port: 8080
                weight: 90
              - kind: MeshService
                name: example-v2
                namespace: app
                port: 8080
                weight: 10
```
{% endpolicy_yaml %}
{% endif_version %}
