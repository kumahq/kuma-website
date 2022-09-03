# Docker

To install and run Kuma on Docker execute the following steps:

* [1. Download Kuma](#_1-download-kuma)
* [2. Run Kuma](#_2-run-kuma)
* [3. Use Kuma](#_3-use-kuma)

::: tip
The official Docker images are used by default in the [Kubernetes](../installation/kubernetes/) and [OpenShift](../installation/openshift/) distributions.
:::

### 1. Download Kuma

Kuma provides the following Docker images for all of its executables:

* **kuma-cp**: at `docker.io/kumahq/kuma-cp:{{ $page.latestVersion }}`
* **kuma-dp**: at `docker.io/kumahq/kuma-dp:{{ $page.latestVersion }}`
* **kumactl**: at `docker.io/kumahq/kumactl:{{ $page.latestVersion }}`
* **kuma-prometheus-sd**: at `docker.io/kumahq/kuma-prometheus-sd:{{ $page.latestVersion }}`

You can freely `docker pull` these images to start using Kuma, as we will demonstrate in the following steps.

### 2. Run Kuma

We can run Kuma:

`docker run -p 5681:5681 docker.io/kumahq/kuma-cp:{{ $page.latestVersion }} run`

This example will run Kuma in `standalone` mode for a "flat" deployment, but there are more advanced [deployment modes](../introduction/deployments.md) like "multi-zone".

::: tip
**Note**: By default this will run Kuma with a `memory` [store](../../documentation/configuration#store), but you can use a persistent storage like PostgreSQL by updating the `conf/kuma-cp.conf` file.
:::

### 3. Use Kuma

Kuma (`kuma-cp`) is now running! Now that Kuma has been installed you can access the control-plane via either the GUI, the HTTP API, or the CLI:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "GUI (Read-Only)"

Kuma ships with a **read-only** GUI that you can use to retrieve Kuma resources. By default the GUI listens on the API port and defaults to `:5681/gui`. 

To access Kuma you can navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

:::
::: tab "HTTP API (Read & Write)"

Kuma ships with a **read and write** HTTP API that you can use to perform operations on Kuma resources. By default the HTTP API listens on port `5681`.

To access Kuma you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

:::
::: tab "kumactl (Read & Write)"

You can use the `kumactl` CLI to perform **read and write** operations on Kuma resources. The `kumactl` binary is a client to the Kuma HTTP API. For example:

```sh
$ docker run --net="host" kumahq/kumactl:<version> kumactl get meshes
NAME          mTLS      METRICS      LOGGING   TRACING
default       off       off          off       off
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | docker run -i --net="host" \
  docker.io/kumahq/kumactl:<version> kumactl apply -f -
```

**Note**: we are running `kumactl` from the Docker container on the same network as the `host`, but most likely you want to download a compatible version of Kuma for the machine where you will be executing the commands.

You can run the following script to automatically detect the operating system and download Kuma:

<div class="language-sh">
<pre><code>curl -L https://kuma.io/installer.sh | VERSION={{ $page.latestVersion }} sh -</code></pre>
</div>

or you can download the distribution manually:

* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-centos-amd64.tar.gz'">CentOS</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-rhel-amd64.tar.gz'">RedHat</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-debian-amd64.tar.gz'">Debian</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-ubuntu-amd64.tar.gz'">Ubuntu</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-darwin-amd64.tar.gz'">macOS</a> or run `brew install kumactl`

and extract the archive with:

```sh
tar xvzf kuma-*.tar.gz
```

You will then find the `kumactl` executable in the `kuma-{{ $page.latestVersion }}/bin` folder.

:::
::::

You will notice that Kuma automatically creates a [`Mesh`](../../policies/mesh) entity with name `default`.

### 4. Quickstart

Congratulations! You have successfully installed Kuma on Docker 🚀. 

In order to start using Kuma, it's time to check out the [quickstart guide for Universal](../quickstart/universal/) deployments. If you are using Docker you may also be interested in checking out the [Kubernetes quickstart](../quickstart/kubernetes/) as well.
