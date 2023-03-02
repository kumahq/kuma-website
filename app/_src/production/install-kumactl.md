---
title: Install kumactl
content_type: how-to
---

This how-to guide explains how to install kumactl in your environment.

{% navtabs %}
{% navtab Kubernetes %}
1. Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    * Multi-zone mode: HOW?

{% endnavtab %}
{% navtab Helm %}
1. Download {{site.mesh_product_name}}:
```sh
helm repo add kuma https://kumahq.github.io/charts
helm upgrade -i kuma kuma/kuma
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    * Multi-zone mode: HOW?

{% endnavtab %}
{% navtab OpenShift %}
1. Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```sh
    ./kumactl install control-plane --cni-enabled | oc apply -f -
    ```
    * Multi-zone mode: HOW?

{% endnavtab %}
{% navtab Docker %}
1. Download {{site.mesh_product_name}}:
```sh
docker pull docker.io/kumahq/kuma-cp:{{ page.latest_version }}
docker pull docker.io/kumahq/kuma-dp:{{ page.latest_version }}
docker pull docker.io/kumahq/kumactl:{{ page.latest_version }}
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```
    docker run -p 5681:5681 docker.io/kumahq/kuma-cp:{{ page.latest_version }} run
    ```
    * Multi-zone mode: HOW?

{% endnavtab %}
{% navtab Linux %}
1. Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```
    kuma-{{ page.latest_version }}/bin/kuma-cp run
    ```
    * Multi-zone mode: HOW?
{% endnavtab %}
{% endnavtabs %}