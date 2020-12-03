# Health Check

This policy enables Kuma to keep track of the health of every data plane proxy, with the goal of minimizing the number of failed requests in case a data plane proxy is temporarily unhealthy.

By creating an `HealthCheck` resource we can instruct a data plane proxy to keep track of the health status for any other data plane proxy. When health-checks are properly configured, a data plane proxy will never send a request to another data plane proxy that is considered unhealthy. When an unhealthy data plane returns to a healthy state, Kuma will resume sending requests to it again.

This policy provides **active** checks. If you want to configure **passive** checks, please utilize the [Circuit Breaker](./circuit-breaker.md) policy. Data plane proxies with **active** checks will explicitly send requests to other data plane proxies to determine if target data plane proxies are healthy or not. This mode will generate extra traffic to other data plane proxies and services as described in the policy configuration.
proxy will explicitly send requests to other data plane proxies (as described in the policy configuration) to determine if a target data plane is healthy or not. This mode will generate extra traffic to other data plane proxies and services.


## Usage

As usual, we can apply `sources` and `destinations` selectors to determine how health-checks will be performed across our data plane proxies.

At the moment, the `HealthCheck` policy supports L4 checks that validate the health status of the underlying TCP connections.

By providing `tcp` section you can specify Base64 encoded text which
will be sent during the health checks and list of (also Base64 encoded)
blocks which should be considered as a health response (when checking
the response, “fuzzy” matching is performed such that each block must be
found, and in the order specified, but not necessarily contiguous). If
`receive` section won't be provided or will be empty, health checks will
be performed as "connect only" and will be marked as successful when TCP
connection will be successfully established.

Below an example:

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

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/1.0.2/documentation/http-api).
:::
::::
