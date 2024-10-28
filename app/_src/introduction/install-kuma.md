---
title: Install Kuma
content_type: how-to
---

{% tip %}
This guide is mostly useful for Universal setup, as for Kubernetes we recommend using `kubectl` for managing [resources](/docs/{{ page.version }}/introduction/concepts#resource).
More in [Kubernetes quickstart guide](/docs/{{ page.version }}/quickstart/kubernetes-demo/).
{% endtip %}

This is a simple guide on how to install {{site.mesh_product_name}} on your machine.

1. Go to the [{{site.mesh_product_name}} packages](https://cloudsmith.io/~kong/repos/{{site.mesh_product_name_path}}-binaries-release/packages/?q=version%3A{{ page.version_data.version }}) 
page to download and extract the installation archive for your OS, or download and extract the latest release automatically (Linux or macOS):
```shell
curl -L {{site.links.web}}{% if page.edition %}/{{page.edition}}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -
```
2. To finish installation, add {{site.mesh_product_name}} binaries to path:
```shell
export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{ page.version_data.version }}/bin
```
This directory contains binaries for `kuma-dp`, `kuma-cp`, `kumactl`, `envoy` and `coredns`

{% tip %}
If you only need `kumactl` on macOS you can install it via `brew install kumactl`.
{% endtip %}


## Next steps
{% if_version gte:2.6.x %}
* [Complete quickstart](/docs/{{ page.version }}/quickstart/universal-demo/) to set up a zone control plane with demo application
{% endif_version %}
{% if_version lte:2.5.x %}
After you've installed `kumactl`, you can deploy {{site.mesh_product_name}} in standalone or multi-zone mode in either Kubernetes or Universal.
{% endif_version %}
