# About multi-zone deployments

Kuma supports the use case where multiple services meshes run in different zones. This use case includes hybrid deployments where you run your services on Kubernetes and in Universal mode, on VMs or elsewhere. Your mesh environment can include multiple isolated service meshes (multi-tenancy), and workloads running in different regions, on different clouds, or in different datacenters. A zone can be a Kubernetes cluster, a VPC, or any other deployment you need to include in the same distributed mesh environment.

## Components of a multi-zone deployment

A multi-zone deployment includes: 

* The **global control plane**. Accepts connections only from remote control planes -- not from any data plane proxies. It provides configurations for the global [policies](/policies) that are applied to the data plane proxies.
* The **remote control planes**. Accept connections from data plane proxies that are started in the same underlying zone, and connect to the global control plane to fetch policies for the data plane proxies that connect to them.
* The **data plane proxies**. Connect to the closest remote control plane in the same zone. 
* The **ingress data plane proxy** Provides ingress to services in different zones. If a zone consumes services only, and does not provide them, the zone does not require this component.
  * Configured automatically on Kubernetes if you install directly with `kumactl`.
  * Must be explicitly enabled if you install on Kubernetes with Helm.
  * Must be installed separately in Universal mode.

## How it works

Kuma manages service connectivity -- establishing and maintaining connections across zones in the mesh -- with the ingress data plane proxy and with a DNS resolver.

The DNS resolver is part of each remote control plane. It resolves each service address to a virtual IP address for all service-to-service communication, and scales horizontally withi the remote control plane.

The global control plane and the remote control planes communicate to synchronize resources such as Kuma policy configurations over Kuma Discovery Service (KDS), which is an xDS-based protocol extension.

<center>
<img src="/images/docs/0.6.0/distributed-diagram.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

:::tip
An ingress data plane proxy is not an API gateway. Instead, it is specific to internal communication within the mesh. API gateways are supported in Kuma [gateway mode](/docs/1.1.1/documentation/dps-and-data-model/#gateway) which can be deployed in addition to `ingress` data plane proxies.
:::

