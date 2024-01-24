---
title: MeshMetric
---

{% warning %}
This policy uses new policy matching algorithm.
Do **not** combine with [Traffic Metrics](/docs/{{ page.version }}/policies/traffic-metrics).
{% endwarning %}

{{site.mesh_product_name}} facilitates consistent traffic metrics across all data plane proxies in your mesh.

You can define metrics configuration for a whole Mesh, and optionally tweak certain parts for individual data plane proxies.
For example, you might need to override the default metrics port if it's already in use on the specified machine.

{{site.mesh_product_name}} provides full integration with Prometheus:

* Each proxy can expose its metrics in [Prometheus format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format).
* {{site.mesh_product_name}} exposes an API called the monitoring assignment service (MADS) which exposes proxies configured by `MeshMetric`.

To collect metrics from {{site.mesh_product_name}}, you need to expose metrics from proxies and applications.

{% tip %}
In the rest of this page we assume you have already configured your observability tools to work with {{site.mesh_product_name}}.
If you haven't already read the [observability docs](/docs/{{ page.version }}/explore/observability).
{% endtip %}

## TargetRef support matrix

| TargetRef type    | top level | to | from |
|-------------------|-----------|----|------|
| Mesh              | ✅         | ❌  | ❌    |    
| MeshSubset        | ✅         | ❌  | ❌    |    
| MeshService       | ✅         | ❌  | ❌    |    
| MeshServiceSubset | ✅         | ❌  | ❌    |    

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

There are three main sections of the configuration: `sidecar`, `applications`, `backends`.
The first two define how to scrape parts of the mesh (sidecar and underlying applications), the third one defines what to do with the data (in case of Prometheus instructs to scrape specific address, in case of OpenTelemetry defines where to push data).

{% tip %}
In contrast to [Traffic Metrics](/docs/{{ page.version }}/policies/traffic-metrics) all configuration is dynamic and no restarts of the Data Plane Proxies are needed.
You can define configuration refresh interval by using `KUMA_DATAPLANE_RUNTIME_DYNAMIC_CONFIGURATION_REFRESH_INTERVAL` env var or `{{site.set_flag_values_prefix}}dataplaneRuntime.dynamicConfiguration.refreshInterval` Helm value.
{% endtip %}

### Sidecar

This part of the configuration applies to the data plane proxy scraping.

In case you don't want to retrieve all Envoy's metrics, it's possible to filter them.
You are able to specify [`regex`](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--stats?filter=regex) which causes the metrics endpoint to return only matching metrics.
Also, you can set flag [`usedOnly`](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--stats?usedonly) that returns only metrics updated by Envoy.

Example section of the configuration:

```yaml
    sidecar:
      regex: http2_act.*
      usedOnly: true
```

### Applications

In addition to exposing metrics from the data plane proxies, you might want to expose metrics from applications running next to the proxies.
{{site.mesh_product_name}} allows scraping Prometheus metrics from the applications endpoint running in the same `Pod` or `VM`.
Later those metrics are aggregated and exposed at the same `port/path` as data plane proxy metrics.
It is possible to configure it at the `Mesh` level, for all the applications in the `Mesh`, or just for specific applications.

Here are reasons where you'd want to use this feature:
- Application metrics are labelled with your mesh parameters (tags, mesh, data plane name...), this means that in mixed Universal and Kubernetes mode metrics are reported with the same types of labels.
- Both application and sidecar metrics are scraped at the same time. This makes sure they are coherent (with 2 different scrapers they can end up scraping at different intervals and make metrics harder to correlate).
- If you disable [passthrough](/docs/{{ page.version }}/networking/non-mesh-traffic#outgoing) and your mesh uses mTLS and Prometheus is outside the mesh this is the only way to retrieve these metrics as the app is completely hidden behind the sidecar.

Example section of the configuration:

```yaml
    applications:
      - path: "/metrics/prometheus"
        address: # optional custom address if the underlying application listens on a different address than the Data Plane Proxy
        port: 8888
```

### Backends

```yaml
    backends:
      - type: Prometheus
        prometheus: 
          port: 5670
          path: /metrics
```

This tells {{site.mesh_product_name}} to expose an HTTP endpoint with Prometheus metrics on port `5670` and URI path `/metrics`.

The metrics endpoint is forwarded to the standard Envoy [Prometheus metrics endpoint](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--stats?format=prometheus) and supports the same query parameters.
You can pass the `filter` query parameter to limit the results to metrics whose names match a given regular expression.
By default, all available metrics are returned.

#### Secure metrics with TLS

{{site.mesh_product_name}} allows configuring metrics endpoint with TLS.

```yaml
    backends:
      - type: Prometheus
        prometheus: 
          port: 5670
          path: /metrics
          tls:
            mode: ProvidedTLS
```

In addition to the `MeshMetric` configuration, `kuma-sidecar` requires a provided certificate and key for its operation.

{% tabs expose-mesh-metrics-data-plane-proxies-tls useUrlFragment=false %}
{% tab expose-mesh-metrics-data-plane-proxies-tls Kubernetes %}

When the certificate and key are available within the container, `kuma-sidecar` needs the paths to provided files as the following environment variables:

* `KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH`
* `KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH`

It's possible to use a [`ContainerPatch`](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/#custom-container-configuration) to add variables to `kuma-sidecar`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: kuma-system
spec:
  sidecarPatch:
    - op: add
      path: /env/-
      value: '{
          "name": "KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH",
          "value": "/kuma/server.crt"
        }'
    - op: add
      path: /env/-
      value: '{
          "name": "KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH",
          "value": "/kuma/server.key"
        }'
```

{% endtab %}
{% tab expose-mesh-metrics-data-plane-proxies-tls Universal %}

Please upload the certificate and the key to the machine, and then define the following environment variables with the correct paths:

	* `KUMA_DATAPLANE_RUNTIME_METRICS_CERT_PATH`
	* `KUMA_DATAPLANE_RUNTIME_METRICS_KEY_PATH`

{% endtab %}
{% endtabs %}

#### activeMTLSBackend

We no longer support activeMTLSBackend, if you need to encrypt and authorize the metrics use [Secure metrics with TLS](#secure-metrics-with-tls) with a combination of [one of the authorization methods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).

#### Running multiple prometheus instances

If you need to run multiple instances of Prometheus and want to target different set of Data Plane Proxies you can do this by using Client ID setting on both `MeshMetric` (`clientId`) and [Prometheus configuration](https://github.com/prometheus/prometheus/pull/13278/files#diff-17f1012e0c2fbd9bcd8dff3c23b18ff4b6676eef3beca6f8a3e72e6a36633334R2233) (`client_id`).

{% warning %}
To use `clientId` setting you need to be running at least Prometheus `2.49.0`.
{% endwarning %}

Example configurations differentiated by `prometheus` tag:

{% policy_yaml first %}
```yaml
type: MeshMetric
name: prometheus-one
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      prometheus: "one"
    backends:
      - type: Prometheus
        prometheus: 
          clientId: "prometheus-one" 
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

{% policy_yaml second %}
```yaml
type: MeshMetric
name: prometheus-two
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      prometheus: "two"
    backends:
      - type: Prometheus
        prometheus: 
          clientId: "prometheus-two" 
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

And the Prometheus configurations:

```yaml
scrape_configs:
  - job_name: 'kuma-dataplanes'
    # ...
    kuma_sd_configs:
    - server: http://localhost:5676
      refresh_interval: 60s # different from prometheus-two
      client_id: "prometheus-one"
```

```yaml
scrape_configs:
  - job_name: 'kuma-dataplanes'
    # ...
    kuma_sd_configs:
      - server: http://localhost:5676
        refresh_interval: 20s # different from prometheus-one
        client_id: "prometheus-two"
```

## Examples

### With custom port, path, clientId, application aggregation and service override

The first policy defines a default `MeshMetric` policy for the `default` mesh.
The second policy creates an override for workloads tagged with `framework: example-web-framework`.
That web framework exposes metrics under `/metrics/prometheus` and port `8888`.

{% policy_yaml customone %}
```yaml
type: MeshMetric
mesh: default
name: metrics-default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      usedOnly: true
    backends:
      - type: Prometheus
        prometheus:
          clientId: main-backend 
          port: 5670
          path: /metrics
          tls:
            mode: "ProvidedTLS"
```
{% endpolicy_yaml %}

{% policy_yaml customtwo %}
```yaml
type: MeshMetric
mesh: default
name: metrics-for-mesh-service
spec:
  targetRef:
    kind: MeshSubset
    tags:
      framework: "example-web-framework"
  default:
    applications:
      - path: "/metrics/prometheus"
        port: 8888
```
{% endpolicy_yaml %}

## All policy options

{% json_schema MeshMetrics %}
