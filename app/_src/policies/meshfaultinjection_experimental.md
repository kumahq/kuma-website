---
title: MeshFaultInjection
description: Test microservice resilience by injecting HTTP errors, delays, and bandwidth limits with client-specific fault targeting.
keywords:
  - fault injection
  - chaos testing
  - resilience testing
content_type: reference
category: policy
---

{% tip %}
[MeshIdentity](/docs/{{ page.release }}/policies/meshidentity) has to be enabled to make `MeshFaultInjection` with `matches` work.
{% endtip %}

## Overview

With the MeshFaultInjection policy you can easily test your microservices against resiliency. You can:

* return specific HTTP error codes to verify error-handling logic.
* introduce artificial response delays to test timeout and retry behavior.
* restrict response speed to emulate slow or unstable network connections.

With `matches` api you can select subset of clients for which faults should be injected.

## Configuration

MeshFaultInjection supports three types of faults

### Abort

Abort defines a configuration of not delivering requests to destination service and replacing the responses from destination data plane by
predefined status code.

* `httpStatus` - HTTP status code which will be returned to source side, has to be in [100 - 599] range
* `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### Delay

Delay defines a configuration of delaying a response from a destination.

* `value` - the duration during which the response will be delayed
* `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

<!-- vale Google.Headings = NO -->
### ResponseBandwidth limit
<!-- vale Google.Headings = YES -->

ResponseBandwidth defines a configuration to limit the speed of responding to requests.

* `limit` - represented by value measure in Gbps, Mbps, kbps, or bps, for example `10kbps`
* `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### List of multiple failures

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

## Examples

### Service backend returns 500 for 50% of requests from frontend service

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
  rules:
    - matches:
        - spiffeID:
            type: Exact
            value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/frontend"
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```

{% endpolicy_yaml %}

### 50.5% of requests to service backend from any frontend service is going to be delayed by 5 seconds

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
  rules:
    - matches:
      - spiffeID:
          type: Exact
          value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/frontend"
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

{% endpolicy_yaml %}

### Backend service applies all faults from list for requests coming from frontend service

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
  rules:
    - matches:
        - spiffeID:
            type: Exact
            value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/frontend"
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: "2.5"
          - abort:
              httpStatus: 503
              percentage: 10
          - delay:
              value: 5s
              percentage: 5
```

{% endpolicy_yaml %}

## See also

* [MeshRetry](/docs/{{ page.release }}/policies/meshretry) - Configure retry behavior for failed requests
* [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout) - Test timeout handling with delays
* [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker) - Verify circuit breaker behavior

## All policy options

{% json_schema MeshFaultInjections %}
