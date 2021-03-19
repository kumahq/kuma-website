# About multi-zone deployments

Kuma supports the use case where you have multiple services meshes running in different zones. This use case includes hybrid deployments where you run your services on Kubernetes and in Universal mode, on VMs or elsewhere. Your mesh environment can include multiple isolated service meshes (multi-tenancy), and workloads running in different regions, on different clouds, or in different datacenters. A zone can be a Kubernetes cluster, a VPC, or any other cluster you need to include in the same distributed mesh environment.

## How it works

A multi-zone deployment includes different roles for different components of your mesh environment: 

* The **Global control plane** accepts connections only from remote control planes -- not from any data plane proxies. It provides configurations for the global [policies](/policies) that are applied to the data plane proxies.
* The **Remote control planes** accept connections from data plane proxies that are started in the same underlying zone, and they connect to the `global` control plane to fetch their service mesh policies.
* The **Data plane proxies**: connect to the closest `remote` control plane in the same zone. Additionally, we need to start an `ingress` data plane proxy on every zone to have cross-zone communication between data plane proxies in different zones.

Service connectivity is provided by:

* **DNS Resolver**: Kuma provides an out of the box DNS server on every `remote` control plane that will be used to resolve service addresses when estabilishing any service-to-service communication. It scales horizontally as we scale the `remote` control plane.
* **Ingress Data Plane**: Kuma provides an out of the box `ingress` data plane proxy mode that will be used to enable traffic to enter a zone from another zone. It can be scaled horizontally. Each zone must have an `ingress` data plane deployed. 


* **Service Connectivity**: Automatically resolved via the built-in DNS resolver that ships with Kuma. When a service wants to consume another service, it will resolve the DNS address of the desired service with Kuma, and Kuma will respond with a Virtual IP address, that corresponds to that service in the Kuma service domain.

When running in multi-zone mode, we introduce the notion of a `global` and `remote` control planes for Kuma:

* **Global**: this control plane will be used to configure the global Service Mesh [policies](/policies) that we want to apply to our data plane proxies. Data plane proxies **cannot** connect directly to a global control plane, but can connect to `remote` control planes that are being deployed on each underlying zone that we want to include as part of the Service Mesh (can be a Kubernetes cluster, or VM based). Only one deployment of the global control plane is required, and it can be scaled horizontally.
* **Remote**: we are going to have as many remote control planes as the number of underlying Kubernetes or VM zones that we want to include in a Kuma [mesh](/docs/1.1.0/policies/mesh/). Remote control planes accept connections from data plane proxies that are started in the same underlying zone, and they connect to the `global` control plane to fetch their service mesh policies. Remote control plane policy APIs are read-only and **cannot** accept Service Mesh policies to be directly configured on them. They can be scaled horizontally within their zone.

<center>
<img src="/images/docs/0.6.0/distributed-diagram.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

While all of them will be part of a Kuma mesh by connecting their data plane proxies to the local `remote` control plane in the same zone, implementing service to service connectivity would be tricky since a source service may not know where a destination service is being hosted at (for instance, in another zone).



:::tip
An `ingress` data plane proxy is specific to internal communication within a mesh and it is not to be considered an API gateway. API gateways are supported via Kuma's [gateway mode](/docs/1.1.0/documentation/dps-and-data-model/#gateway) which can be deployed **in addition** to `ingress` data plane proxies.
:::

The global control plane and the remote control planes communicate with each other via xDS in order to synchronize the resources that are being created to configure Kuma, like policies.