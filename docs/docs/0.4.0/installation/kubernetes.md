# Kubernetes

To install and run Kuma on Kubernetes execute the following steps:

### 1. Download Kuma

To run Kuma on Kubernetes, you need to download a compatible version of Kuma for the machine where you will be executing the commands.

You can run the following script to automatically detect the operating system and download Kuma:

```sh
$ curl -L https://kuma.io/installer.sh | sh -
```

or you can download the distribution manually:

* [CentOS](https://kong.bintray.com/kuma/kuma-0.4.0-centos-amd64.tar.gz)
* [RedHat](https://kong.bintray.com/kuma/kuma-0.4.0-rhel-amd64.tar.gz)
* [Debian](https://kong.bintray.com/kuma/kuma-0.4.0-debian-amd64.tar.gz)
* [Ubuntu](https://kong.bintray.com/kuma/kuma-0.4.0-ubuntu-amd64.tar.gz)
* [macOS](https://kong.bintray.com/kuma/kuma-0.4.0-darwin-amd64.tar.gz)

and extract the archive with:

```sh
$ tar xvzf [FILE]
```

### 2. Run Kuma

Once downloaded, you will find the contents of Kuma in the `kuma-0.4.0` folder. In this folder, you will find - among other files - the `bin` directory that stores the executables for Kuma, including the CLI client [`kumactl`](/docs/0.4.0/documentation/kumactl/).

::: tip
**Note**: On Kubernetes - of all the Kuma binaries in the `bin` folder - we only need `kumactl`.
:::

So we enter the `bin` folder by executing:

```sh
$ cd kuma-0.4.0/bin
```

And we can then proceed to install Kuma on Kubernetes with:

```sh
$ ./kumactl install control-plane | kubectl apply -f -
```

::: tip
We suggest adding the `kumactl` executable to your `PATH` so that it's always available in every working directory. Or - alternatively - you can also create link in `/usr/local/bin/` by executing:

```sh
ln -s ./kumactl /usr/local/bin/kumactl
```
:::

::: tip
It may take a while for Kubernetes to start the Kuma resources, you can check the status by executing:

```sh
$ kubectl get pod -n kuma-system
```
:::

### 3. Use Kuma

Kuma (`kuma-cp`) will be installed in the newly created `kuma-system` namespace! Now that Kuma has been installed, you can access the control-plane via either using the GUI, the read-only HTTP API, or the CLI:

:::: tabs :options="{ useUrlFragment: true }"
::: tab "GUI"

Kuma ships with a **read-only** GUI that you can use to retrieve the Kuma state. By default the GUI listens on port `5683`. 

To access Kuma we need to first port-forward the GUI service with:

```sh
$ kubectl port-forward svc/kuma-control-plane -n kuma-system 5683:5683
```

And then you can navigate to [`127.0.0.1:5683`](http://127.0.0.1:5683) to see the GUI.

:::
::: tab "HTTP API"

Kuma ships with a **read-only** HTTP API that you can use to retrieve the Kuma state. 

By default the HTTP API listens on port `5681`. To access Kuma we need to first port-forward the API service with:

```sh
$ kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

And then you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

:::
::: tab "CLI"

Finally, you can use Kuma with `kubectl` to read and write the Kuma state, or alternatively use the `kumactl` CLI to perform read-only operations as well.

You can use `kubectl` to retrieve Kuma entities (for example `Meshes`) with:

```sh
$ kubectl get meshes
NAME          AGE
default       5h20m
```

or you can use `kumactl` by first exposing the Kuma HTTP API with:

```sh
$ kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

and then running:

```sh
$ kumactl get meshes
NAME          mTLS      METRICS      LOGGING   TRACING
default       off       off          off       off
```

:::
::::

#### GUI



#### HTTP API



#### CLI

Finally, you can use Kuma with `kubectl` to read and write the Kuma state, or alternatively use the `kumactl` CLI to perform read-only operations as well.

You can use `kubectl` to retrieve Kuma entities (for example `Meshes`) with:

```sh
$ kubectl get meshes
NAME          AGE
default       5h20m
```

or you can use `kumactl` by first exposing the Kuma HTTP API with:

```sh
$ kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

and then running:

```sh
$ kumactl get meshes
NAME          mTLS      METRICS      LOGGING   TRACING
default       off       off          off       off
```

### 4. Quickstart

Congratulations! You have successfully installed Kuma on Kubernetes. In order to start using Kuma, it's time to check out the Kubernetes quickstart guide.
