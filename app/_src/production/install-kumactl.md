---
title: Install kumactl
content_type: how-to
---

This how-to guide explains how to install kumactl in your environment.

{% tabs install-kumactl useUrlFragment=false %}
{% tab Kubernetes %}
1. Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
1. Add the `kumactl` executable to your path:
```
cd kuma-{{ page.latest_version }}/bin
PATH=$(pwd):$PATH
```

1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```sh
    kumactl install control-plane | kubectl apply -f -
    ```
    * Multi-zone mode: HOW?

1. Check the status of the {{site.mesh_product_name}} resources:
```sh
kubectl get pod -n kuma-system
```

{% endtab %}
{% tab Helm %}
1. Download {{site.mesh_product_name}}:
```sh
helm repo add kuma https://kumahq.github.io/charts
helm upgrade -i kuma kuma/kuma
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    * Multi-zone mode: HOW?

{% endtab %}
{% tab OpenShift %}
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

{% endtab %}
{% tab Docker %}
1. Download {{site.mesh_product_name}}:
```sh
docker pull docker.io/kumahq/kuma-cp:{{ page.latest_version }}
docker pull docker.io/kumahq/kuma-dp:{{ page.latest_version }}
docker pull docker.io/kumahq/kumactl:{{ page.latest_version }}
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```sh
    docker run -p 5681:5681 docker.io/kumahq/kuma-cp:{{ page.latest_version }} run
    ```
    * Multi-zone mode: HOW?

{% endtab %}
{% tab Linux %}
1. Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
1. Run {{site.mesh_product_name}}:
    * Standalone mode:
    ```sh
    kuma-{{ page.latest_version }}/bin/kuma-cp run
    ```
    * Multi-zone mode: HOW?
{% endtab %}
{% endtabs %}