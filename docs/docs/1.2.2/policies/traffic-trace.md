# Traffic Trace

This policy enables tracing logging to a third party tracing solution. 

Tracing is supported over HTTP, HTTP2, and gRPC protocols in a [`Mesh`](../mesh). You must [explicitly specify the protocol](./protocol-support-in-kuma/) for each service and data plane proxy you want to enable tracing for.

You must also:

1. [Add a tracing backend](#add-a-tracing-backend). You specify a tracing backend as a [`Mesh`](../mesh) resource property.
1. [Add a TrafficTrace resource](#add-a-traffictrace-resource). YOu pass the backend to the `TrafficTrace` resource.

Kuma currently supports the following backends:

* `zipkin`
  * [Jaeger](https://www.jaegertracing.io/) as the Zipkin collector. The Zipkin examples specify Jaeger, but you can modify for a Zipkin-only deployment.
* `datadog`

::: tip
While most commonly we want all the traces to be sent to the same tracing backend, we can optionally create multiple tracing backends in a `Mesh` resource and store traces for different paths of our service traffic in different backends by leveraging Kuma tags. This is especially useful when we want traces to never leave a world region, or a cloud, for example.
:::

## Add Jaeger backend

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

::: tip
On Kubernetes you can deploy Jaeger automatically in a `kuma-tracing` namespace with `kumactl install tracing | kubectl apply -f -`.
:::
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  tracing:
    defaultBackend: jaeger-collector
    backends:
    - name: jaeger-collector
      type: zipkin
      sampling: 100.0
      conf:
        url: http://jaeger-collector.kuma-tracing:9411/api/v2/spans
```

Apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: Mesh
name: default
tracing:
  defaultBackend: jaeger-collector
  backends:
  - name: jaeger-collector
    type: zipkin
    sampling: 100.0
    conf:
      url: http://jaeger-collector.kuma-tracing:9411/api/v2/spans
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.2/documentation/http-api).
:::
::::

## Add Datadog backend

Follow the instructions at [Datadog](https://docs.datadoghq.com/tracing/) to set up the agent, either on bare metal or within Kubernetes. Specify the endpoint as `address:` in either `IP:Port` format or `unix:/var/run/datadog/apm.socket` if connecting via Unix Domain Socket.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  tracing:
    defaultBackend: datadog-collector
    backends:
    - name: datadog-collector
      type: datadog
      sampling: 100.0
      conf:
        address: trace-svc.datadog.svc.cluster.local
        port: 8126
```

Apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: Mesh
name: default
tracing:
  defaultBackend: datadog-collector
  backends:
  - name: datadog-collector
    type: datadog
    sampling: 100.0
    conf:
      address: 127.0.0.1
      port: 8126
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.2/documentation/http-api).
:::
::::

The `defaultBackend` property specifies the tracing backend to use if it's not explicitly specified in the `TrafficTrace` resource.

## Add a TrafficTrace resource

Once we have added a tracing backend, we can now create `TrafficTrace` resources that will determine how we are going to collecting traces, and what backend we should be using to store them.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficTrace
mesh: default
metadata:
  name: trace-all-traffic
spec:
  selectors:
  - match:
      kuma.io/service: '*'
  conf:
    backend: jaeger-collector # or the name of any backend defined for the mesh 
```

Apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: TrafficTrace
name: trace-all-traffic
mesh: default
selectors:
- match:
    kuma.io/service: '*'
conf:
  backend: jaeger-collector # or the name of any backend defined for the mesh
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.2/documentation/http-api).
:::
::::

We can use Kuma Tags to apply the `TrafficTrace` resource in a more target way to a subset of data plane proxies as opposed to all of them (like we do in the example by using the `kuma.io/service: '*'` selector),

It is important that we instrument our services to preserve the trace chain between requests that are made across different services. We can either use a library in the language of our choice, or we can manually pass the following headers:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-parentspanid`
* `x-b3-spanid`
* `x-b3-sampled`
* `x-b3-flags`

As noted before, Envoy's Zipkin tracer is also [compatible with Jaeger through Zipkin V2 HTTP API.](https://www.jaegertracing.io/docs/1.13/features/#backwards-compatibility-with-zipkin).

## Matching

`TrafficTrace` is a [Dataplane policy](how-kuma-chooses-the-right-policy-to-apply.md#dataplane-policy). You can use all the tags in the `selectors` section.
