---
title: MeshRateLimit (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it shouldn't be mixed with [Rate Limit](../rate-limit).
{% endwarning %}

This policy enables per-instance service request limiting. Policy supports ratelimiting of HTTP/HTTP2 requests and TCP connections.

The `MeshRateLimit` policy leverages Envoy's [local rate limiting](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter) for HTTP/HTTP2 and [local rate limit filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/local_rate_limit_filter) for TCP connections.

You can configure:
*  how many requests are allowed in a specified time period, and how the service responds when the limit is reached for HTTP/HTTP2.
*  how many connections are allowed in a specified time period for TCP.

The policy is applied per service instance. This means that if a service `backend` has 3 instances rate limited to 100 requests per second, the overall service is rate limited to 300 requests per second.

Rate limiting supports an [ExternalService](/docs/{{ page.version }}/policies/external-services) only when `ZoneEgress` is enabled.

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ❌  | ✅   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ❌  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |
| MeshGatewayRoute  | ✅        | ❌  | ❌   |

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

The `MeshRateLimit` policy supports both L4/TCP and L7/HTTP limiting. Envoy implements [Tocken Bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/type/v3/token_bucket.proto) algorithm for rate limiting.

### HTTP Rate limiting

 - **`disabled`** - (optional) - should rate limiting policy be disabled
 - **`requestRate`** - configuration of the number of requests in the specific time window
   - **`num`** - the number of requests to limit
   - **`interval`** - the interval for which `requests` will be limited
 - **`onRateLimit`** (optional) - actions to take on RateLimit event
     - **`status`**  (optional) - the status code to return, defaults to `429`
     - **`headers`** - (optional) [headers](#headers) which should be added to every rate limited response

#### Headers

- **`set`** - (optional) - list of headers to set. Overrides value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value
- **`add`** - (optional) - list of headers to add. Appends value if the header exists.
  - **`name`** - header's name
  - **`value`** - header's value

### TCP Rate limiting

TCP rate limiting allows configuration of number of connections in the specific time window.

 - **`disabled`** - (optional) - should rate limiting policy be disabled
 - **`connectionRate`** - configuration of the number of connections in the specific time window
   - **`num`** - the number of requests to limit
   - **`interval`** - the interval for which `connections` will be limited

## Examples

### HTTP Rate limit configured for service `backend` from all services in the Mesh

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRateLimit
metadata:
  name: backend-rate-limit
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
            onRateLimit:
              status: 423
              headers:
                set:
                  - name: "x-kuma-rate-limited"
                    value: "true"
```
We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab usage Universal %}

```yaml
type: MeshRateLimit
mesh: default
name: backend-rate-limit
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        local:
          http:
            requestRate:
              num: 5
              interval: 10s
            onRateLimit:
              status: 423
              headers:
                set:
                  - name: "x-kuma-rate-limited"
                    value: "true"
```
We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

### TCP rate limit for service backend from all services in the Mesh

{% tabs grpc useUrlFragment=false %}
{% tab grpc Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRateLimit
metadata:
  name: backend-rate-limit
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        local:
          tcp:
            connectionRate:
              num: 5
              interval: 10s
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab grpc Universal %}

```yaml
type: MeshRateLimit
name: backend-rate-limit
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        local:
          tcp:
            connectionRate:
              num: 5
              interval: 10s
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}
