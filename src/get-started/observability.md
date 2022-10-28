---
title: Get started with observability
---

`kumactl` ships with a builtin observability stack which consists of:

- [prometheus](https://prometheus.io) for metrics
- [jaeger](https://jaegertracing.io) for ingesting and storing traces
- [loki](https://grafana.com/oss/loki/) for ingesting and storing logs
- [grafana](https://grafana.com/oss/grafana/) for querying and displaying metrics, traces and logs

First, remember to configure Kuma appropriately for the tools in the observability stack:

- [Traffic metrics](/docs/{{ page.version }}/features/observability/traffic-metrics) for telemetry
- [`TrafficTrace`](/docs/{{ page.version }}/features/observability/traffic-tracing) for tracing
- [`TrafficLog`](/docs/{{ page.version }}/features/traffic/log) for logging

On Kubernetes, the stack can be installed with:

```shell
kumactl install observability | kubectl apply -f -
```

This will create a namespace `mesh-observability` with prometheus, jaeger, loki and grafana installed and setup to work with Kuma.

{% warning %}
This setup is meant to be used for trying out Kuma. It is in no way fit for use in production.
For production setups we recommend referring to each project's website or to use a hosted solution like Grafana cloud or Datadog.
{% endwarning %}