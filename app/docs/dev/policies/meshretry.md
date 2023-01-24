---
title: MeshRetry (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [Retry](../retry).
{% endwarning %}

This policy enables {{site.mesh_product_name}} to know how to behave if there is a failed scenario (i.e. HTTP request) which could be retried.

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ✅  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |
| MeshGatewayRoute  | ❌        | ❌  | ❌   |

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

The policy let you configure retry behaviour for `HTTP`, `GRPC` and `TCP` protocols.
The protocol is selected by picking the most [specific protocol](/docs/{{ page.version }}/policies/protocol-support-in-kuma/#protocol-support-in-kuma).

Each protocol has a separate section under `default` in the policy YAML.
Some sections are common between protocols or have similar meaning.

### Retry on

The field `retryOn` is a list of conditions which will cause a retry.

For `HTTP` these are related to the response status code or method ("5xx", "429", "HttpMethodGet").
For `gRPC` these are status codes in response headers ("canceled", "deadline-exceeded", etc.).
There is no equivalent for `TCP`.

One or more conditions can be specified, for example:

```yaml
retryOn:
  - "429"
  - "503"
```

means that it the policy will retry on a status code 429 **or** 503.

### Backoff

[//]: # (TODO: should this be required - https://github.com/kumahq/kuma/blob/b0925593253a186766174b66ca437a696a10c89d/pkg/plugins/policies/meshretry/api/v1alpha1/validator.go#L151 ? can't we just use envoy default of 25ms / 250ms?)

This parameter is applicable to both `HTTP` and `GRPC`.

It consists of `BaseInterval` (the amount of time between retries) and 
`MaxInterval` (the maximal amount of time taken between retries).

We use a fully jittered exponential back-off algorithm for retries.
Given a base interval B and retry number N,
the back-off for the retry is in the range **[0, (2<sup>N</sup> - 1) × B)**.

For example, given a 25ms interval, the first retry will be delayed randomly by 0-24ms,
the 2nd by 0-74ms,
the 3rd by 0-174ms, 
and so on.

The interval is capped at a `MaxInterval`, which defaults to 10 times the `BaseInterval`.

### Rate limited backoff

This parameter is applicable to both `HTTP` and `GRPC`.

MeshRetry can be configured in such a way that
when the upstream server rate limits the request and responds with a header like `retry-after` or `x-ratelimit-reset`
it uses the value from the header to determine **when** to send the retry request instead of the [backoff](#backoff) algorithm.

This can be configured by using `rateLimitedBackOff` field with `resetHeaders`.

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
then the amount of time to wait before issuing a request is determined by [backoff](#backoff) algorithm.

## Examples

### HTTP web to backend on 5xx

{% tabs meshretry-http useUrlFragment=false %}
{% tab meshretry-http Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: web-to-backend-retry-http
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        http:
          numRetries: 10
          backOff:
            baseInterval: 15s
            maxInterval: 20m
          retryOn:
            - "5xx"
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshretry-http Universal %}

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
      default:
        http:
          numRetries: 10
          backOff:
            baseInterval: 15s
            maxInterval: 20m
          retryOn:
            - "5xx"
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../../reference/http-api).

{% endtab %}
{% endtabs %}

### gRPC web to backend on DeadlineExceeded

{% tabs meshretry-http useUrlFragment=false %}
{% tab meshretry-http Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: web-to-backend-retry-grpc
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        grpc:
          numRetries: 5
          backOff:
            baseInterval: 5s
            maxInterval: 1m
          retryOn:
            - "DeadlineExceeded"
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshretry-http Universal %}

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
      default:
        grpc:
          numRetries: 5
          backOff:
            baseInterval: 5s
            maxInterval: 1m
          retryOn:
            - "DeadlineExceeded"
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../../reference/http-api).

{% endtab %}
{% endtabs %}

### TCP web to backend

{% tabs meshretry-http useUrlFragment=false %}
{% tab meshretry-http Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: web-to-backend-retry-tcp
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        tcp:
          maxConnectAttempt: 5
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshretry-http Universal %}

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
      default:
        tcp:
          maxConnectAttempt: 5
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../../reference/http-api).

{% endtab %}
{% endtabs %}
