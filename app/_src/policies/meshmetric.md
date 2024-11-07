---
title: MeshMetric
---

{% warning %}
This policy uses new policy matching algorithm.
Do **not** combine with [Traffic Metrics](/docs/{{ page.release }}/policies/traffic-metrics).
{% endwarning %}

{{site.mesh_product_name}} facilitates consistent traffic metrics across all data plane proxies in your mesh.

You can define metrics configuration for a whole Mesh, and optionally tweak certain parts for individual data plane proxies.
For example, you might need to override the default metrics port if it's already in use on the specified machine.

{{site.mesh_product_name}} provides full integration with Prometheus:

* Each proxy can expose its metrics in [Prometheus format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format).
* {{site.mesh_product_name}} exposes an API called the monitoring assignment service (MADS) which exposes proxies configured by `MeshMetric`.

{% if_version gte:2.7.x %}
Moreover, {{site.mesh_product_name}} provides integration with OpenTelemetry:
{% endif_version %}

{% if_version lte:2.6.x %}
Moreover, {{site.mesh_product_name}} provides experimental integration with OpenTelemetry:
{% endif_version %}

* Each proxy can publish its metrics to [OpenTelemetry collector](https://opentelemetry.io/docs/collector/). 

To collect metrics from {{site.mesh_product_name}}, you need to expose metrics from proxies and applications.

{% tip %}
In the rest of this page we assume you have already configured your observability tools to work with {{site.mesh_product_name}}.
If you haven't already read the [observability docs](/docs/{{ page.release }}/explore/observability).
{% endtip %}

## TargetRef support matrix

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
{% endif_version %}
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                             |
| ----------------------- | --------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags` |
{% endtab %}

{% tab targetRef Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
{% endif_version %}
{% endtab %}

{% endtabs %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

There are three main sections of the configuration: `sidecar`, `applications`, `backends`.
The first two define how to scrape parts of the mesh (sidecar and underlying applications), the third one defines what to do with the data (in case of Prometheus instructs to scrape specific address, in case of OpenTelemetry defines where to push data).

{% tip %}
In contrast to [Traffic Metrics](/docs/{{ page.release }}/policies/traffic-metrics) all configuration is dynamic and no restarts of the Data Plane Proxies are needed.
You can define configuration refresh interval by using `KUMA_DATAPLANE_RUNTIME_DYNAMIC_CONFIGURATION_REFRESH_INTERVAL` env var or `{{site.set_flag_values_prefix}}dataplaneRuntime.dynamicConfiguration.refreshInterval` Helm value.
{% endtip %}

### Sidecar

{% if site.mesh_product_name != "Kuma" %}
{% if_version lte:2.6.x %}
{% warning %}
If you're using Mesh Manager the field `regex` is no longer available.
You need to use version 2.7.x or above and migrate to `profiles.exclude`.
{% endwarning %}
{% endif_version %}
{% endif %}

This part of the configuration applies to the data plane proxy scraping.
In case you don't want to retrieve all Envoy's metrics, it's possible to filter them.

{% if_version gte:2.7.x %}
Below are different methods of filtering.
The order of the operations is as follows:
1. Unused metrics
2. Profiles
3. Exclude
4. Include
{% endif_version %}

{% if_version lte:2.6.x %}
#### Regex

You are able to specify [`regex`](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--stats?filter=regex) which causes the metrics endpoint to return only matching metrics.
{% endif_version %}

#### Unused metrics

By default, metrics that were not updated won't be published.
You can set the `includeUnused` flag that returns all metrics from Envoy.

{% if_version gte:2.7.x %}
#### Profiles

Profiles are predefined sets of metrics with manual `include` and `exclude` functionality.
There are 3 sections:
- `appendProfiles` - allows to combine multiple predefined profiles of metrics.
Right now you can only define one profile but this might change it the future
(for example there might be feature related profiles like "Fault injection profile" and "Circuit Breaker profile" so you can mix and match the ones that you need based on your features usage).
Today only 3 profiles are available: `All`, `Basic` and `None`.
`All` profile contains all metrics produced by Envoy.
`Basic` profile contains all metrics needed by {{site.mesh_product_name}} dashboards and [golden 4 signals](https://sre.google/sre-book/monitoring-distributed-systems/) metrics.
`None` profile removes all metrics
- `exclude` - after profiles are applied you can manually exclude metrics on top of profile filtering.
- `include` - after exclude is applied you can manually include metrics.
{% endif_version %}

#### Examples

{% if_version lte:2.6.x %}
##### Include unused metrics and filter them by regex

{% policy_yaml include_unused_and_regex %}
```yaml
type: MeshMetric
mesh: default
name: metrics-default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      regex: http2_act.*
      includeUnused: true
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

{% endif_version %}

{% if_version gte:2.7.x %}
##### Include unused metrics of only Basic profile with manual exclude and include

{% policy_yaml include_unused_and_exclude %}
```yaml
type: MeshMetric
mesh: default
name: metrics-default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      includeUnused: true
      profiles:
        appendProfiles:
          - name: Basic
        exclude:
          - type: Regex
            match: "envoy_cluster_external_upstream_rq_.*"
        include:
          - type: Exact
            match: "envoy_cluster_default_total_match_count"
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

##### Include only manually defined metrics

{% policy_yaml include_only_manually_defined %}
```yaml
type: MeshMetric
mesh: default
name: metrics-default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: None
        include:
          - type: Regex
            match: "envoy_cluster_external_upstream_rq_.*"
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

##### Exclude all metrics apart from one manually added

{% policy_yaml exclude_only_manually_defined %}
```yaml
type: MeshMetric
mesh: default
name: metrics-default
spec:
  targetRef:
    kind: Mesh
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: None
        include:
          - type: Regex
            match: "envoy_cluster_external_upstream_rq_.*"
    backends:
      - type: Prometheus
        prometheus:
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}
{% endif_version %}

### Applications

{% if_version gte:2.7.x %}
{% warning %}
Metrics exposed by the application need to be in Prometheus format for the Dataplane Proxy to be able to parse and expose them to either Prometheus or OpenTelemetry backend.
{% endwarning %}
{% endif_version %}

In addition to exposing metrics from the data plane proxies, you might want to expose metrics from applications running next to the proxies.
{{site.mesh_product_name}} allows scraping Prometheus metrics from the applications endpoint running in the same `Pod` or `VM`.
Later those metrics are aggregated and exposed at the same `port/path` as data plane proxy metrics.
It is possible to configure it at the `Mesh` level, for all the applications in the `Mesh`, or just for specific applications.

Here are reasons where you'd want to use this feature:
- Application metrics are labelled with your mesh parameters (tags, mesh, data plane name...), this means that in mixed Universal and Kubernetes mode metrics are reported with the same types of labels.
- Both application and sidecar metrics are scraped at the same time. This makes sure they are coherent (with 2 different scrapers they can end up scraping at different intervals and make metrics harder to correlate).
- If you disable [passthrough](/docs/{{ page.release }}/networking/non-mesh-traffic#outgoing) and your mesh uses mTLS and Prometheus is outside the mesh this is the only way to retrieve these metrics as the app is completely hidden behind the sidecar.

Example section of the configuration:

```yaml
applications:
  - name: "backend" # application name used for logging and to scope OpenTelemetry metrics (optional)
    path: "/metrics/prometheus" # application metrics endpoint path
    address: # optional custom address if the underlying application listens on a different address than the Data Plane Proxy
    port: 8888 # port on which application is listening
```

### Backends

#### Prometheus

```yaml
backends:
  - type: Prometheus
    prometheus: 
      port: 5670
      path: /metrics
```

This tells {{site.mesh_product_name}} to expose an HTTP endpoint with Prometheus metrics on port `5670` and uri path `/metrics`.

The metrics endpoint is forwarded to the standard Envoy [Prometheus metrics endpoint](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#get--stats?format=prometheus) and supports the same query parameters.
You can pass the `filter` query parameter to limit the results to metrics whose names match a given regular expression.
By default, all available metrics are returned.

##### Secure metrics with TLS

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

It's possible to use a [`ContainerPatch`](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/#custom-container-configuration) to add variables to `kuma-sidecar`:

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

##### activeMTLSBackend

We no longer support activeMTLSBackend, if you need to encrypt and authorize the metrics use [Secure metrics with TLS](#secure-metrics-with-tls) with a combination of [one of the authorization methods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).

##### Running multiple Prometheus deployments

If you need to run multiple instances of Prometheus and want to target different set of Data Plane Proxies you can do this by using Client ID setting on both `MeshMetric` (`clientId`) and [Prometheus configuration](https://github.com/prometheus/prometheus/pull/13278/files#diff-17f1012e0c2fbd9bcd8dff3c23b18ff4b6676eef3beca6f8a3e72e6a36633334R2233) (`client_id`).

{% warning %}
Support for `clientId` was added in Prometheus version `2.50.0`.
{% endwarning %}

###### Example Prometheus configuration

Let's assume we have two prometheus deployments `main` and `secondary`. We would like to use each of them to monitor different sets
of data plane proxies, with different tags. 

We can start with configuring each Prometheus deployments to use [Kuma SD](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).
Prometheus's deployments will be differentiated by `client_id` parameter.

Main Prometheus config:
```yaml
scrape_configs:
  - job_name: 'kuma-dataplanes'
    # ...
    kuma_sd_configs:
    - server: http://{{site.mesh_cp_name}}.{{site.mesh_namespace}}:5676
      refresh_interval: 60s # different from prometheus-secondary
      client_id: "prometheus-main" # Kuma will use this to pick proper data plane proxies
```

Secondary Prometheus config:
```yaml
scrape_configs:
  - job_name: 'kuma-dataplanes'
    # ...
    kuma_sd_configs:
      - server: http://{{site.mesh_cp_name}}.{{site.mesh_namespace}}:5676
        refresh_interval: 20s # different from prometheus-main
        client_id: "prometheus-secondary"
```

Now we can configure first `MeshMetric` policy to pick data plane proxies with tag `prometheus: main` for main Prometheus discovery.
`clientId` in policy should be the same as `client_id` in Prometheus configuration.
{% policy_yaml first %}
```yaml
type: MeshMetric
name: prometheus-one
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      prometheus: "main"
  default:
    backends:
      - type: Prometheus
        prometheus: 
          clientId: "prometheus-main"  
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

And policy for secondary Prometheus deployment that will pick data plane proxies with tag `prometheus: secondary`. 
{% policy_yaml second %}
```yaml
type: MeshMetric
name: prometheus-two
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      prometheus: "secondary"
  default:
    backends:
      - type: Prometheus
        prometheus: 
          clientId: "prometheus-secondary" # this clientId should be the same as client_id in Prometheus
          port: 5670
          path: /metrics
```
{% endpolicy_yaml %}

{% if_version lte:2.6.x %}
#### OpenTelemetry (experimental)

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry: 
      endpoint: otel-collector.observability.svc:4317
```

This configuration tells {{site.mesh_product_name}} data plane proxy to push metrics to [OpenTelemetry collector](https://opentelemetry.io/docs/collector/).
Dataplane Proxy will scrape metrics from Envoy and other [applications](/docs/{{ page.release }}/policies/meshmetric/#applications) in a Pod/VM.
and push them to configured OpenTelemetry collector.

When you configure application scraping make sure to specify `application.name` to utilize [OpenTelemetry scoping](https://opentelemetry.io/docs/concepts/instrumentation-scope/) 

##### Limitations

- You cannot configure scraping interval for OpenTelemetry. By default, it will publish metrics to collector every **30 seconds**. Ability to configure scraping interval in policy will be added in the future. 
- Right now {{site.mesh_product_name}} supports configuring only one `OpenTelemetry` backend.
{% if_version lte:2.6.x %}
- OpenTelemetry integration does not take [sidecar](/docs/{{ page.release }}/policies/meshmetric/#sidecar) configuration into account.
  This support will be added in the next release.
{% endif_version %}
- [Application](/docs/{{ page.release }}/policies/meshmetric/#applications) must expose metrics in Prometheus format for this integration to work

{% endif_version %}

{% if_version gte:2.7.x %}
#### OpenTelemetry

```yaml
backends:
  - type: OpenTelemetry
    openTelemetry: 
      endpoint: otel-collector.observability.svc:4317
      refreshInterval: 60s
```

This configuration tells {{site.mesh_product_name}} Dataplane Proxy to push metrics to [OpenTelemetry collector](https://opentelemetry.io/docs/collector/).
Dataplane Proxy will scrape metrics from Envoy and other [applications](/docs/{{ page.release }}/policies/meshmetric/#applications) in a Pod/VM
and push them to configured OpenTelemetry collector, by default every **60 seconds** (use `refreshInterval` to change it).

When you configure application scraping make sure to specify `application.name` to utilize [OpenTelemetry scoping](https://opentelemetry.io/docs/concepts/instrumentation-scope/).

#### Pushing metrics from application to OpenTelemetry collector directly

Right now if you want to expose metrics from your application to OpenTelemetry collector you can access collector directly.

If you have disabled [passthrough](/docs/{{ page.release }}/networking/non-mesh-traffic/#outgoing) in your Mesh you need to
configure [ExternalService](/docs/{{ page.release }}/policies/external-services/#external-service) with you collector endpoint. Example ExternalService:

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: ExternalService
mesh: default
metadata:
  name: otel-collector
spec:
  tags:
    kuma.io/service: otel-collector-grpc
    kuma.io/protocol: grpc
  networking:
    address: otel-collector.observability.svc.cluster.local:4317
```
{% endtab %}
{% tab usage Universal %}
```yaml
type: ExternalService
mesh: default
name: otel-collector
tags:
  kuma.io/service: otel-collector-grpc
  kuma.io/protocol: grpc
networking:
  address: otel-collector.observability.svc.cluster.local:4317
```
{% endtab %}
{% endtabs %}

{% endif_version %}

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
      includeUnused: false
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
