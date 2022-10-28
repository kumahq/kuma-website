---
title: Configure Grafana
---



#### Visualizing traces

To visualise your **traces** you need to have Grafana up and running.

{% tip %}
[`kumactl install observability`](#demo-setup) sets this up out of the box.
{% endtip %}

With Grafana installed you can configure a new datasource with url:`http://jaeger-query.mesh-observability/` (or whatever url jaeger can be queried at).
Grafana will then be able to retrieve the traces from Jaeger.

<center>
<img src="/assets/images/docs/jaeger_grafana_config.png" alt="Jaeger Grafana configuration" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

You can then add a [TrafficTrace policy](/docs/{{ page.version }}/policies/traffic-trace) to your mesh to start emitting traces.
At this point you can visualize your traces in Grafana by choosing the jaeger datasource in the [explore section](https://grafana.com/docs/grafana/latest/explore/).

#### Visualizing logs

To visualise your **containers' logs** and your **access logs** you need to have a Grafana up and running.

{% tip %}
[`kumactl install observability`](#demo-setup) sets this up out of the box.
{% endtip %}

<center>
<img src="/assets/images/docs/loki_grafana_config.png" alt="Loki Grafana configuration" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

You can then add a [TrafficLog policy](/docs/{{ page.version }}/policies/traffic-log) to your mesh to start emitting access logs. Loki will pick up logs that are sent to `stdout`. To send logs to `stdout` you can configure the logging backend as shown below:

{% tabs visualizing-logs useUrlFragment=false %}
{% tab visualizing-logs Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  logging:
    defaultBackend: stdout
    backends:
      - name: stdout
        type: file
        conf:
          path: /dev/stdout
```

{% endtab %}
{% tab visualizing-logs Universal %}

```yaml
type: Mesh
name: default
logging:
  defaultBackend: stdout
  backends:
    - name: stdout
      type: file
      conf:
        path: /dev/stdout
```

{% endtab %}
{% endtabs %}

At this point you can visualize your **containers' logs** and your **access logs** in Grafana by choosing the loki datasource in the [explore section](https://grafana.com/docs/grafana/latest/explore/).

For example, running: `{container="kuma-sidecar"} |= "GET"` will show all GET requests on your cluster.
To learn more about the search syntax check the [Loki docs](https://grafana.com/docs/loki/latest/logql/).

{% tip %}
**Nice to have**

Having your Logs and Traces in the same visualisation tool can come really handy. By adding the `traceId` in your app logs you can visualize your logs and the related Jaeger traces.
To learn more about it go read [this article](https://grafana.com/blog/2020/05/22/new-in-grafana-7.0-trace-viewer-and-integrations-with-jaeger-and-zipkin/).
{% endtip %}

### Grafana extensions

The Kuma community has built a datasource and a set of dashboards to provide great interactions between Kuma and Grafana.

#### Datasource and service map

The Grafana Datasource is a datasource specifically built to relate information from the control plane with Prometheus metrics.

Current features include:

- Display the graph of your services with the MeshGraph using [Grafana nodeGraph panel](https://grafana.com/docs/grafana/latest/visualizations/node-graph/).
- List meshes.
- List zones.
- List services.

To use the plugin you'll need to add the binary to your Grafana instance by following the [installation instructions](https://github.com/kumahq/kuma-grafana-datasource).

To make things simpler the datasource is installed and configured when using [`kumactl install observability`](#demo-setup).

#### Dashboards

Kuma ships with default dashboards that are available to import from [the Grafana Labs repository](https://grafana.com/orgs/konghq).

##### Kuma Dataplane

This dashboard lets you investigate the status of a single dataplane in the mesh.

<center>
<img src="/assets/images/docs/0.4.0/kuma_dp1.jpeg" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.4.0/kuma_dp2.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.4.0/kuma_dp3.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/1.1.2/kuma_dp4.png" alt="Kuma Dataplane dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### Kuma Mesh

This dashboard lets you investigate the aggregated statistics of a single mesh.
It provides a topology view of your service traffic dependencies (**Service Map**)
and includes information such as number of requests and error rates.

<center>
<img src="/assets/images/docs/grafana_dashboard_mesh.png" alt="Kuma Mesh dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### Kuma Service to Service

This dashboard lets you investigate aggregated statistics from dataplanes of specified source services to dataplanes of specified destination service.

<center>
<img src="/assets/images/docs/0.4.0/kuma_service_to_service.png" alt="Kuma Service to Service dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/1.1.2/kuma_service_to_service_http.png" alt="Kuma Service to Service HTTP" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### Kuma CP

This dashboard lets you investigate control plane statistics.

<center>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp1.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp2.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
<img src="/assets/images/docs/0.7.1/grafana-dashboard-kuma-cp3.png" alt="Kuma CP dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### Kuma Service

This dashboard lets you investigate aggregated statistics for each service.

<center>
<img src="/assets/images/docs/1.1.2/grafana-dashboard-kuma-service.jpg" alt="Kuma Service dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

##### Kuma MeshGateway

This dashboard lets you investigate aggregated statistics for each builtin gateway.

<center>
<img src="/assets/images/docs/grafana_dashboard_gateway.png" alt="Kuma Gateway dashboard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>
