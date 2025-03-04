---
title: Non-mesh traffic
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}

{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}

## Incoming

With mTLS enabled, external clients cannot access applications inside the mesh. To allow external clients to consume mesh services, consider using [Permissive mTLS]({{ docs }}/policies/mutual-tls/#permissive-mtls).

{% warning %}
{{ Important }}Without [transparent proxy]({{ docs }}/{% if_version lte:2.8.x %}production/dp-config/transparent-proxying/{% endif_version %}{% if_version gte:2.9.x %}networking/transparent-proxy/introduction/{% endif_version %}), application ports remain accessible even if mTLS is enabled. This allows traffic to bypass the data plane proxy, skipping TLS verification. If you choose not to use a transparent proxy, you must secure application ports manually to prevent unauthorized access.
{% endwarning %}

## Outgoing

By default, {{ Kuma }} allows non-mesh traffic to pass through the [data plane proxy]({{ docs }}/introduction/concepts/#data-plane-proxy--sidecar) without applying any policies. For example, if a service sends a request to `{{ site.links.web }}`, those requests won’t be logged, even if traffic logging is enabled in the mesh.

This passthrough mode is enabled by default on all data plane proxies running in transparent mode. To change this behavior, set `networking.outbound.passthrough` in the Mesh resource.

{% tabs passthrough-mode useUrlFragment=false additionalClasses="codeblock" %}  
{% tab passthrough-mode Kubernetes %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  networking:
    outbound:
      passthrough: false
```
{% endtab %}  
{% tab passthrough-mode Universal %}
```yaml
type: Mesh
name: default
networking:
  outbound:
    passthrough: false
```
{% endtab %}  
{% endtabs %}

When `networking.outbound.passthrough` is set to `false`, non-mesh traffic is blocked, preventing any external requests from leaving the mesh.

{% if_version gte:2.8.x %}  
{% tip %}  
Since version 2.8.x, the [MeshPassthrough]({{ docs }}/policies/meshpassthrough) policy allows passthrough traffic for specific sidecars and destinations.  
{% endtip %}  
{% endif_version %}

{% tip %}  
Before disabling passthrough mode (`networking.outbound.passthrough: false`), check the data plane proxy stats to ensure no traffic is flowing through the `pass_through` cluster. Otherwise, you may unintentionally block critical traffic, leading to system instability.  
{% endtip %}

### Policies don't apply to non-mesh traffic

If you need to change configuration for non-mesh traffic 
you can use a {% if_version lte:2.5.x inline:true %}Proxy Template{% endif_version %}{% if_version inline:true gte:2.6.x %}MeshProxyPatch{% endif_version %}.

#### Circuit Breaker

Default values:

```yaml
maxConnections: 1024
maxPendingRequests: 1024
maxRequests: 1024
maxRetries: 3
```

{% if_version lte:2.5.x inline:true %}[ProxyTemplate]({{ docs }}/policies/proxy-template){% endif_version %}{% if_version inline:true gte:2.6.x %}[MeshProxyPatch]({{ docs }}/policies/meshproxypatch){% endif_version %} to change the defaults:

{% if_version lte:2.5.x %}
{% tabs passthrough-thresholds useUrlFragment=false additionalClasses="codeblock" %}
{% tab passthrough-thresholds Kubernetes %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: ProxyTemplate
mesh: default
metadata:
  name: custom-template-1
spec:
  selectors:
    - match:
        kuma.io/service: "*"
  conf:
    imports:
      - default-proxy
    modifications:
      - cluster:
          operation: patch
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
{% endtab %}
{% tab passthrough-thresholds Universal %}
```yaml
type: ProxyTemplate
mesh: default
name: custom-template-1
selectors:
  - match:
      kuma.io/service: "*"
conf:
  imports:
    - default-proxy
  modifications:
    - cluster:
        operation: patch
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
{% endtab %}
{% endtabs %}
{% endif_version %}
{% if_version gte:2.6.x %}
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
{% endif_version %}

#### Timeouts

Default values:

```yaml
connectTimeout: 10s
tcp:
  idleTimeout: 1h
```

{% if_version lte:2.5.x inline:true %}Proxy Template{% endif_version %}{% if_version inline:true gte:2.6.x %}MeshProxyPatch{% endif_version %} to change the defaults:

{% if_version lte:2.5.x %}
{% tabs passthrough-timeouts useUrlFragment=false additionalClasses="codeblock" %}
{% tab passthrough-timeouts Kubernetes %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: ProxyTemplate
mesh: default
metadata:
  name: custom-template-1
spec:
  selectors:
    - match:
        kuma.io/service: "*"
  conf:
    imports:
      - default-proxy
    modifications:
      - cluster:
          operation: patch
          match:
            name: "outbound:passthrough:ipv4"
          value: |
            connect_timeout: "99s"
      - networkFilter:
          operation: patch
          match:
            name: "envoy.filters.network.tcp_proxy"
            listenerName: "outbound:passthrough:ipv4"
          value: |
            name: envoy.filters.network.tcp_proxy
            typedConfig:
              '@type': type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
              idleTimeout: "3h"
```
{% endtab %}
{% tab passthrough-timeouts Universal %}
```yaml
type: ProxyTemplate
mesh: default
name: custom-template-1
selectors:
    - match:
        kuma.io/service: "*"
conf:
  imports:
    - default-proxy
  modifications:
    - cluster:
        operation: patch
        match:
          name: "outbound:passthrough:ipv4"
        value: |
          connect_timeout: "99s"
    - networkFilter:
        operation: patch
        match:
          name: "envoy.filters.network.tcp_proxy"
          listenerName: "outbound:passthrough:ipv4"
        value: |
          name: envoy.filters.network.tcp_proxy
          typedConfig:
            '@type': type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
            idleTimeout: "3h"
```
{% endtab %}
{% endtabs %}
{% endif_version %}
{% if_version gte:2.6.x %}
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
{% endif_version %}
