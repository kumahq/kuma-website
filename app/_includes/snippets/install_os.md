To install and run {{site.mesh_product_name}} execute the following steps:

* [1. Download {{site.mesh_product_name}} ](#download-kuma)
* [2. Run {{site.mesh_product_name}} ](#run-kuma)
* [3. Use {{site.mesh_product_name}} ](#use-kuma)

Finally, you can follow the [Quickstart](#quickstart) to take it from here and continue your {{site.mesh_product_name}} journey.

### Download {{site.mesh_product_name}} 

Run the following script to automatically detect the operating system and download {{site.mesh_product_name}} :

<div class="language-sh">
<pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
</div>


or you can <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-{{ page.os }}-{{ page.arch }}.tar.gz">download</a> the distribution manually: 

* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-centos-amd64.tar.gz">Amazon Linux</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-rhel-amd64.tar.gz">Red Hat</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-centos-amd64.tar.gz">CentOS</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-debian-amd64.tar.gz">Debian</a>
* <a href="https://download.konghq.com/mesh-alpine/kuma-{{ page.latest_version }}-ubuntu-amd64.tar.gz">Ubuntu</a>

Then extract the archive with: `tar xvzf kuma-{{ page.latest_version }}`.

{% tip %}
If you wish to use Kuma on Amazon EKS please follow the [Kubernetes instructions](/docs/{{ page.version }}/installation/kubernetes/) instead.
{% endtip %}


### Run {{site.mesh_product_name}} 
Once downloaded, you will find the contents of {{site.mesh_product_name}} in the `kuma-{{ page.latest_version }}` folder. In this folder, you will find - among other files - the `bin` directory that stores all the executables for {{site.mesh_product_name}} .

You can start the control-plane with: `kuma-{{ page.latest_version }}/bin/kuma-cp run`

This example will run {{site.mesh_product_name}} in `standalone` mode for a "flat" deployment, but there are more advanced [deployment modes](/docs/{{ page.version }}/introduction/deployments) like "multi-zone".

We suggest adding the `kumactl` executable to your `PATH` so that it's always available in every working directory. Or - alternatively - you can also create link in `/usr/local/bin/` by executing:

```sh
ln -s kuma-{{ page.latest_version }}/bin/kumactl /usr/local/bin/kumactl
```

{% tip %}
**Note**: By default this will run {{site.mesh_product_name}} with a `memory` [store](/docs/{{ page.version }}/documentation/configuration), but for production you have to use a persistent storage like PostgreSQL by updating the `conf/kuma-cp.conf` file.
{% endtip %}

### Use {{site.mesh_product_name}} 

{{site.mesh_product_name}} (`kuma-cp`) is now running! Now that {{site.mesh_product_name}} has been installed you can access the control-plane via either the GUI, the HTTP API, or the CLI:

{% tabs use-kuma useUrlFragment=false %}
{% tab use-kuma GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

{% endtab %}
{% tab use-kuma HTTP API (Read & Write) %}

{{site.mesh_product_name}} ships with a **read and write** HTTP API that you can use to perform operations on {{site.mesh_product_name}} resources. By default the HTTP API listens on port `5681`.

To access Kuma you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

{% endtab %}
{% tab use-kuma kumactl (Read & Write) %}

You can use the `kumactl` CLI to perform **read and write** operations on Kuma resources. The `kumactl` binary is a client to the Kuma HTTP API. For example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | kumactl apply -f -
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```
{% endtab %}
{% endtabs %}

You will notice that Kuma automatically creates a [`Mesh`](/docs/{{ page.version }}/policies/mesh) entity with name `default`.

### Quickstart

Congratulations! You have successfully installed Kuma 🚀.

In order to start using Kuma, it's time to check out the [quickstart guide for Universal](/docs/{{ page.version }}/quickstart/universal) deployments.