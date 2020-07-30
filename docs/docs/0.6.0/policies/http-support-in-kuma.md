# HTTP support in Kuma

At its core, `Kuma` distinguishes between 2 major categories of traffic: `HTTP` traffic and opaque `TCP` traffic.

It the former case, `Kuma` can provide deep insights down to application-level transactions, in the latter case the observability is limited to connection-level statistics.

So, as a user of `Kuma`, you're _highly encouraged_ to give it a hint whether your `service` supports `HTTP` or not.

By doing this,

* you will get reacher metrics with [`Traffic Metrics`](../traffic-metrics) policy
* you will get reacher logs with [`Traffic Log`](../traffic-log) policy
* you will be able to use [`Traffic Trace`](../traffic-trace) policy

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
On `Kubernetes`, to give `Kuma` a hint that your `service` supports `HTTP` protocol, you need to add a `<port>.service.kuma.io/protocol` annotation to the `k8s` `Service` object.

E.g.,

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: kuma-example
  annotations:
    8080.service.kuma.io/protocol: http # let Kuma know that your service supports HTTP protocol
spec:
  selector:
    app: web
  ports:
  - port: 8080
```

:::
::: tab "Universal"
On `Universal`, to give `Kuma` a hint that your `service` supports `HTTP` protocol, you need to add a `protocol` tag to the `inbound` interface of your `Dataplane`.

E.g.,

```yaml
type: Dataplane
mesh: default
name: web
networking:
  address: 192.168.0.1 
  inbound:
  - port: 80
    servicePort: 8080
    tags:
      kuma.io/service: web
      kuma.io/protocol: http # let Kuma know that your service supports HTTP protocol
```
:::
::::

## HTTP/2 support

Kuma by default upgrades connection between Dataplanes to HTTP/2. If you want to enable HTTP/2 on connections between a dataplane and an application, use `protocol: http2` tag.
