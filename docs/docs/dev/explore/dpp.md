# Data plane proxy

A **data plane proxy (DPP)** is the part of Kuma that runs next to each workload that is a member of the mesh.
A DPP is composed of the following components:

- a `Dataplane` entity which defines the configuration of the data plane proxy.
- a `kuma-dp` binary that runs on each instance that is part of the mesh. This binary spawns the following subprocesses:
  - `envoy` which will receive configuration from the control-plane to manage traffic correctly 
  - `core-dns` which will help resolve Kuma specific DNS entries

::: tip
Data plane proxies are also often called sidecars.
:::

Since we have one replica of `kuma-dp` for every replica of every service, the number of DPP running quickly adds up. 
For example, if we have 6 replicas of a "Redis" service, then we must have one instance of `kuma-dp` running alongside each replica of the service, therefore 6 replicas of `kuma-dp` and 6 `Dataplane` entities as well.

<center>
<img src="/images/docs/0.4.0/diagram-11.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Concepts: Inbounds, Outbounds, Tags and Services

### Inbound

Inbounds are defined in the `Dataplane` entity and is a combination of a port and a set of tags.
The port is the local port that the workload binds to for this inbound.

Most of the time a DPP exposes a single inbound. When a workload exposes multiple ports, multiple inbounds can be defined.

### Tags
Tags are a set of key-values that are defined for each DPP inbound. These tags serve these purposes:

- Define which service this DPP inbound is part of.
- Add some metadata on the nature of the service being exposed. 
- Be able to select subsets of dataplanes using these tags.

Some tags are reserved to Kuma are prefixed with `kuma.io` like:

* `kuma.io/service`: Identifies the service name. On Kubernetes this tag is automatically created, while on Universal it must be specified manually. This tag must always be present.
* `kuma.io/zone`: Identifies the zone name in a [multi-zone deployment](../deployments/multi-zone.md). This tag is automatically created and cannot be overwritten.
* `kuma.io/protocol`: Identifies [the protocol](../../policies/protocol-support-in-kuma) of the service exposed by this inbound. Accepted values are `tcp`, `http`, `http2`, `grpc` and `kafka`.

### Service
A service is a group of all DPP inbounds that have the same `kuma.io/service` tag.

### Outbounds
Outbounds in the `Dataplane` entity is a way to expose a service in the mesh on a local port of the proxy.
This is useful when not using [transparent-proxy](../networking/transparent-proxying.md) which makes outbounds automatically managed by the control-plane. 

## Dataplane Entity

The `Dataplane` entity serves the following purpose:

- Define the different **inbounds**
- Describe how the other DPPs can connect to this DPP
- Define the different **outbounds**
- Configure local binaries (expose the Envoy admin port, expose health probes, configure transparent-proxy)

A `Dataplane` entity must be present for each DPP. This will work differently in the following environments: 

- Kubernetes: the `Dataplane` entity is generated [**automatically**](dpp-on-kubernetes.md) by the control-plane.
- Universal: the `Dataplane` entity must be defined [**manually**](dpp-on-universal.md).
 
The `Dataplane` entity includes the sections that are described below in the [Dataplane Specification](../generated/resources/proxy_dataplane.md):

* `networking` define what services are exposed, transparent-proxy configuration, inbounds, and outbounds. 
* `metrics` to configure how to collect metrics from the data plane proxy and the workload, check the [traffic metrics](../policies/traffic-metrics.md#expose-metrics-from-applications) for more details.
* `probes` to configure unsecure port to access workload's health endpoints for platform health probing, check the [health probes](../policies/service-health-probes.md) for more details.

## How data plane proxies get configured

As mentioned previously each DPP has a `Dataplane` entity attached to it which describes what and how a workload should expose.

On DPP startup it will:
- The `kuma-dp` process sends a bootstrap request against the zone control-plane to retrieve the Envoy startup configuration
- The `kuma-dp` process starts Envoy with this bootstrap configuration
- Envoy will connect to the zone control-plane using XDS and start stream its configuration and receiving updates
- The zone control-plane will use all policies and `Dataplane` entities to generate the DPP configuration and push it down to the Envoy using the XDS connection

<center>
<img src="/images/docs/0.4.0/diagram-10.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Envoy

`kuma-dp` is built on top of `Envoy`, which has a powerful [Admin API](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) that enables monitoring and troubleshooting of a running dataplane.

By default, `kuma-dp` starts `Envoy Admin API` on the loopback interface (that is only accessible from the local host)
and port is taken from the data plane resource field `networking.admin.port`. If the `admin` section is empty or port
is equal to zero then the default value for port will be taken from the Kuma Control Plane configuration:

```yaml
# Configuration of Bootstrap Server, which provides bootstrap config to Dataplanes
bootstrapServer:
  # Parameters of bootstrap configuration
  params:
    # Port of Envoy Admin
    adminPort: 9901 # ENV: KUMA_BOOTSTRAP_SERVER_PARAMS_ADMIN_PORT
```

It is not possible to override the data plane proxy resource directly in Kubernetes. If you still want to change the admin port, use the pod annotation `kuma.io/envoy-admin-port`.
