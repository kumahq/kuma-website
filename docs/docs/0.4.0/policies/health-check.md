# Health Check

The goal of Health Checks is to minimize the number of failed requests due to temporary unavailability of a target endpoint.
By applying a Health Check policy you effectively instruct a dataplane to keep track of health statuses for target endpoints.
Dataplane will never send a request to an endpoint that is considered "unhealthy".

Since pro-active health checking might result in a tangible extra load on your applications,
Kuma also provides a zero-overhead alternative - ["passive" health checking](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier).
In the latter case, a dataplane will be making decisions whether target endpoints are healthy based on "real" requests
initiated by your application rather than auxiliary requests initiated by the dataplanes itself.

As usual, `sources` and `destinations` selectors allow you to fine-tune to which `Dataplanes` the policy applies (`sources`)
and what endpoints require health checking (`destinations`).

At the moment, `HealthCheck` policy is implemented at L4 level. In practice, it means that a dataplane is looking at success of TCP connections
rather than individual HTTP requests.

On Universal:

```yaml
type: HealthCheck
name: web-to-backend
mesh: default
sources:
- match:
    service: web
destinations:
- match:
    service: backend
conf:
  activeChecks:
    interval: 10s
    timeout: 2s
    unhealthyThreshold: 3
    healthyThreshold: 1
  passiveChecks:
    unhealthyThreshold: 3
    penaltyInterval: 5s
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: HealthCheck
metadata:
  namespace: kuma-example
  name: web-to-backend
mesh: default
spec:
  sources:
  - match:
      service: web
  destinations:
  - match:
      service: backend
  conf:
    activeChecks:
      interval: 10s
      timeout: 2s
      unhealthyThreshold: 3
      healthyThreshold: 1
    passiveChecks:
      unhealthyThreshold: 3
      penaltyInterval: 5s
```