---
title: Mesh Timeout
---

{% warning %}
This policy uses new policy matching algorithm. 
Do **not** combine with [Timeout policy](/docs/{{ page.release }}/policies/timeout).
{% endwarning %}

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                                             |
| ----------------------- | ------------------------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset`, `MeshHTTPRoute` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                                     |
| `from[].targetRef.kind` | `Mesh`                                                                    |
{% endif_version %}
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`             | Allowed kinds                                                             |
| ----------------------- | ------------------------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshHTTPRoute`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService`                              |
| `from[].targetRef.kind` | `Mesh`                                                                    |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`             | Allowed kinds                                |
| ----------------------- | -------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `Dataplane`, `MeshHTTPRoute`         |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService` |
| `from[].targetRef.kind` | `Mesh`                                       |
{% endif_version %}
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                             |
| ----------------------- | --------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
| `to[].targetRef.kind`   | `Mesh`                                                    |
| `from[].targetRef.kind` | `Mesh`                                                    |
{% endtab %}

{% tab targetRef Delegated Gateway %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                                             |
| ----------------------- | ------------------------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset`, `MeshHTTPRoute` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                                     |
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                                             |
| ----------------------- | ------------------------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshHTTPRoute`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService`                              |
{% endif_version %}
{% endtab %}
{% endtabs %}

{% endif_version %}

{% if_version lte:2.5.x %}
{% if_version gte:2.3.x %}

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ✅   | ✅    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |
| MeshHTTPRoute     | ✅         | ❌   | ❌    |

{% endif_version %}

{% if_version lte:2.2.x %}

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ✅   | ✅    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |

{% endif_version %}
{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

This policy enables {{site.mesh_product_name}} to set timeouts on the inbound and outbound connections
depending on the protocol. Using this policy you can configure TCP and HTTP timeouts.
Timeout configuration is split into two sections: common configuration and HTTP configuration.
Common config is applied to both HTTP and TCP communication. HTTP timeout are only applied when
service is marked as http. More on this in [protocol support section](/docs/{{ page.release }}/policies/protocol-support-in-kuma).

MeshTimeout policy lets you configure multiple timeouts:

- `connectionTimeout`
- `idleTimeout`
- `http.requestTimeout`
- `http.streamIdleTimeout`
- `http.maxStreamDuration`
- `http.maxConnectionDuration`
{% if_version inline:true gte:2.6.x %}- `http.requestHeadersTimeout`{% endif_version %}

### Timeouts explained

#### Connection timeout

Connection timeout specifies the amount of time DP will wait for a TCP connection to be established.

#### Idle timeout

For TCP connections idle timeout is the amount of time that the DP will allow a connection to exist
with no inbound or outbound activity. On the other hand when connection in HTTP time at which an inbound
or outbound connection will be terminated if there are no active streams

#### HTTP request timeout

Request timeout lets you configure how long the data plane proxy should wait for the full response.
In details, it spans between the point at which the entire request has been processed by DP and when the response has
been completely processed by DP.

#### HTTP stream idle timeout

Stream idle timeout is the amount of time that the data plane proxy will allow an HTTP/2 stream to exist with no inbound
or outbound activity.
This timeout is strongly recommended for all requests (not just streaming requests/responses) as it additionally
defends against a peer that does not open the stream window once an entire response has been buffered to be sent to a
downstream client.

{% tip %}
Stream timeouts apply even when you are only using HTTP/1.1 in you services. This is because every connection between
data plane proxies is upgraded to HTTP/2.
{% endtip %}

#### HTTP max stream duration

Max stream duration is the maximum time that a stream’s lifetime will span. You can use this functionality
when you want to reset HTTP request/response streams periodically.

#### HTTP max connection duration

Max connection duration is the time after which an inbound or outbound connection will be drained and/or closed,
starting from when it was first established. If there are no active streams, the connection will be closed.
If there are any active streams, the drain sequence will kick-in, and the connection will be force-closed after 5
seconds.

{% if_version gte:2.6.x %}
#### HTTP request headers timeout

The amount of time that proxy will wait for the request headers to be received. The timer is activated when the first byte of the headers is received, and is disarmed when the last byte of the headers has been received.
{% endif_version %}

### Examples

#### Simple outbound HTTP configuration

This configuration will be applied to all data plane proxies inside of Mesh.

{% if_version lte:2.8.x %}
{% policy_yaml example1 %}
```yaml
type: MeshTimeout
name: timeout-global
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
        http:
          requestTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml example1-29x namespace=kuma-demo %}
```yaml
type: MeshTimeout
name: timeout-global
mesh: default
spec:
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
        http:
          requestTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}

#### Simple TCP configuration

{% if_version lte:2.8.x %}
{% policy_yaml example2 %}
```yaml
type: MeshTimeout
name: tcp-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml example2-29x namespace=kuma-demo %}
```yaml
type: MeshTimeout
name: tcp-timeout
mesh: default
spec:
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}

#### Simple configuration for inbound applied to specific service

This configuration will be applied to `backend` service inbound.

{% if_version lte:2.8.x %}
{% policy_yaml example3 %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml example3-29x namespace=kuma-demo %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml example3-210x namespace=kuma-demo %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```
{% endpolicy_yaml %}
{% endif_version %}

#### Full config applied to inbound and outbound of specific service

This timeout configuration will be applied to all inbound connections to `frontend` and outbound connections
from `frontend` to `backend` service

{% if_version lte:2.8.x %}
{% policy_yaml example4 %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 2s
        http:
          requestTimeout: 10s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml example4-29x namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 2s
        http:
          requestTimeout: 10s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml example4-210x namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshTimeout
name: inbound-timeout
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 2s
        http:
          requestTimeout: 10s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
        sectionName: http
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.3.x %}
#### Target `MeshHTTPRoute`

Timeouts like `http.requestTimeout` and `http.streamIdleTimeout` are configurable per route.
If a `MeshHTTPRoute` creates routes on the outbound listener of the service then `MeshTimeout` policy can configure timeouts on these routes.

In the following example the `MeshHTTPRoute` policy `route-to-backend-v2` redirects all requests to `/v2*` to `backend` instances with `version: v2` tag.
`MeshTimeout` `backend-v2` configures timeouts only for requests that are going through `route-to-backend-v2` route. 

{% if_version lte:2.8.x %}
{% policy_yaml example5 %}
```yaml
type: MeshHTTPRoute
name: route-to-backend-v2
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
            - path:
                type: PathPrefix
                value: /v2
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name_uni: backend
                name_kube: backend_kuma-demo_svc_3001
                tags:
                  version: v2
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml example5-29x namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: route-to-backend-v2
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
            - path:
                type: PathPrefix
                value: /v2
          default:
            backendRefs:
              - kind: MeshService
                name: backend-v2
                namespace: kuma-demo
                port: 3001
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml example5-210x namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHTTPRoute
name: route-to-backend-v2
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
            - path:
                type: PathPrefix
                value: /v2
          default:
            backendRefs:
              - kind: MeshService
                name: backend-v2
                namespace: kuma-demo
                port: 3001
```
{% endpolicy_yaml %}
{% endif_version %}

You can see in the following route that the top level `targetRef` matches the previously defined `MeshHTTPRoute`.
{% if_version lte:2.8.x %}
{% policy_yaml example6 %}
```yaml
type: MeshTimeout
name: backend-v2
mesh: default
spec:
  targetRef:
    kind: MeshHTTPRoute
    name: route-to-backend-v2
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.9.x %}
{% policy_yaml example6-29x namespace=kuma-demo %}
```yaml
type: MeshTimeout
name: backend-v2
mesh: default
spec:
  targetRef:
    kind: MeshHTTPRoute
    name: route-to-backend-v2
  to:
    - targetRef:
        kind: Mesh
      default:
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
```
{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}

{% if_version gte:2.6.x %}
#### Default configuration for all gateways in the Mesh

This configuration will be applied on inbounds and outbounds of all gateways.

{% policy_yaml example7 %}
```yaml
type: MeshTimeout
name: mesh-gateways-timeout-all-default
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Gateway"]
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 5m
        http:
          streamIdleTimeout: 5s
          requestHeadersTimeout: 500ms
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 1h
        http:
          streamIdleTimeout: 5s
```
{% endpolicy_yaml %}
{% endif_version %}

### Defaults

| Property                   | default |
|----------------------------|---------|
| `idleTimeout`                | `1h`      |
| `connectionTimeout`          | `5s`      |
| `http.requestTimeout`        | `15s`    |
| `http.streamIdleTimeout`     | `30m`    |
| `http.maxStreamDuration`     | `0s`     |
| `http.maxConnectionDuration` | `0s`     |
{% if_version inline:true gte:2.6.x %}| `http.requestHeadersTimeout` | `0s`      |{% endif_version %}

{% if_version eq:2.1.x %}
If you don't specify a `from` or `to` section , the defaults from [`Timeout`](/docs/{{ page.release }}/policies/timeout) will be used. This
is [a known bug](https://github.com/kumahq/kuma/issues/5850) and is fixed in the next version.
{% endif_version %}

## All policy options

{% json_schema MeshTimeouts %}
