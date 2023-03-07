---
title: Install kumactl
content_type: how-to
---

This how-to guide explains how to install `kumactl` in your environment.

`kumactl` is a CLI tool that you can use to access {{site.mesh_product_name}}. It can do the following:

* Perform read-only operations on {{site.mesh_product_name}} resources on Kubernetes. 
* Read and create resources in {{site.mesh_product_name}} in Universal mode.

The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. 

{% tabs install-kumactl useUrlFragment=false %}
{% tab install-kumactl Kubernetes %}
1. Download {{site.mesh_product_name}}:
{% tabs install_kumactl useUrlFragment=false %}
{% tab install_kumactl Script %}

Run the following script to automatically detect the operating system and download Kuma:

<div class="language-sh">
  <pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
</div>

You can omit the `VERSION` variable to install the latest version.
{% endtab %}
{% tab install_kumactl Direct Link %}

Download the distribution manually. Download a distribution for the **client host** from where you will be executing the commands to access Kubernetes:

* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-centos-amd64.tar.gz">CentOS</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-rhel-amd64.tar.gz">RedHat</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-debian-amd64.tar.gz">Debian</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-ubuntu-amd64.tar.gz">Ubuntu</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-darwin-amd64.tar.gz">macOS</a> or run `brew install kumactl`

and extract the archive with `tar xvzf kuma-{{ page.latest_version }}.tar.gz`
{% endtab %}
{% endtabs %}

1. Add the `kumactl` executable to your path:
```
cd kuma-{{ page.latest_version }}/bin
PATH=$(pwd):$PATH
```

{% endtab %}
{% tab install-kumactl Helm %}
Add the {{site.mesh_product_name}} charts repository:
```sh
helm repo add kuma https://kumahq.github.io/charts
helm upgrade -i kuma kuma/kuma
```

{% endtab %}
{% tab install-kumactl OpenShift %}
Download {{site.mesh_product_name}}:
```sh
curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -
```
{% endtab %}
{% tab install-kumactl Docker %}
Download {{site.mesh_product_name}}:
```sh
docker pull docker.io/kumahq/kuma-cp:{{ page.latest_version }}
docker pull docker.io/kumahq/kuma-dp:{{ page.latest_version }}
docker pull docker.io/kumahq/kumactl:{{ page.latest_version }}
```
{% endtab %}
{% tab install-kumactl Linux %}
Download {{site.mesh_product_name}} by doing one of the following:
* Run the following script to automatically detect the operating system and download {{site.mesh_product_name}}:
<div class="language-sh">
<pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
</div>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-{{ page.os }}-{{ page.arch }}.tar.gz">Download</a> the distribution manually, and then extract the archive with: `tar xvzf kuma-{{ page.latest_version }}`.

{% tip %}
Make sure you have tar and gzip installed.
{% endtip %}
{% endtab %}
{% endtabs %}

## Next steps
After you've installed `kumactl`, you can deploy {{site.mesh_product_name}} in standalone or multi-zone mode.