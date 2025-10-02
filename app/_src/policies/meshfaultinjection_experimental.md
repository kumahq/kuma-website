---
title: MeshFaultInjection
---

{% tip %}
[MeshIdentity](/docs/{{ page.release }}/policies/meshidentity) has to be enabled to make `MeshFaultInjection` with `matches` work.
{% endtip %}

## Overview

With the MeshFaultInjection policy you can easily test your microservices against resiliency. You can inject failures:
* abort - returns specific http code
* delay - adds delay to response
* response bandwidth - limits network connection speed

With `matches` api you can select subset of clients for which faults should be injected.


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
            value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/client"
      default:
        http:
          - abort:
              httpStatus: 500
              percentage: 50
```
{% endpolicy_yaml %}

### 50.5% of requests to service backend from any service is going to be delayed by 5 seconds

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
          value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/client"
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```
{% endpolicy_yaml %}

### Backend service with a list of faults that are applied for frontend service

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
            value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/client"
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

## All policy options

{% json_schema MeshFaultInjections %}
