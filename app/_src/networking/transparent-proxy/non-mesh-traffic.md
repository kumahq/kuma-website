---
title: Non-mesh traffic
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}

{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}

## Incoming

With mTLS enabled, external clients cannot access applications inside the mesh. To allow external clients to consume mesh services, consider using [Permissive mTLS]({{ docs }}/policies/mutual-tls/#permissive-mtls).

## Outgoing

By default, {{ Kuma }} permits all outgoing non-mesh traffic to pass through the [data plane proxy]({{ docs }}/introduction/concepts/#data-plane-proxy--sidecar) without restrictions. For example, if a service sends a request to `{{ site.links.web }}`, those requests won’t be blocked, even if a [MeshTrafficPermission]({{ docs }}/policies/meshtrafficpermission/) policy restricts mesh traffic.

This passthrough mode is enabled by default on all data plane proxies running in transparent mode. To disable it, apply the following [MeshPassthrough]({{ docs }}/policies/meshpassthrough/) policy:

{% warning %}  
{{ Important }} Before disabling passthrough traffic, check the data plane proxy stats to ensure no traffic is flowing through the `pass_through` cluster. Otherwise, you may unintentionally block critical traffic, leading to system instability.  
{% endwarning %}

{% policy_yaml disable-passthrough %}
```yaml
type: MeshPassthrough
name: disable-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Sidecar"]
  default:
    passthroughMode: None
```
{% endpolicy_yaml %}

With this policy, non-mesh traffic is blocked, preventing external requests from leaving the mesh.

### Configuring non-mesh traffic settings

Regular policies in {{ Kuma }} apply only to mesh traffic, meaning non-mesh traffic cannot be directly targeted. However, if you need to modify the behavior of non-mesh traffic, you can achieve similar results using **MeshProxyPatch** policies. These allow you to adjust settings like circuit breakers and timeouts for traffic that bypasses the mesh.

If you need to change configuration for non-mesh traffic you can use a MeshProxyPatch.

<!-- vale Google.Headings = NO -->
#### Circuit Breaker
<!-- vale Google.Headings = YES -->

Default values:

```yaml
maxConnections: 1024
maxPendingRequests: 1024
maxRequests: 1024
maxRetries: 3
```

[MeshProxyPatch]({{ docs }}/policies/meshproxypatch) to change the defaults:

{% policy_yaml passthrough-thresholds-mpp %}
```yaml
type: MeshProxyPatch
mesh: default
name: custom-mpp-1
spec:
  targetRef:
    kind: Mesh
  default:
    appendModifications:
    - cluster:
        operation: Patch
        match:
          name: "outbound:passthrough:ipv4"
        value: |
          circuit_breakers: {
            thresholds: [
              {
                max_connections: 2048,
                max_pending_requests: 2048,
                max_requests: 2048,
                max_retries: 4
              }
            ]
          }
```
{% endpolicy_yaml %}

#### Timeouts

Default values:

```yaml
connectTimeout: 10s
tcp:
  idleTimeout: 1h
```

MeshProxyPatch to change the defaults:

{% policy_yaml passthrough-timeouts-mpp %}
```yaml
type: MeshProxyPatch
mesh: default
name: custom-mpp-1
spec:
  targetRef:
    kind: Mesh
  default:
    appendModifications:
    - cluster:
        operation: Patch
        match:
          name: "outbound:passthrough:ipv4"
        jsonPatches:
        - op: replace
          path: /connectTimeout
          value: 99s
    - networkFilter:
        operation: Patch
        match:
          name: "envoy.filters.network.tcp_proxy"
          listenerName: "outbound:passthrough:ipv4"
        value: |
          name: envoy.filters.network.tcp_proxy
          typedConfig:
            '@type': type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
            idleTimeout: "3h"
```
{% endpolicy_yaml %}
