---
title: Mesh Health Check
---

{% warning %}
This policy uses new policy matching algorithm. 
Do **not** combine with [HealthCheck](/docs/{{ page.release }}/policies/health-check).
{% endwarning %}

This policy enables {{site.mesh_product_name}} to keep track of the health of every data plane proxy,
with the goal of minimizing the number of failed requests in case a data plane proxy is temporarily unhealthy.

By creating a `MeshHealthCheck` resource you instruct a data plane proxy to keep track of the health status for any other data plane proxy.
When health-checks are properly configured,
a data plane proxy will never send a request to another data plane proxy that is considered unhealthy.
When an unhealthy proxy returns to a healthy state,
{{site.mesh_product_name}} will resume sending requests to it again.

This policy provides **active** checks.
If you want to configure **passive** checks,
please utilize the [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker) policy.
Data plane proxies with **active** checks will explicitly send requests to other data plane proxies to determine if target proxies are healthy or not.
This mode generates extra traffic to other proxies and services as described in the policy configuration.

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                 |
| --------------------- | --------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                         |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endtab %}

{% tab Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% endtab %}

{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ✅  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

The `MeshHealthCheck` policy supports both L4/TCP and L7/HTTP/gRPC checks.

### Protocol selection

The health check protocol is selected by picking the most [specific protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma)
and falls back to more general protocol when specified protocol has `disabled=true` in policy definition.
See [protocol fallback example](#protocol-fallback).

### Examples

#### Health check from web to backend service

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        http:
          path: /health
          expectedStatuses: [200, 201]
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        http:
          path: /health
          expectedStatuses: [200, 201]
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        http:
          path: /health
          expectedStatuses: [200, 201]
```
{% endpolicy_yaml %}
{% endif_version %}

#### Protocol fallback

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        tcp: {} # http has "disabled=true" so TCP (a more general protocol) is used as a fallback
        http:
          disabled: true
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        tcp: {} # http has "disabled=true" so TCP (a more general protocol) is used as a fallback
        http:
          disabled: true
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        tcp: {} # http has "disabled=true" so TCP (a more general protocol) is used as a fallback
        http:
          disabled: true
```
{% endpolicy_yaml %}
{% endif_version %}


#### gRPC health check from cart to payment service

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 3001
      default:
        interval: 15s
        timeout: 5s
        unhealthyThreshold: 3
        healthyThreshold: 2
        grpc:
          serviceName: "grpc.health.v1.CustomHealth"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 15s
        timeout: 5s
        unhealthyThreshold: 3
        healthyThreshold: 2
        grpc:
          serviceName: "grpc.health.v1.CustomHealth"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshHealthCheck
name: web-to-backend-check
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 3001
      default:
        interval: 15s
        timeout: 5s
        unhealthyThreshold: 3
        healthyThreshold: 2
        grpc:
          serviceName: "grpc.health.v1.CustomHealth"
```
{% endpolicy_yaml %}
{% endif_version %}

## Common configuration

- **`interval`** - (optional) interval between consecutive health checks, if not specified then equal to `1m`
- **`timeout`** - (optional) maximum time to wait for a health check response, if not specified then equal to `15s`
- **`unhealthyThreshold`** - (optional) number of consecutive unhealthy checks before considering a host unhealthy, if not specified then equal to 5
- **`healthyThreshold`** - (optional) number of consecutive healthy checks before considering a host healthy, if not specified then equal to 1
- **`initialJitter`** - (optional) if specified, Envoy will start health checking after a random time in
  milliseconds between 0 and `initialJitter`. This only applies to the first health check
- **`intervalJitter`** - (optional) if specified, during every interval Envoy will add `intervalJitter` to the wait time
- **`intervalJitterPercent`** - (optional) if specified, during every interval Envoy will add `intervalJitter` *
  `intervalJitterPercent` / 100 to the wait time. If `intervalJitter` and
  `intervalJitterPercent` are both set, both of them will be used to increase the wait time.
{% if_version lte:2.9.x %}
- **`healthyPanicThreshold`** - (optional) allows to configure panic threshold for Envoy clusters. If not specified,
  the default is 50%. To disable panic mode, set to 0%.
{% endif_version %}
{% if_version gte:2.10.x %}
- **`healthyPanicThreshold`** - (optional) allows to configure panic threshold for Envoy clusters. If not specified,
  the default is 50%. To disable panic mode, set to 0%. ⚠️This is deprecated from version 2.10.x and has been moved to [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker).⚠️
{% endif_version %}
- **`failTrafficOnPanic`** - (optional) if set to true, Envoy will not consider any hosts when the cluster is in
  'panic mode'. Instead, the cluster will fail all requests as if all hosts are unhealthy.
  This can help avoid potentially overwhelming a failing service.
- **`noTrafficInterval`** - (optional) a special health check interval that is used
  when a cluster has never had traffic routed to it.
  This lower interval allows cluster information to be kept up to date,
  without sending a potentially large amount of active health checking traffic for no reason.
  Once a cluster has been used for traffic routing, Envoy will shift back
  to using the standard health check interval that is defined.
  Note that this interval takes precedence over any other.
  The default value for "no traffic interval" is 60 seconds.
- **`eventLogPath`** - (optional) specifies the path to the file where Envoy can log health check events.
  If empty, no event log will be written.
- **`alwaysLogHealthCheckFailures`** - (optional) if set to true, health check failure events will always be logged.
  If set to false, only the initial health check failure event will be logged.
  The default value is false.
- **`reuseConnection`** - (optional) reuse health check connection between health checks. Default is true.

## Protocol specific configuration

### HTTP

HTTP health checks are executed using HTTP2

- **`disabled`** - (optional) - if true HTTP health check is disabled
- **`path`** - (optional) HTTP path to be used during the health checks, if not specified then equal to "/"
- **`expectedStatuses`** (optional) - list of HTTP response statuses which are considered healthy
  - only statuses in the range `[100, 600)` are allowed
  - by default, when this property is not provided only responses with
    status code `200` are being considered healthy
- **`requestHeadersToAdd`** (optional) - [HeaderModifier](#headermodifier) list of HTTP headers which should be added to each health check request

#### HeaderModifier

- **`set`** - (optional) - list of headers to set. Overrides value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value
- **`add`** - (optional) - list of headers to add. Appends value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value

### TCP

- **`disabled`** - (optional) - if true TCP health check is disabled
- **`send`** - (optional) - Base64 encoded content of the message which should be
  sent during the health checks
- **`receive`** - (optional) - list of Base64 encoded blocks of strings which should be
  found in the returning message which should be considered as healthy
  - when checking the response, “fuzzy” matching is performed such that
    each block must be found, and in the order specified, but not
    necessarily contiguous;
  - if **`receive`** section won't be provided or will be empty, checks
    will be performed as "connect only" and will be marked as successful
    when TCP connection will be successfully established.

### gRPC

- **`disabled`** - (optional) - if true gRPC health check is disabled
- **`serviceName`** - (optional) - service name parameter which will be sent to gRPC service
- **`authority`** - (optional) - value of the :authority header in the gRPC health check request,
  by default name of the cluster this health check is associated with

## All policy options

{% json_schema MeshHealthChecks %}
