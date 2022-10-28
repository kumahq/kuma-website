---
title: Observability
---

This page will describe how to configure different observability tools to work with Kuma.

## Control plane metrics

Control plane metrics are exposed on port `:5680` and available under the standard path `/metrics`.

## Configuring Grafana

## Configuring Datadog

The recommended way to use Datadog is with its [agent](https://docs.datadoghq.com/agent).

{% tabs datadog useUrlFragment=false %}
{% tab datadog Kubernetes %}
The [Datadog agent docs](https://docs.datadoghq.com/agent/kubernetes/installation) have in-depth installation methods.
{% endtab %}

{% tab datadog Universal %}
Checkout the [Datadog agent docs](https://docs.datadoghq.com/agent/basic_agent_usage).
{% endtab %}
{% endtabs %}

### Metrics

Kuma exposes metrics with [traffic metrics](/docs/{{ page.version }}/policies/traffic-metrics) in Prometheus format.

You can add annotations to your pods to enable the Datadog agent to scrape metrics.

{% tabs metrics useUrlFragment=false %}
{% tab metrics Kubernetes %}
Please refer to the dedicated [documentation](https://docs.datadoghq.com/containers/kubernetes/prometheus/?tabs=helm#metric-collection-with-prometheus-annotations).
{% endtab %}

{% tab metrics Universal %}
You need to setup your agent with an [openmetrics.d/conf.yaml](https://docs.datadoghq.com/integrations/guide/prometheus-host-collection/#pagetitle).
{% endtab %}
{% endtabs %}

### Tracing

Checkout the

1. Set up the [Datadog](https://docs.datadoghq.com/tracing/) agent.
2. Set up [APM](https://docs.datadoghq.com/tracing/).

{% tabs tracing useUrlFragment=false %}
{% tab tracing Kubernetes %}
Configure the [Datadog agent for APM](https://docs.datadoghq.com/agent/kubernetes/apm/).

If Datadog is not running on each node you can expose the APM agent port to Kuma via Kubernetes service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trace-svc
spec:
  selector:
    app.kubernetes.io/name: datadog-agent-deployment
  ports:
    - protocol: TCP
      port: 8126
      targetPort: 8126
```

Apply the configuration with `kubectl apply -f [..]`.

Check if the label of the datadog pod installed has not changed (`app.kubernetes.io/name: datadog-agent-deployment`),
if it did adjust accordingly.
{% endtab %}

{% tab tracing Universal %}
Checkout the [Datadog agent docs](https://docs.datadoghq.com/agent/basic_agent_usage)
{% endtab %}
{% endtabs %}

Once the agent is configured to ingest traces you'll need to configure a [TrafficTrace](/docs/{{ page.version }}/policies/traffic-trace).

### Logs

The best way to have Kuma and Datadog work together is with [TCP ingest](https://docs.datadoghq.com/agent/logs/?tab=tcpudp#custom-log-collection).

Once your agent is configured with TCP ingest you can configure a [TrafficLog](/docs/{{ page.version }}/policies/traffic-log) for data plane proxies to send logs.

## Observability in multi-zone

Kuma is multi-zone at heart. We explain here how to architect your telemetry stack to accommodate multi-zone.

### Prometheus

When Kuma is used in multi-zone the recommended approach is to use 1 Prometheus instance in each zone and to send the metrics of each zone to a global Prometheus instance.

Prometheus offers different ways to do this:

- [Federation](https://prometheus.io/docs/prometheus/latest/federation/) the global Prometheus will scrape each zone Prometheuses.
- [Remote Write](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations) each zone Prometheuses will directly write their metrics to the global, this is meant to be more efficient the API the federation.
- [Remote Read](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations) like remote write but the other way around.

### Jaeger, Loki, Datadog and others

Most telemetry components don't have a hierarchical setup like Prometheus.
If you want to have a central view of everything you can set up the system in global and have each zone send their data to it.
Because zone is present in data plane tags you shouldn't be worried about metrics, logs and traces overlapping between zones.
