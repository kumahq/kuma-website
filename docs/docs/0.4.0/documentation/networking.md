# Networking

Kuma - being an application that wants to improve the underlying connectivity between your services by making the underlying network more reliable - also comes with some networking requirements itself.

## kuma-cp ports

First and foremost, the `kuma-cp` application is a server that offers a number of services - some meant for internal consumption by `kuma-dp` data-planes, some meant for external consumption by [kumactl](../kumactl) CLI, by the [HTTP API](../http-api) or by the [GUI](../gui).

When `kuma-cp` starts up, by default it listens on a few ports:

* `5676`: the Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from, e.g. a list of all dataplanes in the mesh.
* `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
* `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
* `5679`: the Admin Server that serves Dataplane Tokens and manages Provided Certificate Authority
* `5680`: the HTTP server that returns the health status of the control-plane.
* `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when running in `universal` - that you can use to apply new policies.
* `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.
* `5683`: the HTTP server that exposes Kuma UI.

## kuma-dp ports

When we start a data-plane via `kuma-dp` we expect all the inbound and outbound service traffic to go through it. The inbound and outbound ports are defined in the [dataplane specification](./dps-and-data-model/#dataplane-specification) when running in universal mode, while on Kubernetes the service-to-service traffic always runs on port `15001`.

In addition to the service traffic ports, the data-plane automatically also opens the `envoy` [administration interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) listener on the following addresses:

* On Kubernetes, by default at `127.0.0.1:9901`.
* On Universal, by default on the first available port greater or equal than `30001`, like `127.0.01:30001`.

The Envoy administration interface can also be [manually configured](./dps-and-data-model/#envoy) to listen on any arbitrary port by specifying the `--admin-port` argument when running `kuma-dp`.

## Service Discovery

Here we are going to be exploring the communication between `kuma-dp` and `kuma-cp`, and the communication between multiple `kuma-dp` to handle our service traffic.

Every time a data-plane (served by `kuma-dp`) connects to the control-plane, it initiates a gRPC streaming connection to Kuma (served by `kuma-cp`) in order to retrieve the latest policy configuration, and send diagnostic information to the control-plane.

::: tip
The connection between the data-planes and the control-plane is not on the execution path of the service requests, which means that if the data-plane temporarily loses connection to the control-plane the service traffic won't be affected.
:::

While doing so, the data-planes also advertise the IP address of each service. The IP address is retrieved:

* On Kubernetes by looking at the address of the `Pod`.
* On Universal by looking at the inbound listeners that have been configured in the [`inbound` property](./dps-and-data-model/#dataplane-specification) of the data-plane specification.

The IP address that's being advertised by every data-plane to the control-plane is also being used to route service traffic from one `kuma-dp` to another `kuma-dp`. This means that Kuma knows at any given time what are all the IP addresses associated to every replica of every service. Another use-case where the IP address of the data-planes is being used is for metrics scraping by Prometheus.

Because Kuma by design already knows the address to every data-plane - and therefore to every service in the mesh - it is not required to use Kuma with a third-party service discovery tool or dns resolver, because such tools would not give Kuma any additional information than the one it already knows.

In order for connectivity to work among the `kuma-dp` instances, Kuma also assumes a flat network topology: this means that every data-plane must be able to consume another data-plane by directly sending requests to its IP address. This is true also in the case of multi-region or multi-datacenter setups.

<center>
<img src="/images/docs/0.3.2/diagram-16.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

As illustrated in the picture above, every `kuma-dp` must be able to send requests to every other `kuma-dp` on the specific ports that govern service traffic, as described in the `kuma-dp` [ports section](#kuma-dp-ports).