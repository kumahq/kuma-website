# Traffic Trace

With the `TrafficTrace` policy you can configure tracing on every Kuma DP that belongs to the `Mesh`.
Note that tracing operates on L7 HTTP traffic, so make sure that selected dataplanes are configured with HTTP Protocol.

You can configure tracing in 3 steps:

1) Configure tracing backend

On Universal:

```yaml
type: Mesh
name: default
tracing:
  defaultBackend: my-zipkin
  backends:
  - name: my-zipkin
    sampling: 100.0 
    zipkin:
      url: http://zipkin.local:9411/api/v1/spans
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  tracing:
    defaultBackend: my-zipkin
    backends:
    - name: my-zipkin
      sampling: 100.0 
      zipkin:
        url: http://zipkin.local:9411/api/v1/spans
```

::: tip
If you are starting from scratch, consider using `kumactl install tracing | kubectl apply -f -` to deploy configured Prometheus with Grafana.
:::

2) Select the dataplanes that should send traces for given backend

On Universal:

```yaml
type: TrafficTrace
mesh: default
name: all
selectors:
- match:
    service: '*'
conf:
  backend: my-zipkin
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficTrace
mesh: default
metadata:
  namespace: kuma-demo
  name: default
spec:
  selectors:
  - match:
      service: '*'
  conf:
    backend: my-zipkin
```

::: tip
If a backend in `TrafficTrace` is not explicitly specified, the `defaultBackend` from `Mesh` will be used.
:::

3) Instrument your service so the trace chain is preserved between services. You can either use a library for the language of your choice or manually pass following headers:
* `x-request-id`
* `x-b3-traceid`
* `x-b3-parentspanid`
* `x-b3-spanid`
* `x-b3-sampled`
* `x-b3-flags`


Envoy's Zipkin tracer is also [compatible with Jaeger through Zipkin V1 HTTP API.](https://www.jaegertracing.io/docs/1.13/features/#backwards-compatibility-with-zipkin).

::: warning
You need to restart Kuma DP for tracing configuration to be applied. This limitation will be solved in the next versions of Kuma. 
:::
