---
title: MeshFaultInjection
---

With the MeshFaultInjection policy you can easily test your microservices against resiliency.

{% warning %}
This policy uses a new policy matching algorithm.
Do **not** combine with [FaultInjection](/docs/{{ page.version }}/policies/fault-injection).
{% endwarning %}

## `targetRef` support matrix

{% if_version gte:2.7.x %}
{% tabs targetRef27x useUrlFragment=false %}
{% tab targetRef27x Sidecar %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshServiceSubset` |
{% endtab %}

{% tab targetRef27x Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`                                                   |
{% endtab %}

{% tab targetRef27x Delegated Gateway %}

`MeshFaultInjection` isn't supported on delegated gateways.

{% endtab %}
{% endtabs %}

{% endif_version %}

{% if_version eq:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `from[].targetRef.kind` | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`                                                   |
{% endtab %}

{% tab targetRef Delegated Gateway %}

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

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/introduction).

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

Abort defines a configuration of not delivering requests to destination service and replacing the responses from destination dataplane by
predefined status code.

- `httpStatus` - HTTP status code which will be returned to source side, has to be in [100 - 599] range
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### Delay

Delay defines a configuration of delaying a response from a destination.

- `value` - the duration during which the response will be delayed
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

### ResponseBandwidth limit

ResponseBandwidth defines a configuration to limit the speed of responding to requests.

- `limit` - represented by value measure in Gbps, Mbps, kbps, or bps, e.g. 10kbps
- `percentage` - a percentage of requests on which abort will be injected, has to be in [0.0 - 100.0] range. If the value is a double number, put it in quotes.

## Examples
### Service backend returns 500 for 50% of requests from frontend service

{% tabs meshfaultinjection-backend-to-frontend-simple useUrlFragment=false %}
{% tab meshfaultinjection-backend-to-frontend-simple Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: MeshService
    name: backend
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

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshfaultinjection-backend-to-frontend-simple Universal %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshService
    name: backend
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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

### 50.5% of requests to service backend from any service is going to be delayed by 5s

{% tabs meshfaultinjection-from-all useUrlFragment=false %}
{% tab meshfaultinjection-from-all Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: frontend
      default:
        http:
          - delay:
              percentage: "50.5"
              value: 5s
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshfaultinjection-from-all Universal %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshService
    name: backend
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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

### Backend service with a list of faults that are applied for frontend service

{% tabs meshfaultinjection-list-of-faults useUrlFragment=false %}
{% tab meshfaultinjection-list-of-faults Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: MeshService
    name: backend
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

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshfaultinjection-list-of-faults Universal %}

```yaml
type: MeshFaultInjection
mesh: default
name: default-fault-injection
spec:
  targetRef:
    kind: MeshService
    name: backend
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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

## All policy options

{% json_schema MeshFaultInjections %}
