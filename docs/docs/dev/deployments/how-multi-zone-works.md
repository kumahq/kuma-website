# About multi-zone deployments

Kuma supports running your service mesh in multiple zones. It is even possible to run with a mix of Kubernetes and Universal zones. Your mesh environment can include multiple isolated service meshes (multi-tenancy), and workloads running in different regions, on different clouds, or in different datacenters. A zone can be a Kubernetes cluster, a VPC, or any other deployment you need to include in the same distributed mesh environment.

## Components of a multi-zone deployment

A multi-zone deployment includes:

* The **global control plane**. Accepts connections only from zone control planes -- not from any data plane proxies. It provides configurations for the global [policies](/policies) that are applied to the data plane proxies.
* The **zone control planes**. Accept connections from data plane proxies that are started in the same underlying zone, and connect to the global control plane to fetch policies for the data plane proxies that connect to them.
* The **data plane proxies**. Connect to the zone control plane in the same zone.
* The **zone ingress** Provides ingress to local services for different zones.
    * Configured automatically on Kubernetes if you install directly with `kumactl`.
    * Must be explicitly enabled if you install on Kubernetes with Helm.
    * Must be installed separately in Universal mode.

## How it works

Kuma manages service connectivity -- establishing and maintaining connections across zones in the mesh -- with the zone ingress and with a DNS resolver.

The DNS resolver is embedded in each data plane proxy. It resolves each service address to a virtual IP address for all service-to-service communication.

The global control plane and the zone control planes communicate to synchronize resources such as Kuma policy configurations over Kuma Discovery Service (KDS), which is a protocol based on xDS.

<center>
<img src="/images/docs/0.6.0/distributed-diagram.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

:::tip
A zone ingress is not an API gateway. Instead, it is specific to internal cross-zone communication within the mesh. API gateways are supported in Kuma [gateway mode](../documentation/dps-and-data-model.md) which can be deployed in addition to zone ingresses.
:::
