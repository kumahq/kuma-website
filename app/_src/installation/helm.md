---
title: Helm
---

To install and run {{site.mesh_product_name}} on Kubernetes with Helm charts execute the following steps:

* Add the {{site.mesh_product_name}} charts repository
* Run {{site.mesh_product_name}}
* Use {{site.mesh_product_name}}

Finally you can follow the [Quickstart](#quickstart) to take it from here and continue your {{site.mesh_product_name}} journey.

{% tip %}
{{site.mesh_product_name}} also provides an alternative [Kubernetes distribution](/docs/{{ page.version }}/installation/kubernetes/) that you can use instead of Helm charts.
{% endtip %}

## Prerequisites

Helm version 3.8.0 is required to use the {{site.mesh_product_name}} Helm charts. If you are using an older version of Helm, upgrade to version 3.8.0 first.

## Add the {{site.mesh_product_name}} charts repository

To start using {{site.mesh_product_name}} with Helm charts, you first need to add the [{{site.mesh_product_name}} charts repository](https://kumahq.github.io/charts) to your local Helm deployment: 

```sh
helm repo add kuma https://kumahq.github.io/charts
```

Once the repo is added, all following updates can be fetched with `helm repo update`.

## Run {{site.mesh_product_name}}

At this point, you can install and run {{site.mesh_product_name}} using the following commands. You could use any Kubernetes namespace to install {{site.mesh_product_name}}, by default we recommend using `{{site.mesh_namespace}}`:

```sh
helm install --create-namespace --namespace {{site.mesh_namespace}} kuma kuma/kuma
```

This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".

## Use {{site.mesh_product_name}}

{% include snippets/use_kuma_k8s.md %}

## Quickstart

Congratulations! You have successfully installed {{site.mesh_product_name}} on Kubernetes 🚀. 

In order to start using {{site.mesh_product_name}}, it's time to check out the {% if_version gte:2.6.x %}[quickstart guide](/docs/{{ page.version }}/quickstart/kubernetes-demo/){% endif_version %}{% if_version lte:2.5.x %}[quickstart guide](/docs/{{ page.version }}/quickstart/kubernetes/){% endif_version %} deployments.

## Argo CD

{{site.mesh_product_name}} requires a certificate to verify a connection between the control plane and a data plane proxy.
{{site.mesh_product_name}} Helm chart autogenerate self-signed certificate if the certificate isn't explicitly set.
Argo CD uses `helm template` to compare and apply Kubernetes YAMLs.
Helm template doesn't work with chart logic to verify if the certificate is present.
This results in replacing the certificate on each Argo redeployment.
The solution to this problem is to explicitly set the certificates.
See {% if_version lte:2.1.x %}["Data plane proxy to control plane communication"](/docs/{{ page.version }}/security/certificates#data-plane-proxy-to-control-plane-communication){% endif_version %}{% if_version gte:2.2.x %}["Data plane proxy to control plane communication"](/docs/{{ page.version }}/production/secure-deployment/certificates/){% endif_version %} to learn how to preconfigure {{site.mesh_product_name}} with certificates.
