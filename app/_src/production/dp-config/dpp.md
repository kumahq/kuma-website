---
title: Data plane proxy
content_type: explanation
---

A **data plane proxy (DPP)** is the part of {{site.mesh_product_name}} that runs next to each workload that is a member of the mesh.
A DPP is composed of the following components:

- a `Dataplane` entity defines the configuration of the DPP
- a `kuma-dp` binary runs on each instance that is part of the mesh. This binary spawns the following subprocesses:
  - `Envoy` receives configuration from the control-plane to manage traffic correctly 
  - `core-dns` resolves {{site.mesh_product_name}} specific DNS entries

{% tip %}
Data plane proxies are also called sidecars.
{% endtip %}

We have one instance of `kuma-dp` for every instance of every service.

<center>
<img src="/assets/images/docs/0.4.0/diagram-11.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Concepts

### Inbound

An inbound consists of:

- a set of tags
- the port the workload listens on

Most of the time a DPP exposes a single inbound. When a workload exposes multiple ports, multiple inbounds can be defined.

### Tags
Tags are a set of key-value pairs (.e.g `version=v2`) that are defined for each DPP inbound. These tags serve the following purposes:

- specifying the service this DPP inbound is part of
- adding metadata about the exposed service
- allowing subsets of DPPs to be selected by these tags

Tags prefixed with `kuma.io` are reserved:

* `kuma.io/service` identifies the service name. On Kubernetes this tag is automatically created, while on Universal it must be specified manually. This tag must always be present.
* `kuma.io/zone` identifies the zone name in a {% if_version lte:2.1.x %}[multi-zone deployment](/docs/{{ page.release }}/deployments/multi-zone){% endif_version %}{% if_version gte:2.2.x %}[multi-zone deployment](/docs/{{ page.release }}/production/deployment/multi-zone/){% endif_version %}. This tag is automatically created and cannot be overwritten.
* `kuma.io/protocol` identifies [the protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma) of the service exposed by this inbound. Accepted values are `tcp`, `http`, `http2`, `grpc` and `kafka`.

### Service
A service is a group of all DPP inbounds that have the same `kuma.io/service` tag.

### Outbounds
An outbound allows the workload to consume a service in the mesh using a local port.
This is only useful when not using [transparent proxy](/docs/{{ page.release }}/{% if_version lte:2.1.x %}networking/transparent-proxying/{% endif_version %}{% if_version gte:2.2.x lte:2.8.x %}production/dp-config/transparent-proxying/{% endif_version %}{% if_version gte:2.9.x %}networking/transparent-proxy/introduction/{% endif_version %}). 

## `Dataplane` entity

The `Dataplane` entity consists of:

- the IP address used by other DPPs to connect to this DPP
- inbounds
- outbounds

A `Dataplane` entity must be present for each DPP. `Dataplane` entities are managed differently depending on the environment: 

- Kubernetes: The control plane {% if_version lte:2.1.x %}[**automatically generates**](/docs/{{ page.release }}/explore/dpp-on-kubernetes){% endif_version %}{% if_version gte:2.2.x %}[**automatically generates**](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/){% endif_version %} the `Dataplane` entity. 
- Universal: The {% if_version lte:2.1.x %}[**user defines**](/docs/{{ page.release }}/explore/dpp-on-universal){% endif_version %}{% if_version gte:2.2.x %}[**user defines**](/docs/{{ page.release }}/production/dp-config/dpp-on-universal/){% endif_version %} the `Dataplane` entity. 
 
## Dynamic configuration of the data plane proxy 

When the DPP runs:
- The `kuma-dp` retrieves Envoy startup configuration from the control plane.
- The `kuma-dp` process starts Envoy with this configuration.
- Envoy connects to the control plane using XDS and receives configuration updates when the state of the mesh changes.

The control plane uses policies and `Dataplane` entities to generate the DPP configuration. 

<center>
<img src="/assets/images/docs/0.4.0/diagram-10.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Data plane proxy ports

When we start a data-plane via `kuma-dp` we expect all the inbound and outbound service traffic to go through it. The inbound and outbound ports are defined in the dataplane specification when running in universal mode, while on Kubernetes the service-to-service traffic always runs on port `15001`.

In addition to the service traffic ports, the data-plane automatically also opens the `envoy` [administration interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) listener on the `127.0.0.1:9901`.

## Schema

{% json_schema Dataplane type=proto %}
