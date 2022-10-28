---
title: Configure Prometheus
---


The {{ site.mesh_product_name }} community has contributed a builtin service discovery to Prometheus, it is documented in the [Prometheus docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).
This service discovery will connect to the control plane and retrieve all data planes with enabled metrics which Prometheus will scrape and retrieve metrics according to your [traffic metrics setup](/docs/{{ page.version }}/policies/traffic-metrics).

{% tip %}
There are 2 ways you can run prometheus:

1. Inside the mesh (default for [`kumactl install observability`](#demo-setup)). In this case you can use mTLS to retrieve the metrics. This provides high security but will require one prometheus per mesh and might not be accessible if your mesh becomes unavailable. It will also require one Prometheus deployment per {{ site.mesh_product_name }} mesh.
2. Outside the mesh. In this case you'll need to specify `skipMTLS: true` in the [traffic metrics configuration](/docs/{{ page.version }}/policies/traffic-metrics). This is less secured but will ensure Prometheus is as available as possible. It is also easier to add to an existing setup with services in and outside the mesh.

In production, we recommend the second option as it provides better visibility when things go wrong, and it's usually acceptable for metrics to be less secure.
{% endtip %}

### Using an already existing prometheus setup

In Prometheus version 2.29 and later, you can add {{ site.mesh_product_name }} metrics to your `prometheus.yml`:

```sh
scrape_configs:
    - job_name: 'kuma-dataplanes'
      scrape_interval: "5s"
      relabel_configs:
      - source_labels:
        - __meta_kuma_mesh
        regex: "(.*)"
        target_label: mesh
      - source_labels:
        - __meta_kuma_dataplane
        regex: "(.*)"
        target_label: dataplane
      - source_labels:
        - __meta_kuma_service
        regex: "(.*)"
        target_label: service
      - action: labelmap
        regex: __meta_kuma_label_(.+)
      kuma_sd_configs:
      - server: "http://kuma-control-plane.kuma-system.svc:5676" # replace with the url of your control plane
```

For more information, see [the Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kuma_sd_config).

For earlier versions of Prometheus, {{ site.mesh_product_name }} provides the `kuma-prometheus-sd` tool, which runs alongside your Prometheus instance.
This tool fetches a list of current data plane proxies from the {{ site.mesh_product_name }} control plane and saves the list in Prometheus-compatible format
to a file on disk. Prometheus watches for changes to the file and updates its scraping configuration accordingly.

1.  Run `kuma-prometheus-sd`, for example:

    ```shell
    kuma-prometheus-sd run \
      --cp-address=grpcs://kuma-control-plane.internal:5676 \
      --output-file=/var/run/kuma-prometheus-sd/kuma.file_sd.json
    ```

1.  Configure Prometheus to read from the file you just saved. For example, add the following snippet to `prometheus.yml`:

    ```yaml
    scrape_configs:
      - job_name: "kuma-dataplanes"
        scrape_interval: 15s
        file_sd_configs:
          - files:
              - /var/run/kuma-prometheus-sd/kuma.file_sd.json
    ```

If you have [traffic metrics](/docs/{{ page.version }}/policies/traffic-metrics) enabled for your mesh, check the Targets page in the Prometheus dashboard.
You should see a list of data plane proxies from your mesh. For example:

<center>
<img src="/assets/images/docs/0.4.0/prometheus-targets.png" alt="A screenshot of Targets page on Prometheus UI" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>
