# Deployments

The deployment modes that Kuma provides are quite unique in the Service Mesh landscape and have been developed thanks to the guidance of our enterprise users, especially when it comes to the distributed one.

There are two deployment models that can be adopted with Kuma in order to address any Service Mesh use-case, from the simple one running in one cluster to the more complex one where multiple Kubernetes or VM clusters are involved, or even hybrid universal ones where Kuma runs simultaneously on Kubernetes and VMs.

The two deployments modes are:

* [**Flat**](#flat-mode): Kuma's default deployment model with one control plane (that can be scaled horizontally) and many data planes connecting directly to it.
* [**Distributed**](#distributed-mode): Kuma's advanced deployment model to support multiple Kubernetes or VM-based clusters, or hybrid Service Meshes running on both Kubernetes and VMs combined.

:::tip
**Automatic Connectivity**: Running a Service Mesh should be easy and connectivity should be abstracted away, so that when a service wants to consume another service all it needs is the name of the destination service. Kuma achieves this out of the box in both deployment modes with a built-in service discovery and - in the case of the distributed mode - with an Ingress resource and Remote CPs.
:::

## Flat Mode

This is the simplest deployment mode for Kuma, and the default one.

* **Control plane**: There is one deployment of the control plane that can be scaled horizontally.
* **Data planes**: The data planes connect to the control plane regardless of where they are being deployed.
* **Service Connectivity**: Every data plane proxy must be able to connect to every other data plane proxy regardless of where they are being deployed.

This mode implies that we can deploy Kuma and its data plane proxies in a flat networking topology mode so that the service connectivity from every data plane proxy can be estabilished directly to every other data plane proxy.

TODO: IMAGE

Although flat mode can support complex multi-cluster or hybrid deployments (Kubernetes + VMs) as long as the networking requirements are satisfied, typically in most use cases our connectivity cannot be flattened out across multiple clusters. Therefore flat mode is usually a great choice within the context of one cluster (ie: within one Kubernetes cluster or one AWS VPC).

For those situations where the flat deployment mode doesn't satistfy our architecture, Kuma provides a [distributed mode](#distributed-mode) which is more powerful and provides a greater degree of flexibility in more complex environments.

### Usage

In order to deploy Kuma in a flat deployment, the `kuma-cp` control plane must be started in `standalone` mode:

```sh
$ kuma-cp run --mode=standalone
```

Once Kuma is up and running, data plane proxies can now [connect](/docs/0.5.1/documentation/dps-and-data-model) directly to it. 

:::tip
When the mode is not specified, Kuma will always start in `standalone` mode by default.
:::

## Distributed Mode

This is a more advanced deployment mode for Kuma that allow us to support service meshes that are running on many clusters, including hybrid deployments on both Kubernetes and VMs.

* **Control plane**: There is one `global` control plane, and many `remote` control planes. A global control plane only accepts connections from remote control planes.
* **Data planes**: The data planes connect to the closest `remote` control plane in the same zone. Additionally, we need to start an `ingress` data plane on every zone.
* **Service Connectivity**: Automatically resolved via the built-in DNS resolver that ships with Kuma. When a service wants to consume another service, it will resolve the DNS address of the desired service with Kuma, and Kuma will either respond with the address of a data plane proxy that is local to the source service (aka, in the same zone), or with the address of the `ingress` data plane for cross-zone communication.

:::tip
We can support multiple isolated service meshes thanks to Kuma's multi-tenancy support, and workloads from both Kubernetes or any other supported Universal environment can participate in the Service Mesh across different regions, clouds and datacenters while not compromizing the ease of use and still allowing for end-to-end service connectivity.
:::

When running in distributed mode, we introduce the notion of a `global` and `remote` control planes for Kuma:

* **Global**: this control plane will be used to configure the global Service Mesh [policies](/policies) that we want to apply to our data plane proxies. Data plane proxies **cannot** connect direclty to a global control plane, but can connect to `remote` control planes that are being deployed on each underlying zone that we want to include as part of the Service Mesh (can be a Kubernetes cluster, or a VM based cluster). Only one deployment of the global control plane is required, and it can be scaled horizontally.
* **Remote**: we are going to have as many remote control planes as the number of underlying Kubernetes or VM zones that we want to include in a Kuma [mesh](/docs/latest/policies/mesh/). Remote control planes will accept connections from data planes that are being started in the same underlying zone, and they will themselves connect to the `global` control plane in order to fetch the service mesh policies that have been configured. Remote control planes are read-only and **cannot** accept Service Mesh policies to be directly configured on them. They can be scaled horizontally.

In this deployment, a Kuma cluster is made of one global control plane and as many remote control planes as the number of zones that we want to support:

* **Zone**: A zone identifies a Kubernetes cluster, a VPC, or any other cluster that we want to include in a Kuma service mesh.

TODO: IMAGE

In a distributed deployment mode, services will be running on multiple platforms, clouds or Kubernetes clusters (which are identifies as `zones` in Kuma). While all of them will be part of a Kuma mesh by connecting their data plane proxies to the local `remote` control plane in the same zone, implementing service to service connectivity would be tricky since a source service may not know where a destination service is being hosted at (for instance, in another zone).

To implement easy service connectivity, Kuma ships with:

* **DNS Resolver**: Kuma provides an out of the box DNS server on every `remote` control plane that will be used to resolve service addresses when estabilishing any service-to-service communication. It scales horizontally as we scale the `remote` control plane.
* **Ingress Data Plane**: Kuma provides an out of the box `ingress` data plane mode that will be used to enable traffic to enter a zone from another zone. It can be scaled horizontally. Each zone must have an `ingress` data plane deployed. 

:::tip
An `ingress` data plane is specific to internal communication within a mesh and it is not to be considered an API gateway. API gateways are supported via Kuma's [gateway mode](/docs/0.5.1/documentation/dps-and-data-model/#gateway) which can be deployed **in addition** to `ingress` data planes.
:::

The global control plane and the remote control planes communicate with each other via xDS in order to synchronize the resources that are being created to configure Kuma, like policies.

:::warning
**For Kubernetes**: The global control plane on Kubernetes must reside on its own Kubernetes cluster, in order to keep the CRDs separate from the ones that the remote control planes will create during the synchronization process.
:::

### Usage

First and foremost we must start our `global` control plane:

```sh
$ kuma-cp run --mode=global
```

TODO: Add examples to talk to remote control planes
TODO: Add examples to start remote control planes