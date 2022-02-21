# Inspect API

Starting the version 1.5.0 Kuma implements several HTTP endpoints that improve debugging experience. These endpoints form Inspect API. Inspect API
is fully supported by `kumactl`, but can be used directly, using the [HTTP API](./http-api/#inspect-api).

## Matched policies

There is a list of rules Kuma uses to match policies with data plane proxies, more on it in 
[How Kuma chooses the right policy to apply](../../policies/how-kuma-chooses-the-right-policy-to-apply). If deployment
With many policies it's hard to understand which policy is selected for a specific data plane proxy.
proxy. That's where Inspect API may help:

```shell
kumactl inspect dataplane backend-1 --mesh=default
```
```text
DATAPLANE:
  ProxyTemplate
    pt-1
  TrafficTrace
    backends-eu

INBOUND 127.0.0.1:10010:10011(backend):
  TrafficPermission
    allow-all-default

OUTBOUND 127.0.0.1:10006(gateway):
  Timeout
    timeout-all-default
  TrafficRoute
    route-all-default

SERVICE gateway:
  CircuitBreaker
    circuit-breaker-all-default
  HealthCheck
    gateway-to-backend
  Retry
    retry-all-default
```

Each data plane proxy has 4 places where policy could be attached:  

- Inbound – policy is applied to envoy inbound listener
- Outbound – policy is applied to envoy outbound listener
- Service – policy is applied to envoy outbound cluster (upstream cluster)
- Dataplane – the area where policy applied is not specific, could affect inbound/outbound listeners and clusters

The command in the example above shows what policies were matched for every type of attachment. 

## Affected data plane proxies

Sometimes it's useful to see if it's safe to delete or modify some policy. Before doing any critical changes
it is worth checking what data plane proxies will be affected. This could be done using Inspect API as well:

```shell
kumactl inspect traffic-permission tp1 --mesh=default
```
```text
Affected data plane proxies:

  backend-1:
    inbound 127.0.0.1:10010:10011(backend)
    inbound 127.0.0.1:20010:20011(backend-admin)
    inbound 127.0.0.1:30010:30011(backend-api)

  web-1:
    inbound 127.0.0.1:10020:10021(web)
```

This command works for all types of policies.

## Envoy proxy configuration

Kuma has 3 components that built on top of envoy – kuma-dp, zone-ingress and zone-egress. During debugging, you can access envoy config dump.
Inspect API gives access to config dumps of all envoy-based components:

Get config dump for data plane proxy:
```shell
kumactl inspect dataplane backend-1 --config-dump
```

Get config dump for zone-ingress:
```shell
kumactl inspect zoneingress zi-1 --config-dump
```

Get config dump for zone-egress:
```shell
kumactl inspect zoneegress ze-1 --config-dump
```

::: warning
In order to get config dump in Multizone deployment `kumactl` should be pointed to Zone CP, today Global CP doesn't have access 
to envoy config dumps. This is a limitation, and we're going to resolve it in the next releases. 
:::
