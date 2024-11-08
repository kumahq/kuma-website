---
title: MeshTrace
---

{% warning %}
This policy uses new policy matching algorithm.
Do **not** combine with [TrafficTrace](/docs/{{ page.release }}/policies/traffic-trace).
{% endwarning %}

This policy enables publishing traces to a third party tracing solution.

Tracing is supported over HTTP, HTTP2, and gRPC protocols.
You must [explicitly specify the protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma) for each service and data plane proxy you want to enable tracing for.

{{site.mesh_product_name}} currently supports the following trace exposition formats:

- `Zipkin` traces in this format can be sent to [many different tracing backends](https://github.com/openzipkin/openzipkin.github.io/issues/65)
- `Datadog`

{% warning %}
Services still need to be instrumented to preserve the trace chain across requests made across different services.

You can instrument with a language library of your choice ([for Zipkin](https://zipkin.io/pages/tracers_instrumentation) and [for Datadog](https://docs.datadoghq.com/tracing/setup_overview/setup/java/?tab=containers)).
For HTTP you can also manually forward the following headers:

- `x-request-id`
- `x-b3-traceid`
- `x-b3-parentspanid`
- `x-b3-spanid`
- `x-b3-sampled`
- `x-b3-flags`
{% endwarning %}

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
{% endif_version %}
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`      | Allowed kinds         |
| ---------------- | --------------------- |
| `targetRef.kind` | `Mesh`, `MeshGateway` |
{% endtab %}

{% tab targetRef Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`                                     |
{% endif_version %}
{% endtab %}

{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ❌  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ❌  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

### Sampling

{% tip %}
Most of the time setting only `overall` is sufficient. `random` and `client` are for advanced use cases.
{% endtip %}

You can configure sampling settings equivalent to Envoy's:

- [overall](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=overall_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [random](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=random_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [client](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=client_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)

The value is always a percentage and is between 0 and 100.

Example:

```yaml
sampling:
  overall: 80
  random: 60
  client: 40
```

### Tags

You can add tags to trace metadata by directly supplying the value (`literal`) or by taking it from a header (`header`).

Example:

```yaml
tags:
  - name: team
    literal: core
  - name: env
    header:
      name: x-env
      default: prod
  - name: version
    header:
      name: x-version
```

If a value is missing for `header`, `default` is used.
If `default` isn't provided, then the tag won't be added.

### Backends

#### Datadog

You can configure a Datadog backend with a `url` and `splitService`.

Example:
```yaml
datadog:
  url: http://my-agent:8080 # Required. The url to reach a running datadog agent
  splitService: true # Default to false. If true, it will split inbound and outbound requests in different services in Datadog
```

The `splitService` property determines if Datadog service names should be split based on traffic direction and destination.
For example, with `splitService: true` and a `backend` service that communicates with a couple of databases,
you would get service names like `backend_INBOUND`, `backend_OUTBOUND_db1`, and `backend_OUTBOUND_db2` in Datadog.

#### Zipkin

In most cases the only field you'll want to set in `url`.

Example:
```yaml
zipkin:
  url: http://jaeger-collector:9411/api/v2/spans # Required. The url to a zipkin collector to send traces to 
  traceId128bit: false # Default to false which will expose a 64bits traceId. If true, the id of the trace is 128bits
  apiVersion: httpJson # Default to httpJson. It can be httpJson, httpProto and is the version of the zipkin API
  sharedSpanContext: false # Default to true. If true, the inbound and outbound traffic will share the same span. 
```

{% if_version gte:2.2.x %}
#### OpenTelemetry

The only field you can set is `endpoint`.

Example:
```yaml
openTelemetry:
  endpoint: otel-collector:4317 # Required. Address of OpenTelemetry collector
```
{% endif_version %}

## Examples

### Zipkin

{% if_version eq:2.2.x %}
Simple example:
{% policy_yaml simple-zipkin %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-zipkin %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
          apiVersion: httpJson
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.3.x %}
{% if_version lte:2.8.x %}
Simple example:
{% policy_yaml simple-zipkin-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-zipkin-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
          apiVersion: httpJson
```
{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
Simple example:
{% policy_yaml simple-zipkin-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-zipkin-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: Zipkin
        zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
          apiVersion: httpJson
```
{% endpolicy_yaml %}
{% endif_version %}

### Datadog

{% tip %}
This assumes a Datadog agent is configured and running. If you haven't already check the [Datadog observability page](/docs/{{ page.release }}/explore/observability#configuring-datadog).
{% endtip %}

{% if_version eq:2.2.x %}
Simple example:
{% policy_yaml simple-datadog %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - datadog:
          url: http://127.0.0.1:8126
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-datadog %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - datadog:
          url: http://127.0.0.1:8126
          splitService: true
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.3.x %}
{% if_version lte:2.8.x %}
Simple example:
{% policy_yaml simple-datadog-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: Datadog
        datadog:
          url: http://127.0.0.1:8126
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-datadog-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: Datadog
        datadog:
          url: http://127.0.0.1:8126
          splitService: true
```
{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
Simple example:
{% policy_yaml simple-datadog-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    backends:
      - type: Datadog
        datadog:
          url: http://127.0.0.1:8126
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-datadog-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: Datadog
        datadog:
          url: http://127.0.0.1:8126
          splitService: true
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.2.x %}
### OpenTelemetry

{% tip %}
This assumes a OpenTelemetry collector is configured and running.
If you haven't already check the [OpenTelementry operator](https://github.com/open-telemetry/opentelemetry-operator).
{% endtip %}

{% if_version eq:2.2.x %}
Simple example:
{% policy_yaml simple-otel %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-otel %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.3.x %}
{% if_version lte:2.8.x %}
Simple example:
{% policy_yaml simple-otel-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-otel-23x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
Simple example:
{% policy_yaml simple-otel-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}

Full example:
{% policy_yaml extended-otel-29x %}
```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    tags:
      - name: team
        literal: core
      - name: env
        header:
          name: x-env
          default: prod
      - name: version
        header:
          name: x-version
    sampling:
      overall: 80
      random: 60
      client: 40
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.com:4317
```
{% endpolicy_yaml %}
{% endif_version %}
{% endif_version %}

### Targeting parts of the infrastructure

While usually you want all the traces to be sent to the same tracing backend,
you can target parts of a `Mesh` by using a finer-grained `targetRef` and a designated backend to trace different paths of our service traffic.
This is especially useful when you want traces to never leave a world region, or a cloud, for example.

In this example, we have two zones `east` and `west`, each of these with their own Zipkin collector: `east.zipkincollector:9411/api/v2/spans` and `west.zipkincollector:9411/api/v2/spans`.
We want data plane proxies in each zone to only send traces to their local collector.

To do this, we use a `TargetRef` kind value of `MeshSubset` to filter which data plane proxy a policy applies to.

{% if_version lte:2.2.x %}
West only policy:

{% policy_yaml west-only %}
```yaml
type: MeshTrace
name: trace-west
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: west
  default:
    backends:
      - zipkin:
          url: http://west.zipkincollector:9411/api/v2/spans
```
{% endpolicy_yaml %}

East only policy:

{% policy_yaml east-only %}
```yaml
type: MeshTrace
name: trace-east
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: east
  default:
    backends:
      - zipkin:
          url: http://east.zipkincollector:9411/api/v2/spans
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.3.x %}
West only policy:

{% policy_yaml west-only-23x %}
```yaml
type: MeshTrace
name: trace-west
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: west
  default:
    backends:
      - type: Zipkin
        zipkin:
          url: http://west.zipkincollector:9411/api/v2/spans
```
{% endpolicy_yaml %}

East only policy:

{% policy_yaml east-only-23x %}
```yaml
type: MeshTrace
name: trace-east
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: east
  default:
    backends:
      - zipkin:
          url: http://east.zipkincollector:9411/api/v2/spans
```
{% endpolicy_yaml %}
{% endif_version %}

## All policy options

{% json_schema MeshTraces %}
