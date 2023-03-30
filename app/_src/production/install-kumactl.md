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
  <pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
</div>

You can omit the `VERSION` variable to install the latest version.
{% endtab %}
{% tab install-kumactl Direct Link %}

Download the distribution manually. Download a distribution for the **client host** from where you will be executing kumactl:

{% if page.version == "dev" %}
In preview builds each version are of the format `{{ site.mesh_helm_install_name }}-0.0.0-preview-v<8charactersShortCommitHash>`.

You can find all released versions for all targets from: <a href="https://download.konghq.com/{{ site.mesh_helm_install_name }}-binaries-preview/">The download page.</a>
{% endif %}
{% if page.version != "dev" %}
The latest version is: **{{ page.latest_version }}**.

You can find all released versions for all targets from: <a href="https://download.konghq.com/{{ site.mesh_helm_install_name }}-binaries-release/">The download page.</a>
{% endif %}

{% tip %}
On macOS you can use `brew install kumactl`.
{% endtip %}

and extract the archive with `tar -xvzf {{ site.mesh_helm_install_name }}-{{ page.latest_version }}.tar.gz`
{% endtab %}
{% endtabs %}

Add the `kumactl` executable to your path:
```
cd kuma-{{ page.latest_version }}/bin
PATH=$(pwd):$PATH
```

## Next steps
After you've installed `kumactl`, you can deploy {{site.mesh_product_name}} in standalone or multi-zone mode in either Kubernetes or Universal.
