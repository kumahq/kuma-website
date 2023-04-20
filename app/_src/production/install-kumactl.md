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

{% tabs install-kumactl useUrlFragment=false %}
{% tab install-kumactl Script %}

Run the following script to automatically detect the operating system and download Kuma:

<div class="language-sh">
  <pre class="no-line-numbers"><code>curl -L {{site.links.web}}{% if page.edition %}/{{page.edition}}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -</code></pre>
</div>

You can omit the `VERSION` variable to install the latest version.
{% endtab %}
{% tab install-kumactl Direct Link %}

Download the distribution manually. Download a distribution for the **client host** from where you will be executing kumactl:

{% if page.version_data.release == "dev" %}
In preview builds each version are of the format `{{ site.mesh_helm_install_name }}-0.0.0-preview-v<8charactersShortCommitHash>`.

You can find all released versions for all targets from: <a href="{{site.links.download}}/{{ site.mesh_helm_install_name }}-binaries-preview/">The download page.</a>
{% endif %}
{% if page.version_data.release != "dev" %}
The latest version is: **{{ page.version_data.version }}**.

You can find all released versions for all targets from: <a href="{{site.links.download}}/{{ site.mesh_helm_install_name }}-binaries-release/">The download page.</a>
{% endif %}

{% if site.mesh_helm_install_name == "kuma" %}
{% tip %}
On macOS you can use `brew install kumactl`.
{% endtip %}
{% endif %}

and extract the archive with `tar -xvzf {{ site.mesh_helm_install_name }}-{{ page.version_data.version }}.tar.gz`
{% endtab %}
{% endtabs %}

Add the `kumactl` executable to your path:
```
cd kuma-{{ page.version_data.version }}/bin
PATH=$(pwd):$PATH
```

## Next steps
After you've installed `kumactl`, you can deploy {{site.mesh_product_name}} in standalone or multi-zone mode in either Kubernetes or Universal.
