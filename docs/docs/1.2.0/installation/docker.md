# Docker

To install and run Kuma on Docker execute the following steps:

* [1. Download Kuma](#_1-download-kuma)
* [2. Run Kuma](#_2-run-kuma)
* [3. Use Kuma](#_3-use-kuma)

::: tip
The official Docker images are used by default in the [Kubernetes](/docs/1.2.0/installation/kubernetes/) and [OpenShift](/docs/1.2.0/installation/openshift/) distributions.
:::

### 1. Download Kuma

Kuma provides the following Docker images for all of its executables:

* **kuma-cp**: at `docker.io/kumahq/kuma-cp:1.2.0`
* **kuma-dp**: at `docker.io/kumahq/kuma-dp:1.2.0`
* **kumactl**: at `docker.io/kumahq/kumactl:1.2.0`
* **kuma-prometheus-sd**: at `docker.io/kumahq/kuma-prometheus-sd:1.2.0`

You can freely `docker pull` these images to start using Kuma, as we will demonstrate in the following steps.

### 2. Run Kuma

Finally we can run Kuma in either **standalone** or **multi-zone** mode:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Standalone"

Standalone mode is perfect when running Kuma in a single cluster across one environment:

```sh
$ docker run \
    -p 5681:5681 \
    docker.io/kumahq/kuma-cp:1.2.0 run
```

To learn more, read about the [deployment modes available](/docs/1.2.0/documentation/deployments/).

:::
::: tab "Multi-Zone"

Multi-zone mode is perfect when running one deployment of Kuma that spans across multiple Kubernetes clusters, clouds and VM environments under the same Kuma deployment. 

This mode also supports hybrid Kubernetes + VMs deployments.

To learn more, read the [multi-zone installation instructions](/docs/1.2.0/documentation/deployments/).

:::
::::

::: tip
**Note**: By default this will run Kuma with a `memory` [backend](../../documentation/backends), but you can use a persistent storage like PostgreSQL by updating the `conf/kuma-cp.conf` file.
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
$ docker run \
    --net="host" \
    docker.io/kumahq/kumactl: kumactl get meshes
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
  docker.io/kumahq/kumactl: kumactl apply -f -
```

**Note**: we are running `kumactl` from the Docker container on the same network as the `host`, but most likely you want to download a compatible version of Kuma for the machine where you will be executing the commands.

You can run the following script to automatically detect the operating system and download Kuma:

```sh
$ curl -L https://kuma.io/installer.sh | sh -
```

or you can download the distribution manually:

* [CentOS](https://download.konghq.com/mesh-alpine/kuma-1.2.0-centos-amd64.tar.gz)
* [RedHat](https://download.konghq.com/mesh-alpine/kuma-1.2.0-rhel-amd64.tar.gz)
* [Debian](https://download.konghq.com/mesh-alpine/kuma-1.2.0-debian-amd64.tar.gz)
* [Ubuntu](https://download.konghq.com/mesh-alpine/kuma-1.2.0-ubuntu-amd64.tar.gz)
* [macOS](https://download.konghq.com/mesh-alpine/kuma-1.2.0-darwin-amd64.tar.gz)

and extract the archive with:

```sh
$ tar xvzf kuma-*.tar.gz
```

You will then find the `kumactl` executable in the `kuma-1.2.0/bin` folder.

:::
::::

You will notice that Kuma automatically creates a [`Mesh`](../../policies/mesh) entity with name `default`.

### 4. Quickstart

Congratulations! You have successfully installed Kuma on Docker 🚀. 

In order to start using Kuma, it's time to check out the [quickstart guide for Universal](/docs/1.2.0/quickstart/universal/) deployments. If you are using Docker you may also be interested in checking out the [Kubernetes quickstart](/docs/1.2.0/quickstart/kubernetes/) as well.
