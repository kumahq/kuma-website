---
title: Install single zone on Kubernetes with Helm
content_type: how-to
---

This is a simple guide on how to install {{site.mesh_product_name}} on your Kubernetes cluster using [Helm](https://helm.sh/).

1. Add helm repo:
```shell
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}} && helm repo update
```
2. Install {{site.mesh_product_name}} on your cluster:
```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --version {{ page.version_data.version }}
```

## Next steps
* [Complete quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/) to install demo application and secure traffic 
* [Federate](/docs/{{ page.version }}/guides/federate) zone into a multi zone deployment