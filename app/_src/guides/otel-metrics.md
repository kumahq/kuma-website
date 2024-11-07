---
title: Collect metrics with OpenTelemetry  
---

{{site.mesh_product_name}} provides integration with [OpenTelemetry](https://opentelemetry.io/). You can collect and push 
dataplane proxy and application metrics to [OpenTelemetry collector](https://opentelemetry.io/docs/collector/). Which opens up
lots of possibilities of processing and exporting metrics to multiple ecosystems like [Datadog](https://www.datadoghq.com/),
[Grafana cloud](https://grafana.com/products/cloud/), [Honeycomb](https://www.honeycomb.io/) and more.

## Prerequisites
- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

## Install {{site.mesh_product_name}} observability stack

To start we need to install {{site.mesh_product_name}} observability stack which is build on top of [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/).

```shell
kumactl install observability | kubectl apply -f-
```

We will use it to scrape metrics from OpenTelemetry collector and visualise them on {{site.mesh_product_name}} dashboards.

Since quickstart guide have really restrictive MeshTrafficPermissions we need to allow traffic in `mesh-observability` namespace:

{% if_version lte:2.8.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: allow-observability
spec:
  targetRef:
    kind: MeshSubset
    tags:
      k8s.kuma.io/namespace: mesh-observability
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          k8s.kuma.io/namespace: mesh-observability
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}
{% if_version gte:2.9.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: mesh-observability
  name: allow-observability
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}

## Install OpenTelemetry collector

First we need an OpenTelemetry collector configuration. Save it by running:

```shell
echo "
mode: deployment
config:
  exporters:
    prometheus:
      endpoint: \${env:MY_POD_IP}:8889
  extensions:
    health_check:
      endpoint: \${env:MY_POD_IP}:13133
  processors:
    batch: {}
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: \${env:MY_POD_IP}:4317
  service:
    extensions:
      - health_check
    pipelines:
      metrics:
        receivers: [otlp]
        exporters: [prometheus]
        processors: [batch]
ports:
  otlp:
    enabled: true
    containerPort: 4317
    servicePort: 4317
    hostPort: 4317
    protocol: TCP
    appProtocol: grpc
  prometheus:
    enabled: true
    containerPort: 8889
    servicePort: 8889
    protocol: TCP
image:
  repository: 'otel/opentelemetry-collector-contrib'
resources:
  limits:
    cpu: 250m
    memory: 512Mi
" > values-otel.yaml
```

This is the Helm chart configuration we will be using. This will configure OpenTelemetry collector to listen on grpc port `4317` for metrics 
pushed by dataplane proxy, process and expose collected metrics in Prometheus format on port `8889`. In the next step we 
will configure Prometheus to scrape these metrics. Our configuration relies on [the contrib distribution](https://github.com/open-telemetry/opentelemetry-collector-contrib) of opentelemetry-collector so we set this in the values.

Most important in this configuration is `pipelines` section:

```yaml
pipelines:
  metrics:
    receivers: [otlp]
    exporters: [prometheus]
```

In this basic guide we will focus only on collecting metrics, but this can be also easily configured to collect traces and logs.
We use `otlp` receiver to accept metrics pushed from dataplane proxies. 

Then we have basic recommended processors to limit memory usage and to 
process metrics in batch. You can filter, modify and do more with [available processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor).

Last part is `exporters` section. You can export metrics to multiple destination like Prometheus, Datadog, Grafana Cloud and more. Full list of available exporters can be found [here](https://opentelemetry.io/ecosystem/registry/?component=exporter).
We will use Prometheus exporter for now.

With configuration in place we can install OpenTelemetry collector:

```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install --namespace mesh-observability opentelemetry-collector open-telemetry/opentelemetry-collector -f values-otel.yaml
```

## Configure Prometheus to scrape metrics from OpenTelemetry collector

We need to update `prometheus-server` ConfigMap and add `scrape_configs` entry:
```yaml
- job_name: "opentelemetry-collector"
  scrape_interval: 15s
  static_configs:
    - targets: ["opentelemetry-collector.mesh-observability.svc:8889"]
```

Prometheus will automatically pick up this config and start scraping OpenTelemetry collector. To check if config was applied properly
you can go to Prometheus GUI:

```shell
kubectl port-forward svc/prometheus-server -n mesh-observability 9090:80
```

Now go to http://localhost:9090/targets. You should see new target `opentelemetry-collector`:

<center>
<img src="/assets/images/guides/otel-metrics/prometheus_otel_source.png" alt="Prometheus OpenTelemetry source"/>
</center>

## Enable OpenTelemetry metrics and check results

By now we have installed and configured all needed observability tools: OpenTelemetry collector, Prometheus and Grafana.
We can now apply [MeshMetric policy](/docs/{{ page.release }}/policies/meshmetric):

{% if_version lte:2.8.x %}
```shell
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317' | kubectl apply -f -
```
{% endif_version %}
{% if_version gte:2.9.x %}
```shell
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317' | kubectl apply -f -
```
{% endif_version %}

This policy will configure all dataplane proxies in `default` Mesh to collect and push metrics to OpenTelemetry collector. 

To check results we need to log into Grafana. First enable port forward to Grafana GUI:

```shell
kubectl port-forward svc/grafana -n mesh-observability 3000:80
```

Then navigate to browser `http://localhost:3000` and check `Dataplane` dashboard. You should see something similar to:

<center>
<img src="/assets/images/guides/otel-metrics/grafana-dataplane-view.png" alt="Dataplane Grafana dashboard"/>
</center>

## Next steps

* Further explore [MeshMetric policy](/docs/{{ page.release }}/policies/meshmetric)
* Explore [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog/#opentelemetry) and [MeshTrace](/docs/{{ page.release }}/policies/meshtrace/#opentelemetry) policies that work with OpenTelemetry
* Explore features of [OpenTelemetry collector](https://opentelemetry.io/docs/collector/) for metrics filtering/processing and exporting
* Checkout tutorials on how to push metrics to SaaS solutions [Grafana cloud](https://grafana.com/docs/grafana-cloud/monitor-applications/application-observability/setup/collector/opentelemetry-collector/), [Datadog](https://www.datadoghq.com/blog/ingest-opentelemetry-traces-metrics-with-datadog-exporter/), [Honeycomb](https://docs.honeycomb.io/send-data/opentelemetry/collector/)