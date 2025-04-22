---
title: Logging
---

When encountering issues, it is often necessary to increase logging levels to gain further insight into the problem. Below, we will explore the options for changing the log levels of various components in both Kubernetes and Universal deployments.

## Adjusting logging levels for Kuma-DP
Logging levels can be adjusted on a per-kuma-dp-based component basis. These components include:

* Data plane proxies
* Zone ingress
* Zone egress


The available Envoy logging levels are:

* trace
* debug
* info
* warning/warn
* error
* critical
* off

See `ALL_LOGGER_IDS` in [logger.h from Envoy source](https://github.com/envoyproxy/envoy/blob/main/source/common/common/logger.h#L36) for a list of available components.


{% tabs %}
{% tab Kubernetes %}
**Option 1: Annotations** 

The below annotations can be used to adjust logging levels and components:

`kuma.io/envoy-log-level`: Specifies the log level for Envoy system logs to enable (affects all components).

`kuma.io/envoy-component-log-level`: Specifies the log level for Envoy system logs to enable by component. This allows targeting specific components, each with its own log level.

**Note**: These annotations must be added to the pod or pod template of a workload. Making this change will trigger a `restart` or `rollout` of the workload.

All components:
```yaml
spec:
  selector:
    matchLabels:
      app: postgres
  replicas: 1
  template:
    metadata:
      annotations:
        kuma.io/envoy-log-level: debug
        kuma.io/envoy-component-log-level: dns:debug
```

Targeted Components:
```yaml
spec:
  selector:
    matchLabels:
      app: postgres
  replicas: 1
  template:
    metadata:
      annotations:
        kuma.io/envoy-component-log-level: "dns:debug,connection:trace"
```
**Option 2: Port forwarding** 
The Envoy interface can also be accessed directly. This can be achieved using Kubernetes port-forwarding capabilities, as the Envoy admin interface is not exposed by default.

```shell
kubectl port-forward kuma-demo-app-76df4d8cf5-9q9j9 -n kuma-demo 9901:9901 2>&1 &
```

Once port forwarding is set up, you can increase the log level by sending an `HTTP POST` request with one of the supported values. The debug-level logs will then be available via the standard logging facilities (for example, stderr on Kubernetes):

```shell
curl -X POST http://localhost:9901/logging?level=debug
```
Or targeting a particular component:

```shell
curl -X POST http://localhost:9901/logging?wasm=debug
```

{% endtab %}
{% tab Universal %}

In Universal mode, logging can be enabled by passing the `--envoy-log-level` flag to the kuma-dp process.

```shell
kuma-dp run --envoy-log-level=debug
```

You can optionally target specific components, each with its own log level, by passing the flag:
`--envoy-component-log-level`

```shell
kuma-dp run --envoy-component-log-level="upstream:debug,connection:trace"
```

{% endtab %}
{% endtabs %}


## Adjusting logging levels for Kuma-CP
The available logging levels for Control Planes are:

* debug
* info
* off


{% tabs %}
{% tab Kubernetes %}
When using Helm to deploy on Kubernetes, the following can be used to change the Control Plane log level:

```yaml
kuma:
  controlPlane:
   logLevel: "debug"
```

Additionally, the --log-level flag can be passed as an argument to the kuma-cp binary in your container's definition.

```yaml
containers:
  - name: control-plane
    image: "docker.io/kong/kuma-cp:2.9.3"
    args:
      - run
      - --log-level=debug
      - --config-file=/etc/kuma.io/kuma-control-plane/config.yaml
```

{% endtab %}
{% tab Universal %}

In Universal mode, logging can be enabled by passing the `--envoy-log-level` flag to the kuma-dp process.

```shell
kuma-cp run --log-level=debug
``` 

{% endtab %}
{% endtabs %}

## Adjusting logging levels for CoreDNS
Logging for CoreDNS does not have specific levels; it is either on/true or off/false.


{% tabs %}
{% tab  Kubernetes %}
When using Helm to deploy on Kubernetes, the following can be used to change the DNS log level:

```yaml
kuma:
  dataPlane:
    dnsLogging: true
```

Additionally, the environment variable `KUMA_RUNTIME_KUBERNETES_INJECTOR_BUILTIN_DNS_LOGGING` can be set in your container's definition.

```yaml
      containers:
        - name: control-plane
          image: "docker.io/kong/kuma-cp:2.9.3"
          env:
            - name: KUMA_RUNTIME_KUBERNETES_INJECTOR_BUILTIN_DNS_LOGGING
              value: "true"
```

{% endtab %}
{% tab Universal %}

In Universal mode, logging can be enabled by setting the environment variable `KUMA_RUNTIME_KUBERNETES_INJECTOR_BUILTIN_DNS_LOGGING`.

```shell
export KUMA_RUNTIME_KUBERNETES_INJECTOR_BUILTIN_DNS_LOGGING=true
``` 

{% endtab %}
{% endtabs %}