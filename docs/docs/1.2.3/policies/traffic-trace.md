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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.3/documentation/http-api).
:::
::::

## Add Datadog backend

### Prerequisites

1. Set up the [Datadog](https://docs.datadoghq.com/tracing/) agent.
1. Set up [APM](https://docs.datadoghq.com/tracing/).
   - For Kubernetes, see [the datadog documentation for setting up Kubernetes](https://docs.datadoghq.com/agent/kubernetes/apm/).

If Datadog is running within Kubernetes, you can expose the APM agent port to Kuma via Kubernetes service.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: v1
kind: Service
metadata:
  name: trace-svc
spec:
  selector:
    app: datadog
  ports:
    - protocol: TCP
      port: 8126
      targetPort: 8126
```
Apply the configuration with `kubectl apply -f [..]`.
:::
::::

### Set up in Kuma

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

where `trace-svc` is the name of the Kubernetes Service you specified when you configured the Datadog APM agent.

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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.3/documentation/http-api).
:::
::::

The `defaultBackend` property specifies the tracing backend to use if it's not explicitly specified in the `TrafficTrace` resource.

## Add TrafficTrace resource

Next, create `TrafficTrace` resources that specify how to collect traces, and which backend to store them in.

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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.2.3/documentation/http-api).
:::
::::

You can also add tags to apply the `TrafficTrace` resource only a subset of data plane proxies. `TrafficTrace` is a [Dataplane policy](how-kuma-chooses-the-right-policy-to-apply.md#dataplane-policy), so you can specify any of the `selectors` tags.

Services should also be instrumented to preserve the trace chain across requests made across different services. You can instrument with a language library of your choice, or you can manually pass the following headers:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-parentspanid`
* `x-b3-spanid`
* `x-b3-sampled`
* `x-b3-flags`

## Configure Grafana to visualize the logs

To visualise your **traces** you need to have a Grafana up and running.
You can install Grafana by following the information of the [official page](https://grafana.com/docs/grafana/latest/installation/) or use the one installed with [Traffic metrics](traffic-metrics.md).

With Grafana installed you can configure a new datasource with url:`http://jaeger-query.kuma-tracing/` so Grafana will be able to retrieve the traces from Jaeger.

<center>
<img src="../images/jaeger_grafana_config.png" alt="Jaeger Grafana configuration" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>
