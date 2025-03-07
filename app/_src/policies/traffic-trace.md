---
title: Traffic Trace
---
{% if_version gte:2.6.x %}
{% warning %}
New to Kuma? Don't use this, check the [`MeshTrace` policy](/docs/{{ page.release }}/policies/meshtrace) instead.
{% endwarning %}
{% endif_version %}

This policy enables tracing logging to a third party tracing solution. 

Tracing is supported over HTTP, HTTP2, and gRPC protocols. You must [explicitly specify the protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma) for each service and data plane proxy you want to enable tracing for.

You must also:

1. [Add a tracing backend](#add-a-tracing-backend-to-the-mesh). You specify a tracing backend as a [`Mesh`](/docs/{{ page.release }}/production/mesh/) resource property.
2. [Add a TrafficTrace resource](#add-traffictrace-resource). You pass the backend to the `TrafficTrace` resource.

{{site.mesh_product_name}} currently supports the following trace exposition formats:

* `zipkin` traces in this format can be sent to [many different tracing backends](https://github.com/openzipkin/openzipkin.github.io/issues/65). 
* `datadog`

{% warning %}
Services still need to be instrumented to preserve the trace chain across requests made across different services.

You can instrument with a language library of your choice ([for zipkin](https://zipkin.io/pages/tracers_instrumentation) and [for datadog](https://docs.datadoghq.com/tracing/setup_overview/setup/java/?tab=containers)).
For HTTP you can also manually forward the following headers:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-parentspanid`
* `x-b3-spanid`
* `x-b3-sampled`
* `x-b3-flags`
{% endwarning %}

## Add a tracing backend to the mesh

### Zipkin

{% tip %}
This assumes you already have a zipkin compatible collector running.
If you haven't, read the [observability docs](/docs/{{ page.release }}/explore/observability).
{% endtip %}

{% tabs %}
{% tab Kubernetes %}

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
        url: http://jaeger-collector.mesh-observability:9411/api/v2/spans # If not using `kuma install observability` replace by any zipkin compatible collector address.
```

Apply the configuration with `kubectl apply -f [..]`.
{% endtab %}
{% tab Universal %}
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
      url: http://my-jaeger-collector:9411/api/v2/spans # Replace by any zipkin compatible collector address.
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).
{% endtab %}
{% endtabs %}

### Datadog

{% tip %}
This assumes a Datadog agent is configured and running. If you haven't already check the [Datadog observability page](/docs/{{ page.release }}/explore/observability#configuring-datadog). 
{% endtip %}

{% tabs %}
{% tab Kubernetes %}

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
{% endtab %}

{% tab Universal %}
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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).
{% endtab %}
{% endtabs %}

The `defaultBackend` property specifies the tracing backend to use if it's not explicitly specified in the `TrafficTrace` resource.

## Add TrafficTrace resource

Next, create `TrafficTrace` resources that specify how to collect traces, and which backend to send them to.

{% tabs %}
{% tab Kubernetes %}
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
{% endtab %}

{% tab Universal %}
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

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).
{% endtab %}
{% endtabs %}

{% tip %}
When `backend ` field is omitted, the logs will be forwarded into the `defaultBackend` of that `Mesh`.
{% endtip %}

You can also add tags to apply the `TrafficTrace` resource only a subset of data plane proxies. `TrafficTrace` is a [Dataplane policy](/docs/{{ page.release }}/policies/how-kuma-chooses-the-right-policy-to-apply#dataplane-policy), so you can specify any of the `selectors` tags.

{% tip %}
While most commonly we want all the traces to be sent to the same tracing backend, we can optionally create multiple tracing backends in a `Mesh` resource and store traces for different paths of our service traffic in different backends by leveraging {{site.mesh_product_name}} tags.
This is especially useful when we want traces to never leave a world region, or a cloud, for example.
{% endtip %}

## All options

{% json_schema TrafficTrace type=proto %}
