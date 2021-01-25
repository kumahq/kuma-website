# Health checks

Health is an extremely important part of the microservice architecture for various reasons. Load balancers rely on the 
health status of the application while picking endpoint from load balancer set. Users want the application state to be 
observable through the GUI or CLI. Orchestrators like Kubernetes also want to know the application status to manage 
lifecycle of the application. 

Kuma supports several aspects of the health checking. There are two policies which allows configuring active and passive:
[Health Check](../policies/health-check.md) and [Circuit Breaker](../policies/circuit-breaker.md).

Kuma is able to track the status of the Envoy proxy. If grpc stream with Envoy is disconnected then Kuma considers this 
proxy as offline. 

Also, every `inbound` in the Dataplane model has `health` section:

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 127.0.0.1
  inbound:
    - port: 11011
      servicePort: 11012
      health:
        ready: true
      tags:
        kuma.io/service: backend
        kuma.io/protocol: http
```

This `health.ready` status is intended to show the status of the application itself. It is set differently depending on 
the environment ([Kubernetes](#kubernetes-probes) or [Universal](#universal-probes)), but it's treated the same way 
regardless of the environment:

- if proxy status is `Offline`, then Dataplane is `Offline`:
- if proxy status is `Online`:
  - if all inbounds are ready then Dataplane is `Online`
  - if all inbounds are not ready then Dataplane is `Offline`
  - if at least one of the inbounds is not ready then Dataplane is `Partially degraded` 
  - if inbound is not ready then it's not included in the load-balancer set which means it doesn't receive the traffic
  - if all inbounds which implement the same service are ready then service is `Online`
  - if all inbounds which implement the same service are not ready then service is `Offline`
  - if at least one of the inbounds which implement the same service is not ready then service is `Partially degraded`

## Kubernetes probes

Kuma natively supports the `httpGet` Kubernetes probes. By default, Kuma overrides the specified probe with a virtual one. For example, if we specify the following probe:

```yaml
livenessProbe:
  httpGet:
    path: /metrics
    port: 3001
  initialDelaySeconds: 3
  periodSeconds: 3
```

Kuma will replace it with:

```yaml
livenessProbe:
  httpGet:
    path: /3001/metrics
    port: 9000
  initialDelaySeconds: 3
  periodSeconds: 3
```

Where `9000` is a default virtual probe port, which can be configured in `kuma-cp.config`:

```yaml
runtime:
  kubernetes:
    injector:
      virtualProbesPort: 19001
```
And can also be overwritten in the Pod's annotations:

```yaml
annotations:
  kuma.io/virtual-probes-port: 19001
```

To disable Kuma's probe virtualziation, we can either set it in Kuma's configuration gile `kuma-cp.config`:

```yaml
runtime:
  kubernetes:
    injector:
      virtualProbesEnabled: true
```

or in the Pod's annotations:

```yaml
annotations:
  kuma.io/virtual-probes: enabled
```

:::tip
Even if virtual probes are disabled Kuma takes `pod.status.containerStatuses.ready` in order to fill `dataplane.inbound.health` section.
:::

## Universal probes

On Universal there is no single standard for probing the application. For health checking of the application status on
Universal Kuma is using Envoy's Health Discovery Service (HDS). Envoy does health checks and reports the status back to Kuma Control Plane.

In order to configure health checking of your application you have to update `inbound` config with `serviceProbe`:

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 127.0.0.1
  inbound:
    - port: 11011
      servicePort: 11012
      serviceProbe:
        timeout: 2s
        interval: 1s
        healthyThreshold: 1
        unhealthThreshold: 1
        tcp: {}
      tags:
        kuma.io/service: backend
        kuma.io/protocol: http
```

`Timeout`, `Interval`, `HealthyThreshold` and `UnhealthyThreshold` are optional. Default values for them are configured in kuma-cp config:

```yaml
# Dataplane Server configuration that servers API like Bootstrap/XDS/SDS for the Dataplane.
dpServer:
  ...
  hds:
    # Enabled if true then Envoy will actively check application's ports, but only on Universal.
    # On Kubernetes this feature disabled for now regardless the flag value
    enabled: true # ENV: KUMA_DP_SERVER_HDS_ENABLED
    # Interval for Envoy to send statuses for HealthChecks
    interval: 5s # ENV: KUMA_DP_SERVER_HDS_INTERVAL
    # RefreshInterval is an interval for re-genarting configuration for Dataplanes connected to the Control Plane
    refreshInterval: 10s # ENV: KUMA_DP_SERVER_HDS_REFRESH_INTERVAL
    # Check defines a HealthCheck configuration
    checkDefaults:
      # Timeout is a time to wait for a health check response. If the timeout is reached the
      # health check attempt will be considered a failure
      timeout: 2s # ENV: KUMA_DP_SERVER_HDS_CHECK_TIMEOUT
      # Interval between health checks
      interval: 1s # ENV: KUMA_DP_SERVER_HDS_CHECK_INTERVAL
      # NoTrafficInterval is a special health check interval that is used when a cluster has
      #	never had traffic routed to it
      noTrafficInterval: 1s # ENV: KUMA_DP_SERVER_HDS_CHECK_NO_TRAFFIC_INTERVAL
      # HealthyThreshold is a number of healthy health checks required before a host is marked healthy
      healthyThreshold: 1 # ENV: KUMA_DP_SERVER_HDS_CHECK_HEALTHY_THRESHOLD
      # UnhealthyThreshold is a number of unhealthy health checks required before a host is marked unhealthy
      unhealthyThreshold: 1 # ENV: KUMA_DP_SERVER_HDS_CHECK_UNHEALTHY_THRESHOLD
```
