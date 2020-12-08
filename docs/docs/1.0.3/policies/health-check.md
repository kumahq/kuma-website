# Health Check

This policy enables Kuma to keep track of the health of every data plane proxy, with the goal of minimizing the number of failed requests in case a data plane proxy is temporarily unhealthy.

By creating an `HealthCheck` resource we can instruct a data plane proxy to keep track of the health status for any other data plane proxy. When health-checks are properly configured, a data plane proxy will never send a request to another data plane proxy that is considered unhealthy. When an unhealthy data plane returns to a healthy state, Kuma will resume sending requests to it again.

This policy provides **active** checks. If you want to configure **passive** checks, please utilize the [Circuit Breaker](./circuit-breaker.md) policy. Data plane proxies with **active** checks will explicitly send requests to other data plane proxies to determine if target data plane proxies are healthy or not. This mode will generate extra traffic to other data plane proxies and services as described in the policy configuration.
proxy will explicitly send requests to other data plane proxies (as described in the policy configuration) to determine if a target data plane is healthy or not. This mode will generate extra traffic to other data plane proxies and services.


## Usage

As usual, we can apply `sources` and `destinations` selectors to determine how health-checks will be performed across our data plane proxies.

`HealthCheck` policy supports L4/TCP (default) and L7/HTTP checks.

### Examples

#### TCP

By providing an optional `tcp` section you can specify Base64 encoded text which
should be sent during health checks, and a list of (also Base64 encoded)
blocks which should be considered as health responses (when checking
the response, “fuzzy” matching is performed such that each block must be
found, and in the order specified, but not necessarily contiguous). If
`receive` section won't be provided or will be empty, checks will
be performed as "connect only" and will be marked as successful when TCP
connection will be successfully established.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: HealthCheck
mesh: default
metadata:
  name: web-to-backend-check
spec:
  sources:
  - match:
      kuma.io/service: web
  destinations:
  - match:
      kuma.io/service: backend
  conf:
    interval: 10s
    timeout: 2s
    unhealthyThreshold: 3
    healthyThreshold: 1
    tcp:
      send: Zm9v
      receive:
      - YmFy
      - YmF6
```
We will apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: HealthCheck
name: web-to-backend-check
mesh: default
sources:
- match:
    kuma.io/service: web
destinations:
- match:
    kuma.io/service: backend
conf:
  interval: 10s
  timeout: 2s
  unhealthyThreshold: 3
  healthyThreshold: 1
  tcp:
    send: Zm9v
    receive:
    - YmFy
    - YmF6
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/1.0.3/documentation/http-api).
:::
::::

#### HTTP

To set up HTTP health checks you have to provide `http`. Constraints:
- field `path` is required and cannot be empty;
- by default every health check request will be attempted using HTTP 2 protocol,
  to change this and use HTTP 1 instead, you have to set value of `useHttp1` property
  to `true`;
- by default the only status code considered as healthy is `200`, if you want to
  change this behaviour and accept other statuses, you can provide the list of valid
  status codes by configuring `expectedStatuses` property (only statuses in the range
  `[100, 600)` are allowed);
- the default behaviour when providing custom HTTP headers which should be added
  to every health check request is that they will be appended to already existing ones,
  to change this behabiour you can add to the header you want to fully replace
  a property `append` set to `true`


:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: HealthCheck
mesh: default
metadata:
  name: web-to-backend-check
spec:
  sources:
  - match:
      kuma.io/service: web
  destinations:
  - match:
      kuma.io/service: backend
  conf:
    interval: 10s
    timeout: 2s
    unhealthyThreshold: 3
    healthyThreshold: 1
    http:
      path: /health
      requestHeadersToAdd:
      - append: false
        header:
          key: Content-Type
          value: application/json
      - header:
          key: Accept
          value: application/json
      expectedStatuses: [200, 201]
      useHttp1: true
```
We will apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: HealthCheck
name: web-to-backend-check
mesh: default
sources:
- match:
    kuma.io/service: web
destinations:
- match:
    kuma.io/service: backend
conf:
  interval: 10s
  timeout: 2s
  unhealthyThreshold: 3
  healthyThreshold: 1
  http:
    path: /health
    requestHeadersToAdd:
    - append: false
      header:
        key: Content-Type
        value: application/json
    - header:
        key: Accept
        value: application/json
    expectedStatuses: [200, 201]
    useHttp1: true
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/1.0.3/documentation/http-api).
:::
::::
