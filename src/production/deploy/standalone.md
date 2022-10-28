---
title: Deploy Kuma in standalone mode
---


In order to deploy {{ site.mesh_product_name }} in a standalone deployment, the `kuma-cp` control plane must be started in `standalone` mode:

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}
This is the standard installation method as described in the [installation page](/install).
```sh
kumactl install control-plane | kubectl apply -f -
```

**With zone egress**:

It's possible to run [`ZoneEgress`](/docs/{{ page.version }}/explore/zoneegress) for standalone deployment. In order to deploy {{ site.mesh_product_name }} with `ZoneEgress` run the install command with an additional parameter.
```sh
kumactl install control-plane --egress-enabled | kubectl apply -f -
```
{% endtab %}
{% tab usage Universal %}
This is the standard installation method as described in the [installation page](/install).
```sh
kuma-cp run
```

**With zone egress**:

`ZoneEgress` works for Universal deployment as well. In order to deploy `ZoneEgress` for Universal deployment [follow the instruction](/docs/{{ page.version }}/explore/zoneegress#zone-egress).

{% endtab %}
{% endtabs %}

Once {{ site.mesh_product_name }} is up and running, data plane proxies can now [connect](/docs/{{ page.version }}/explore/dpp) directly to it.

{% tip %}
When the mode is not specified, {{ site.mesh_product_name }} will always start in `standalone` mode by default.
{% endtip %}

## Failure modes

#### Control plane offline

* New data planes proxis won't be able to join the mesh.
* Data-plane proxy configuration will not be updated.
* Communication between data planes proxies will still work.

{% tip %}
You can think of this failure case as *"Freezing"* the zone mesh configuration.
Communication will still work but changes will not be reflected on existing data plane proxies.
{% endtip %}
