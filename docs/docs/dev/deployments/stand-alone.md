# Standalone deployment

## About

This is the simplest deployment mode for Kuma, and the default one.

* **Control plane**: There is one deployment of the control plane that can be scaled horizontally.
* **Data plane proxies**: The data plane proxies connect to the control plane regardless of where they are deployed.
* **Service Connectivity**: Every data plane proxy must be able to connect to every other data plane proxy regardless of where they are being deployed.

This mode implies that we can deploy Kuma and its data plane proxies in a standalone networking topology mode so that the service connectivity from every data plane proxy can be established directly to every other data plane proxy.

<center>
<img src="/images/docs/0.6.0/flat-diagram.png" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Standalone mode is usually a great choice within the context of one zone (ie: within one Kubernetes cluster or one AWS VPC).

## Limitations

* All data plane proxies need to be able to communicate with every other dataplane proxy.
* A standalone deployment cannot mix Universal and Kubernetes workloads.
* A deployment can connect to only one Kubernetes cluster at once.

If these limitations are problematic you should look at [Multi-zone deployments](../multi-zone).

## Usage

In order to deploy Kuma in a standalone deployment, the `kuma-cp` control plane must be started in `standalone` mode:

:::::: tabs :options="{ useUrlFragment: false }"
::::: tab "Kubernetes"
This is the standard installation method as described in the [installation page](/install).

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

**With zone egress**:

It's possible to run [`ZoneEgress`](../explore/zoneegress.md) for standalone deployment. In order to deploy Kuma with `ZoneEgress` run the install command with an additional parameter.

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

:::::
::::: tab "Universal"
This is the standard installation method as described in the [installation page](/install).
```sh
kuma-cp run
```

**With zone egress**:

`ZoneEgress` works for Universal deployment as well. In order to deploy `ZoneEgress` for Universal deployment [follow the instruction](../explore/zoneegress.md#zone-egress).

:::::
::::::

Once Kuma is up and running, data plane proxies can now [connect](../explore/dpp.md) directly to it.

:::tip
When the mode is not specified, Kuma will always start in `standalone` mode by default.
:::

## Failure modes

#### Control plane offline

* New data planes proxis won't be able to join the mesh.
* Data-plane proxy configuration will not be updated.
* Communication between data planes proxies will still work.

::: tip
You can think of this failure case as *"Freezing"* the zone mesh configuration.
Communication will still work but changes will not be reflected on existing data plane proxies.
:::
