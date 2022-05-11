# Kubernetes

To install and run Kuma execute the following steps:

* [1. Download Kuma](#_1-download-kuma)
* [2. Run Kuma](#_2-run-kuma)
* [3. Use Kuma](#_3-use-kuma)

Finally, you can follow the [Quickstart](#_4-quickstart) to take it from here and continue your Kuma journey.

::: tip
Kuma also provides [Helm charts](../installation/helm/) that we can use instead of this distribution.
:::

### 1. Download Kumactl

!!!include(install_kumactl.md)!!!

### 2. Run Kuma

Finally, we can install and run Kuma:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "x86"
```sh
kumactl install control-plane | kubectl apply -f -
```
:::
::: tab "ARM"
```sh
kumactl install control-plane --control-plane-node-selector kubernetes.io/arch=arm64 | kubectl apply -f-
```
:::
::::

This example will run Kuma in `standalone` mode for a "flat" deployment, but there are more advanced [deployment modes](../introduction/deployments.md) like "multi-zone".

::: tip
It may take a while for Kubernetes to start the Kuma resources, you can check the status by executing:

```sh
kubectl get pod -n kuma-system
```
:::

### 3. Use Kuma

!!!include(use_kuma_k8s.md)!!!

### 4. Quickstart

Congratulations! You have successfully installed Kuma on Kubernetes 🚀.

In order to start using Kuma, it's time to check out the [quickstart guide for Kubernetes](../quickstart/kubernetes/) deployments.
