# Helm

To install and run Kuma on Kubernetes with Helm charts execute the following steps:

* [1. Add the Kuma charts repository](#_1-add-the-kuma-charts-repository)
* [2. Run Kuma](#_2-run-kuma)
* [3. Use Kuma](#_3-use-kuma)

Finally you can follow the [Quickstart](#_4-quickstart) to take it from here and continue your Kuma journey.

::: tip
Kuma also provides an alternative [Kubernetes distribution](../installation/kubernetes/) that we can use instead of Helm charts.
:::

### 1. Add the Kuma charts repository

To start using Kuma with Helm charts, we first need to add the [Kuma charts repository](https://kumahq.github.io/charts) to our local Helm deployment: 

```sh
helm repo add kuma https://kumahq.github.io/charts
```

Once the repo is added, all following updates can be fetched with `helm repo update`.

### Run Kuma

At this point we can install and run Kuma using the following commands. We could use any Kubernetes namespace to install Kuma, by default we suggest using `kuma-system`:

```sh
helm install --create-namespace --namespace kuma-system kuma kuma/kuma
```

This example will run Kuma in `standalone` mode for a "flat" deployment, but there are more advanced [deployment modes](../introduction/deployments.md) like "multi-zone".

### 3. Use Kuma

!!!include(use_kuma_k8s.md)!!!

### 4. Quickstart

Congratulations! You have successfully installed Kuma on Kubernetes 🚀. 

In order to start using Kuma, it's time to check out the [quickstart guide for Kubernetes](../quickstart/kubernetes/) deployments.
