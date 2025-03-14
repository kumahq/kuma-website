---
title: MeshRetry
---

{% warning %}
This policy uses new policy matching algorithm. 
Do **not** combine with [Retry](/docs/{{ page.release }}/policies/retry).
{% endwarning %}

This policy enables {{site.mesh_product_name}} to know how to behave if there are failed requests which could be retried.

## TargetRef support matrix

{% if_version gte:2.4.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind` | `Mesh`, `MeshService`, `MeshExternalService`             |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                |
| --------------------- | -------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`                          |
| `to[].targetRef.kind` | `Mesh`, `MeshService`, `MeshExternalService` |
{% endif_version %}
{% if_version lte:2.5.x %}
| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ❌   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ✅  | ❌   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |
{% endif_version %}
{% endtab %}

{% tab Builtin Gateway %}
{% if_version gte:2.6.x %}
| `targetRef`           | Allowed kinds                                             |
| --------------------- | --------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
| `to[].targetRef.kind` | `Mesh`                                                    |
{% endif_version %}
{% if_version lte:2.5.x %}
| `targetRef.kind`    | top level | to  |
| ------------------- | --------- | --- |
| `Mesh`              | ✅        | ✅  |
| `MeshGateway`       | ✅        | ❌  |
| `MeshService`       | ✅        | ❌  |
| `MeshServiceSubset` | ✅        | ❌  |
{% endif_version %}
{% endtab %}

{% if_version gte:2.6.x %}
{% tab Delegated Gateway %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`, `MeshExternalService`             |
{% endif_version %}
{% endtab %}
{% endif_version %}

{% endtabs %}

{% endif_version %}
{% if_version lte:2.3.x %}

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ❌   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ✅  | ❌   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

The policy let you configure retry behaviour for `HTTP`, `GRPC` and `TCP` protocols.
The protocol is selected by picking the most [specific protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma).

Each protocol has a separate section under `default` in the policy yaml.
Some sections are common between protocols or have similar meaning.

### Retry on

The field `retryOn` is a list of conditions which will cause a retry.

For `HTTP` these are related to the response status code or method (`5xx`, `429`, `HttpMethodGet`).
For `gRPC` these are status codes in response headers (`canceled`, `deadline-exceeded`, etc.).
There is no equivalent for `TCP`.

One or more conditions can be specified, for example:

```yaml
retryOn:
  - "429"
  - "503"
```

means that it the policy will retry on a status code 429 **or** 503.

Full list of available `HTTP` conditions:

```yaml
retryOn:
  - 5XX
  - GatewayError
  - Reset
  - Retriable4xx
  - ConnectFailure
  - EnvoyRatelimited
  - RefusedStream
  - Http3PostConnectFailure
  - HttpMethodConnect
  - HttpMethodDelete
  - HttpMethodGet
  - HttpMethodHead
  - HttpMethodOptions
  - HttpMethodPatch
  - HttpMethodPost
  - HttpMethodPut
  - HttpMethodTrace
  - "429" # any HTTP status code
  - "503"
```

Full list of available `gRPC` conditions:

```yaml
retryOn:
  - Canceled
  - DeadlineExceeded
  - Internal
  - ResourceExhausted
  - Unavailable
```

### Back off

This parameter is applicable to both `HTTP` and `GRPC`.

It consists of `BaseInterval` (the amount of time between retries) and 
`MaxInterval` (the maximal amount of time taken between retries).

We use an exponential back-off algorithm with jitter for retries.
Given a base interval B and retry number N,
the back-off for the retry is in the range **[0, (2<sup>N</sup> - 1) × B)**.

For example, given a 25 ms interval, the first retry will be delayed randomly by 0-24 ms,
the second by 0-74 ms,
the third by 0-174 ms, 
and so on.

The interval is capped at a `MaxInterval`, which defaults to 10 times the `BaseInterval`.

### Rate limited back off

This parameter is applicable to both `HTTP` and `GRPC`.

`MeshRetry` can be configured in such a way that
when the upstream server rate limits the request and responds with a header like `retry-after` or `x-ratelimit-reset`
it uses the value from the header to determine **when** to send the retry request instead of the [back off](#back-off) algorithm.

#### Example

Given this configuration:

```yaml
retryOn:
  - "503"
rateLimitedBackOff:
  resetHeaders:
    - name: retry-after
      format: Seconds
    - name: x-ratelimit-reset
      format: UnixTimestamp
```

and an HTTP response:

```HTTP
HTTP/1.1 503 Service Unavailable
retry-after: 15
```

The retry request will be issued after 15 seconds.

If the response is as follows:

```HTTP
HTTP/1.1 503 Service Unavailable
x-ratelimit-reset: 1706096119
```

The request will be retried at `Wed Jan 24 2024 11:35:19 GMT+0000`.

If the response does not contain `retry-after` or `x-ratelimit-reset` header (with valid integer value)
then the amount of time to wait before issuing a request is determined by [back off](#back-off) algorithm.

## Examples

### HTTP frontend to backend on 5xx

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshRetry
name: web-to-backend-retry-http
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 8080
      default:
        http:
          numRetries: 10
          backOff:
            baseInterval: 15s
            maxInterval: 20m
          retryOn:
            - "5xx"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-http
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
        sectionName: http
        _port: 8080
      default:
        http:
          numRetries: 10
          backOff:
            baseInterval: 15s
            maxInterval: 20m
          retryOn:
            - "5xx"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-http
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
        sectionName: http
        _port: 8080
      default:
        http:
          numRetries: 10
          backOff:
            baseInterval: 15s
            maxInterval: 20m
          retryOn:
            - "5xx"
```
{% endpolicy_yaml %}
{% endif_version %}


### gRPC frontend to backend on DeadlineExceeded

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshRetry
name: web-to-backend-retry-grpc
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 8080
      default:
        grpc:
          numRetries: 5
          backOff:
            baseInterval: 5s
            maxInterval: 1m
          retryOn:
            - "DeadlineExceeded"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-grpc
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
        sectionName: http
        _port: 8080
      default:
        grpc:
          numRetries: 5
          backOff:
            baseInterval: 5s
            maxInterval: 1m
          retryOn:
            - "DeadlineExceeded"
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-grpc
mesh: default
spec:
  targetRef:
    kind: Dataplane
    tags:
      app: frontend
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        grpc:
          numRetries: 5
          backOff:
            baseInterval: 5s
            maxInterval: 1m
          retryOn:
            - "DeadlineExceeded"
```
{% endpolicy_yaml %}
{% endif_version %}

### TCP frontend to backend

{% if_version lte:2.8.x %}
{% policy_yaml %}
```yaml
type: MeshRetry
name: web-to-backend-retry-tcp
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 8080
      default:
        tcp:
          maxConnectAttempt: 5
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-tcp
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
        sectionName: http
        _port: 8080
      default:
        tcp:
          maxConnectAttempt: 5
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshRetry
name: frontend-to-backend-retry-tcp
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
        sectionName: http
        _port: 8080
      default:
        tcp:
          maxConnectAttempt: 5
```
{% endpolicy_yaml %}
{% endif_version %}

## All policy options

{% json_schema MeshRetries %}
