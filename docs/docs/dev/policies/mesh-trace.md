# Mesh Trace (beta)

::: warning
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [TrafficTrace](traffic-trace.md).
:::

This policy enables publishing traces to a third party tracing solution.

Tracing is supported over HTTP, HTTP2, and gRPC protocols.
You must [explicitly specify the protocol](protocol-support-in-kuma.md) for each service and data plane proxy you want to enable tracing for.

Kuma currently supports the following trace exposition formats:

* `zipkin` traces in this format can be sent to [many different tracing backends](https://github.com/openzipkin/openzipkin.github.io/issues/65) 
* `datadog`

::: warning
Services still need to be instrumented to preserve the trace chain across requests made across different services.

You can instrument with a language library of your choice ([for zipkin](https://zipkin.io/pages/tracers_instrumentation) and [for datadog](https://docs.datadoghq.com/tracing/setup_overview/setup/java/?tab=containers)).
For HTTP you can also manually forward the following headers:

* `x-request-id`
* `x-b3-traceid`
* `x-b3-parentspanid`
* `x-b3-spanid`
* `x-b3-sampled`
* `x-b3-flags`
:::

## Matching matrix

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ❌   | ❌    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ❌   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |
| MeshGatewayRoute  | ✅         | ❌   | ❌    |
| MeshHTTPRoute     | ❌         | ❌   | ❌    |

If you don't understand this table you should read [matching docs](matching.md#matching-matrix)

## Add MeshTrace resource

:::::::: tabs :options="{ useUrlFragment: false }"
::::::: tab "Zipkin"
:::::: tabs :options="{ useUrlFragment: false }"
::::: tab "Kubernetes"
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Minimal example"
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: default
  namespace: kuma-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector.mesh-observability:9411/api/v2/spans
```
:::
::: tab "Full example"
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: default
  namespace: kuma-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: Mesh
    name: default
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector.mesh-observability:9411/api/v2/spans
          apiVersion: httpJson
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
      overall:
        value: 80
      random:
        value: 60
      client:
        value: 40
```
:::
::::

Apply the configuration with `kubectl apply -f [..]`.

:::::
::::: tab "Universal"
:::: tabs  :options="{ useUrlFragment: false }"
::: tab "Minimal example"

```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
```

:::
::: tab "Full example"

```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
    name: default
  default:
    backends:
      - zipkin:
          url: http://jaeger-collector:9411/api/v2/spans
          apiVersion: httpJson
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
      overall:
        value: 80
      random:
        value: 60
      client:
        value: 40
```

:::
::::

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../reference/http-api.md).

:::::
::::::
:::::::
::::::: tab "Datadog"

::: tip
This assumes a Datadog agent is configured and running. If you haven't already check the [Datadog observability page](../explore/observability.md#configuring-datadog).
:::

:::::: tabs :options="{ useUrlFragment: false }"
::::: tab "Kubernetes"
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Minimal example"
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: default
  namespace: kuma-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  default:
    backends:
      - datadog:
          url: http://trace-svc.default.svc.cluster.local:8126
```
:::
::: tab "Full example"
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: default
  namespace: kuma-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: Mesh
    name: default
  default:
    backends:
      - datadog:
          url: http://trace-svc.default.svc.cluster.local:8126
          splitService: true
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
      overall:
        value: 80
      random:
        value: 60
      client:
        value: 40
```
:::
::::

where `trace-svc` is the name of the Kubernetes Service you specified when you configured the Datadog APM agent.

Apply the configuration with `kubectl apply -f [..]`.

:::::
::::: tab "Universal"
:::: tabs  :options="{ useUrlFragment: false }"
::: tab "Minimal example"

```yaml
type: MeshTrace
name: default
mesh: default
spec:
  default:
    backends:
      - datadog:
          url: http://127.0.0.1:8126
```
:::
::: tab "Full example"

```yaml
type: MeshTrace
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
    name: default
  default:
    backends:
      - datadog:
          url: http://127.0.0.1:8126
          splitService: true
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
      overall:
        value: 80
      random:
        value: 60
      client:
        value: 40
```
:::
::::

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../reference/http-api.md).

:::::
::::::

The `splitService` property determines if Datadog service names should be split based on traffic direction and destination.
For example, with `splitService: true` and a `backend` service that communicates with a couple of databases,
you would get service names like `backend_INBOUND`, `backend_OUTBOUND_db1`, and `backend_OUTBOUND_db2` in Datadog.
By default, this property is set to false.

:::::::
::::::::

## Configuration options

### Sampling

:::tip
Most of the time setting only `overall` is sufficient; `random` and `client` are for advanced use cases.
:::

You can configure sampling settings equivalent to Envoy's:
- [overall](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=overall_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [random](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=random_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)
- [client](https://www.envoyproxy.io/docs/envoy/v1.22.5/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto.html?highlight=client_sampling#extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-tracing)

Example:

```yaml
sampling:
  overall:
    value: 80
  random:
    value: 60
  client:
    value: 40
```

### Tags

You can add tags to trace metadata by directly supplying the value ("literal") or by taking it from a header ("header").

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

For `header` - if a value is missing then `default` will be used.
If `default` is not provided then the tag won't be added.

## Targeting parts of the infrastructure

While most commonly we want all the traces to be sent to the same tracing backend,
we can target parts of a `Mesh` by using finer-grained `targetRef` and a designated backend to trace different paths of our service traffic.
This is especially useful when we want traces to never leave a world region, or a cloud, for example.
