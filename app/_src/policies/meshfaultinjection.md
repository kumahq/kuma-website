---
title: MeshFaultInjection
description: Test microservice resilience by injecting HTTP errors, response delays, and bandwidth limits into service traffic.
keywords:
  - fault injection
  - chaos testing
  - resilience testing
content_type: reference
category: policy
---

With the MeshFaultInjection policy you can easily test your microservices against resiliency.

{% warning %}
This policy uses a new policy matching algorithm.
Do **not** combine with [FaultInjection](/docs/{{ page.release }}/policies/fault-injection).
{% endwarning %}

## `targetRef` support matrix

{% if_version gte:2.7.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.8.x %}

| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshServiceSubset`                |
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshServiceSubset`                |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`             | Allowed kinds                                 |
| ----------------------- | --------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshServiceSubset`     |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}

| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`                                                   |
{% endtab %}

{% tab Delegated Gateway %}

`MeshFaultInjection` isn't supported on delegated gateways.

{% endtab %}
{% endtabs %}

{% endif_version %}

{% if_version eq:2.6.x %}
{% tabs %}
{% tab Sidecar %}

| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endtab %}

{% tab Builtin Gateway %}

| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`                                                   |
{% endtab %}

{% tab Delegated Gateway %}

`MeshFaultInjection` isn't supported on delegated gateways.

{% endtab %}
{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ❌  | ✅   |
| `MeshSubset`        | ✅        | ❌  | ✅   |
| `MeshService`       | ✅        | ❌  | ✅   |
| `MeshServiceSubset` | ✅        | ❌  | ✅   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

`MeshFaultInjection` allows configuring a list of HTTP faults. They execute in the same order as they were defined.

```yaml
default:
  http:
    - abort:
        httpStatus: 500
        percentage: "2.5"
      delay:
        value: 5s
        percentage: 5
      responseBandwidth:
        limit: "50Mbps"
        percentage: 50
    - abort:
        httpStatus: 500
        percentage: 10
    - delay:
        value: 5s
        percentage: 5
```

It's worth mentioning that percentage of the next filter depends on the percentage of previous ones.

```yaml
http:
  - abort:
      httpStatus: 500
      percentage: 70
  - abort:
      httpStatus: 503
      percentage: 50
```

That means that for 70% of requests, it returns 500 and for 50% of the 30% that passed it returns 503.

### Abort

Abort defines a configuration of not delivering requests to destination service and replacing the responses from destination data plane by
predefined status code.

- `httpStatus` - HTTP status code which will be returned to source side, has to be in [100 - 599] range
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### Delay

Delay defines a configuration of delaying a response from a destination.

- `value` - the duration during which the response will be delayed
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### ResponseBandwidth limit

ResponseBandwidth defines a configuration to limit the speed of responding to requests.

- `limit` - represented by value measure in Gbps, Mbps, kbps, or bps, for example `10kbps`
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

## Examples

### Service backend returns 500 for 50% of requests from frontend service

{% if_version lte:2.5.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```

{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```

{% endpolicy_yaml %}
{% endif_version %}

### 50.5% of requests to service backend from any service is going to be delayed by 5 seconds

{% if_version lte:2.5.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: backend
  from:
    - targetRef:
        kind: Mesh
        name: default
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: Mesh
        name: default
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: Mesh
        name: default
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  from:
    - targetRef:
        kind: Mesh
        name: default
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

{% endpolicy_yaml %}
{% endif_version %}

### Backend service with a list of faults that are applied for frontend service

{% if_version lte:2.5.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: "2.5"
          - abort:
              httpStatus: 500
              percentage: 10
          - delay:
              value: 5s
              percentage: 5
```

{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
{% policy_yaml %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: "2.5"
          - abort:
              httpStatus: 500
              percentage: 10
          - delay:
              value: 5s
              percentage: 5
```

{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: "2.5"
          - abort:
              httpStatus: 500
              percentage: 10
          - delay:
              value: 5s
              percentage: 5
```

{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: "2.5"
          - abort:
              httpStatus: 500
              percentage: 10
          - delay:
              value: 5s
              percentage: 5
```

{% endpolicy_yaml %}
{% endif_version %}

## See also

- [MeshRetry](/docs/{{ page.release }}/policies/meshretry) - Test retry behavior with fault injection
- [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout) - Test timeout handling with delays
- [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker) - Verify circuit breaker triggers

## All policy options

{% json_schema MeshFaultInjections %}
