---
title: Multi-zone deployment
content_type: explanation
---

## About

{{site.mesh_product_name}} supports running your service mesh in multiple zones. It is even possible to run with a mix of Kubernetes and Universal zones. Your mesh environment can include multiple isolated service meshes (multi-tenancy), and workloads running in different regions, on different clouds, or in different datacenters. A zone can be a Kubernetes cluster, a VPC, or any other deployment you need to include in the same distributed mesh environment.
The only condition is that all the data planes running within the zone must be able to connect to the other data planes in this same zone.

<center>
<img src="/assets/images/diagrams/gslides/kuma_multizone.svg" alt="Kuma service mesh multi zone deployment without zone egress" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>
Or without the optional zone egress:
<center>
<img src="/assets/images/diagrams/gslides/kuma_multizone_without_egress.svg" alt="Kuma service mesh multi zone deployment with zone egress" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

### How it works

In {{site.mesh_product_name}}, zones are abstracted away, meaning that your data plane proxies will find services wherever they run.
This way you can make a service multi-zone by having data planes using the same `kuma.io/service` in different zones. This gives you automatic fail-over of services in case a specific zone fails.

Let's look at how a service `backend` in `zone-b` is advertised to `zone-a` and a request from the local zone `zone-a` is routed to the remote
service in `zone-b`.

#### Destination service zone

When the new service `backend` joins the mesh in `zone-b`, the `zone-b` zone control plane adds this service to the `availableServices` on the `zone-b` `ZoneIngress` resource.
The `kuma-dp` proxy running as a zone ingress is configured with this list of
services so that it can route incoming requests.
This `ZoneIngress` resource is then also synchronized to the global control plane.

The global control-plane will propagate the zone ingress resources and all policies to all other zones over {{site.mesh_product_name}} Discovery Service (KDS), which is a protocol based on xDS.

#### Source service zone

The `zone-b` `ZoneIngress` resource is synchronized from the global control
plane to the `zone-a` zone control plane.
Requests to the `availableServices` from `zone-a` are load balanced between local instances and remote instances of this service.
Requests send to `zone-b` are routed to the zone ingress proxy of `zone-b`.

For load-balancing, the zone ingress endpoints are weighted with the number of instances running behind them. So a zone with 2 instances will receive twice as much traffic than a zone with 1 instance.
You can also favor local service instances with [locality-aware load balancing](/docs/{{ page.version }}/policies/locality-aware).

In the presence of a {% if_version lte:2.1.x %}[zone egress](/docs/{{ page.version }}/explore/zoneegress){% endif_version %}{% if_version gte:2.2.x %}[zone egress](/docs/{{ page.version }}/production/cp-deployment/zoneegress/){% endif_version %}, the traffic is routed through the local zone egress before being sent to the remote zone ingress.

When using {% if_version lte:2.1.x %}[transparent proxy](/docs/{{ page.version }}/networking/transparent-proxying){% endif_version %}{% if_version gte:2.2.x %}[transparent proxy](/docs/{{ page.version }}/production/dp-config/transparent-proxying/){% endif_version %} (default in Kubernetes),
{{site.mesh_product_name}} generates a VIP,
a DNS entry with the format `<kuma.io/service>.mesh`, and will listen for traffic on port 80. The `<kuma.io/service>.mesh:80` format is just a convention.
[`VirtualOutbounds`](/docs/{{ page.version }}/policies/virtual-outbound)s enable you to customize the listening port and how the DNS name for these services looks.

{% tip %}
A zone ingress is not an API gateway. It is only used for cross-zone communication within a mesh. API gateways are supported in {{site.mesh_product_name}} [gateway mode](/docs/{{ page.version }}/explore/gateway) and can be deployed in addition to zone ingresses.
{% endtip %}

### Components of a multi-zone deployment

A multi-zone deployment includes:

- The **global control plane**:
  - Accept connections only from zone control planes.
  - Accept creation and changes to [policies](/policies) that will be applied to the data plane proxies.
  - Send policies down to zone control planes.
  - Send zone ingresses down to zone control plane.
  - Keep an inventory of all data plane proxies running in all zones (this is only done for observability but is not required for operations).
  - Reject connections from data plane proxies.
- The **zone control planes**:
  - Accept connections from data plane proxies started within this zone.
  - Receive policy updates from the global control plane.
  - Send data plane proxies and zone ingress changes to the global control plane.
  - Compute and send configurations using XDS to the local data plane proxies.
  - Update list of services which exist in the zone in the zone ingress.
  - Reject policy changes that do not come from global.
- The **data plane proxies**:
  - Connect to the local zone control plane.
  - Receive configurations using XDS from the local zone control plane.
  - Connect to other local data plane proxies.
  - Connect to zone ingresses for sending cross zone traffic.
  - Receive traffic from local data plane proxies and local zone ingresses.
- The **zone ingress**:
  - Receive XDS configuration from the local zone control plane.
  - Proxy traffic from other zone data plane proxies to local data plane proxies.
- (optional) The **zone egress**:
  - Receive XDS configuration from the local zone control plane.
  - Proxy traffic from local data plane proxies:
    - to zone ingress proxies from other zones;
    - to external services from local zone;
