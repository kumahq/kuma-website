---
title: Configuring built-in routes
---

For configuring how traffic is forwarded from a listener to your mesh services,
use [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) and
[`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute).

Using these route resources with a gateway requires [using `spec.targetRef` to target
gateway data plane proxies](../../../policies/targetref/#target-resources).
Otherwise, [filtering and routing traffic](/../../../policies/meshhttproute) is
configured as outlined in the docs.

Note that when using `MeshHTTPRoute` and `MeshTCPRoute` with builtin gateways,
`spec.to[].targetRef` is restricted to `kind: Mesh`.

### `MeshHTTPRoute`

{% tabs routes useUrlFragment=false %}
{% tab routes Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: edge-gateway-route
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags: # optional, for selecting specific listeners
      port: http/8080
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
                name: demo-app_kuma-demo_svc_5000-demo_svc_3001
```

{% endtab %}
{% tab routes Universal %}

```yaml
type: MeshGatewayRoute
mesh: default
name: edge-gateway-route
selectors:
  - match:
      kuma.io/service: edge-gateway
      port: http/8080
conf:
  http:
    rules:
      - matches:
          - path:
              match: PREFIX
              value: /
        backends:
          - destination:
              kuma.io/service: demo-app_kuma-demo_svc_5000
```

{% endtab %}
{% endtabs %}

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

along with the following `MeshHTTPRoute` rule, the only one present in the mesh:

```yaml
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

This route explicitly attaches to the second listener with `hostname: *.example.com`.

This means that requests to `foo.example.com`, which match the first listener
because it's more specific,
will return a 404 because there are no routes attached for that listener.

#### `MeshHTTPRoute` hostnames

`MeshHTTPRoute` rules can themselves specify an additional list of hostnames to further
limit the traffic handled by those rules. Consider the following example:

```yaml
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
              - kind: MeshServiceSubset
                name: example_app_svc_8080
                tags:
                  version: v1
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
              - kind: MeshServiceSubset
                name: example_app_svc_8080
                tags:
                  version: v2
```

This route would send all traffic to `dev.example.com` to the `v2` backend but
other traffic to `v1`.

### `MeshTCPRoute`

If your traffic isn't HTTP, you can use `MeshTCPRoute` to balance traffic
between services.

```yaml
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
                name: example_app_svc_8080
                tags:
                  version: v1
                weight: 90
              - kind: MeshServiceSubset
                name: example_app_svc_8080
                tags:
                  version: v2
                weight: 10
```
