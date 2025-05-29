---
title: Install kumactl
content_type: how-to
---

This how-to guide explains how to install `kumactl` in your environment.

`kumactl` is a CLI tool that you can use to access {{site.mesh_product_name}}. It can do the following:

* Perform read-only operations on {{site.mesh_product_name}} resources on Kubernetes. 
* Read and create resources in {{site.mesh_product_name}} in Universal mode.

The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. 

Download {{site.mesh_product_name}}:

{% tip %}
Make sure you have tar and gzip installed.
{% endtip %}

{% tabs %}
{% tab Script %}

Run the following script to automatically detect the operating system and download Kuma:

<div class="language-sh">
  <pre class="no-line-numbers"><code>curl -L {{site.links.web}}{% if page.edition != "kuma" %}/{{page.edition}}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -</code></pre>
</div>

You can omit the `VERSION` variable to install the latest version.
{% endtab %}
{% tab install-kumactl Direct Link %}

Download the distribution manually. Download a distribution for the **client host** from where you will be executing kumactl:

{% if page.release.label %}
In preview builds each version are of the format `{{ site.mesh_helm_install_name }}-0.0.0-preview-v<8charactersShortCommitHash>`.

{% endif %}
{% unless page.release.label %}
The latest version is: **{{ page.version_data.version }}**.

{% endunless %}

You can find all released versions for all targets on <a href="{{site.links.download}}/{{ site.mesh_helm_install_name }}-binaries-release/">the download page</a> and extract the archive with\
`tar -xvzf {{ site.mesh_helm_install_name }}-{{ page.version_data.version }}.tar.gz`.

{% if site.mesh_helm_install_name == "kuma" %}
{% tip %}
On macOS you can use `brew install kumactl`.
{% endtip %}
{% endif %}

{% endtab %}
{% endtabs %}

Add the `kumactl` executable to your path:
```
cd {{site.mesh_install_archive_name }}-{{ page.version_data.version }}/bin
export PATH=$(pwd):$PATH
```

## Next steps
{% if_version gte:2.6.x %}
{% if_version lte:2.10.x %}
* [Complete quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application
{% endif_version %}
{% endif_version %}
{% if_version gte:2.11.x %}
* [Complete quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application
{% endif_version %}
{% if_version lte:2.5.x %}
After you've installed `kumactl`, you can deploy {{site.mesh_product_name}} in standalone or multi-zone mode in either Kubernetes or Universal.
{% endif_version %}
