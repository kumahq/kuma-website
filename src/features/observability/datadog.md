---
title: Configure Datadog
---


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
