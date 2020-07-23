# OpenShift

To install and run Kuma on OpenShift execute the following steps:

* [1. Download Kuma](#_1-download-kuma)
* [2. Run Kuma](#_2-run-kuma)
* [3. Use Kuma](#_3-use-kuma)

Finally you can follow the [Quickstart](#_4-quickstart) to take it from here and continue your Kuma journey.

### 1. Download Kuma

To run Kuma on OpenShift, you need to download a compatible version of Kuma for the machine from which you will be executing the commands.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Script"

You can run the following script to automatically detect the operating system and download Kuma:

```sh
$ curl -L https://kuma.io/installer.sh | sh -
```

:::
::: tab "Manually"

You can also download the distribution manually. Download a distribution for the **client host** from where you will be executing the commands to access OpenShift:

* [CentOS](https://kong.bintray.com/kuma/kuma-0.6.0-centos-amd64.tar.gz)
* [RedHat](https://kong.bintray.com/kuma/kuma-0.6.0-rhel-amd64.tar.gz)
* [Debian](https://kong.bintray.com/kuma/kuma-0.6.0-debian-amd64.tar.gz)
* [Ubuntu](https://kong.bintray.com/kuma/kuma-0.6.0-ubuntu-amd64.tar.gz)
* [macOS](https://kong.bintray.com/kuma/kuma-0.6.0-darwin-amd64.tar.gz) or `brew install kumactl`

and extract the archive with:

```sh
$ tar xvzf kuma-0.6.0*.tar.gz
```

:::
::::

### 2. Run Kuma

Once downloaded, you will find the contents of Kuma in the `kuma-0.6.0` folder. In this folder, you will find - among other files - the `bin` directory that stores the executables for Kuma, including the CLI client [`kumactl`](/docs/0.6.0/documentation/kumactl/).

::: tip
**Note**: On OpenShift - of all the Kuma binaries in the `bin` folder - we only need `kumactl`.
:::

So we enter the `bin` folder by executing:

```sh
$ cd kuma-0.6.0/bin
```

We suggest adding the `kumactl` executable to your `PATH` so that it's always available in every working directory. Or - alternatively - you can also create link in `/usr/local/bin/` by executing:

```sh
ln -s ./kumactl /usr/local/bin/kumactl
```

And we can then proceed to install Kuma on OpenShift with:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "OpenShift 4.x"
```sh
$ ./kumactl install control-plane --cni-enabled | oc apply -f -
```

Starting from version 4.1 OpenShift utilizes `nftables` instead of `iptables`. So using init container for redirecting traffic to the proxy is no longer works. Instead, we use `kuma-cni` which could be installed with `--cni-enabled` flag.
:::

::: tab "OpenShift 3.11"
By default `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` are disabled on OpenShift 3.11.
In order to make it work add the following `pluginConfig` into `/etc/origin/master/master-config.yaml` on the master node:
```yaml
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
```
After updating `master-config.yaml` restart the cluster and install `control-plane`:
```sh
$ ./kumactl install control-plane | oc apply -f -
```

:::
::::

This example will run Kuma in `standalone` mode for a "flat" deployment, but there are more advanced [deployment modes](/docs/0.6.0/documentation/deployments/).

::: tip
It may take a while for OpenShift to start the Kuma resources, you can check the status by executing:

```sh
$ oc get pod -n kuma-system
```
:::

### 3. Use Kuma

Kuma (`kuma-cp`) will be installed in the newly created `kuma-system` namespace! Now that Kuma has been installed, you can access the control-plane via either the GUI, `oc`, the HTTP API, or the CLI:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "GUI (Read-Only)"

Kuma ships with a **read-only** GUI that you can use to retrieve Kuma resources. By default the GUI listens on the API port and defaults to `:5681/gui`. 

To access Kuma we need to first port-forward the API service with:

```sh
$ kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

And then navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

:::
::: tab "oc (Read & Write)"

You can use Kuma with `oc` to perform **read and write** operations on Kuma resources. For example:

```sh
$ oc get meshes
NAME          AGE
default       1m
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | oc apply -f -
```

:::
::: tab "HTTP API (Read-Only)"

Kuma ships with a **read-only** HTTP API that you can use to retrieve Kuma resources. 

By default the HTTP API listens on port `5681`. To access Kuma we need to first port-forward the API service with:

```sh
$ oc port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

And then you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

:::
::: tab "kumactl (Read-Only)"

You can use the `kumactl` CLI to perform **read-only** operations on Kuma resources. The `kumactl` binary is a client to the Kuma HTTP API, you will need to first port-forward the API service with:

```sh
$ oc port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

and then run `kumactl`, for example:

```sh
$ kumactl get meshes
NAME          mTLS      METRICS      LOGGING   TRACING
default       off       off          off       off
```

You can configure `kumactl` to point to any remote `kuma-cp` instance by running:

```sh
$ kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```
:::
::::

You will notice that Kuma automatically creates a [`Mesh`](../../policies/mesh) entity with name `default`.

::: warning
Kuma explicitly specifies UID for `kuma-dp` to avoid capturing traffic from `kuma-dp` itself. For that reason, special privilege has to be granted to application namespace:
```sh
$ oc adm policy add-scc-to-user anyuid -z APPLICATION_SERVICE_ACCOUNT -n APPLICATION_NAMESPACE
```
:::

### 4. Quickstart

Congratulations! You have successfully installed Kuma on OpenShift 🚀. 

In order to start using Kuma, it's time to check out the [quickstart guide for Kubernetes](/docs/0.6.0/quickstart/kubernetes/) deployments.