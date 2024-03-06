---
title: Kubernetes
---

To install and run {{site.mesh_product_name}} execute the following steps:

* Download {{site.mesh_product_name}}
* Run {{site.mesh_product_name}}
* Use {{site.mesh_product_name}}

Finally, you can follow the [Quickstart](#quickstart) to take it from here and continue your {{site.mesh_product_name}} journey.

{% tip %}
{{site.mesh_product_name}} also provides [Helm charts](/docs/{{ page.version }}/installation/helm) that you can use instead of this distribution.
{% endtip %}

## Download kumactl

{% include snippets/install_kumactl.md installer_version="preview" %}

## Run {{site.mesh_product_name}}

Finally, you can install and run {{site.mesh_product_name}}:

```sh
kumactl install control-plane | kubectl apply -f -
```

This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".

{% tip %}
It may take a while for Kubernetes to start the {{site.mesh_product_name}} resources, you can check the status by executing:

```sh
kubectl get pod -n {{site.mesh_namespace}}
```
{% endtip %}

## Use {{site.mesh_product_name}}

{% include snippets/use_kuma_k8s.md %}

## Quickstart

Congratulations! You have successfully installed {{site.mesh_product_name}} on Kubernetes 🚀.

In order to start using {{site.mesh_product_name}}, it's time to check out the {% if_version gte:2.6.x %}[Kubernetes quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/){% endif_version %}{% if_version lte:2.5.x %}[Kubernetes quickstart](/docs/{{ page.version }}/quickstart/kubernetes/){% endif_version %}.
