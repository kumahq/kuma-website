---
title: Install
content_type: how-to
---

{% capture install-tip %}
This guide is mostly useful for Universal setup, as for Kubernetes we recommend using `kubectl` for managing [resources](/docs/{{ page.release }}/introduction/concepts#resource).
{% if_version lte:2.10.x %}
More in [Kubernetes quickstart guide](/docs/{{ page.release }}/quickstart/kubernetes-demo/).
{% endif_version %}
{% if_version gte:2.11.x %}
More in [Kubernetes quickstart guide](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/).
{% endif_version %}
{% endcapture %}

{% tip %}
{{ install-tip }}
{% endtip %}

This is a simple guide on how to install {{site.mesh_product_name}} on your machine.

1. Go to the [{{site.mesh_product_name}} packages](https://cloudsmith.io/~kong/repos/{{site.mesh_product_name_path}}-binaries-release/packages/?q=version%3A{{ page.version_data.version }}) 
page to download and extract the installation archive for your OS, or download and extract the latest release automatically (Linux or macOS):
```shell
curl -L {{site.links.web}}{% if page.edition != "kuma" %}/{{page.edition}}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -
```
2. To finish installation, add {{site.mesh_product_name}} binaries to path:
```shell
export PATH=$(pwd)/{{site.mesh_product_name_path}}-{{ page.version_data.version }}/bin:$PATH
```
This directory contains binaries for `kuma-dp`, `kuma-cp`, `kumactl`, `envoy` and `coredns`

{% if page.edition == "kuma" %}
{% tip %}
If you only need `kumactl` on macOS you can install it via `brew install kumactl`.
{% endtip %}
{% endif %}

## Next steps
* [Complete quickstart](/docs/{{ page.release }}/quickstart/universal-demo/) to set up a zone control plane with demo application
