# Networking

Kuma - being an application that wants to improve the underlying connectivity between your services by making the underlying network more reliable - also comes with some networking requirements itself.

## kuma-cp ports

First and foremost, the `kuma-cp` application is a server that offers a number of services - some meant for internal consumption by `kuma-dp` data-planes, some meant for external consumption by [kumactl](../kumactl) CLI, by the [HTTP API](../http-api) or by the [GUI](../gui).

The number and type of exposed ports depends on the mode in which the control plane is run

### Standalone Control Plane

This is the default, single zone mode, in which all of the following ports are enabled in `kuma-cp`

* TCP
    * `5676`: the Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from, e.g. a list of all dataplanes in the mesh.
    * `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
    * `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
    * `5679`: the Admin Server that serves Dataplane Tokens and manages Provided Certificate Authority
    * `5680`: the HTTP server that returns the health status of the control-plane.
    * `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when running in `universal` - that you can use to apply new policies. It also exposes the Kuma GUI at `/gui`
    * `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.
    * `5685`: the Kuma Discovery Service port, leveraged in Distributed control plane mode
* UDP
    * `5653`: the Kuma DNS server

### Global Control Plane


When Kuma is run as a distributed service mesh, the Global control plane exposes the following ports:

* TCP
    * `5443`: The port for the admission webhook, only enabled in `Kubernetes`
    * `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when running in `universal` - that you can use to apply new policies. Manipulating the dataplane resources is not possible. It also exposes the Kuma GUI at `/gui`

### Remote Control Plane

When Kuma is run as a distributed service mesh, the Remote control plane exposes the following ports:

* TCP
    * `5443`: The port for the admission webhook, only enabled in `Kubernetes`
    * `5676`: the Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from, e.g. a list of all dataplanes in the mesh.
    * `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
    * `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
    * `5679`: the Admin Server that serves Dataplane Tokens and manages Provided Certificate Authority
    * `5680`: the HTTP server that returns the health status of the control-plane.
    * `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when running in `universal` - you can only manage the dataplane resources.
    * `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.
* UDP
    * `5653`: the Kuma DNS server

## kuma-dp ports

When we start a data-plane via `kuma-dp` we expect all the inbound and outbound service traffic to go through it. The inbound and outbound ports are defined in the [dataplane specification](./dps-and-data-model/#dataplane-specification) when running in universal mode, while on Kubernetes the service-to-service traffic always runs on port `15001`.

In addition to the service traffic ports, the data-plane automatically also opens the `envoy` [administration interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) listener on the following addresses:

* On Kubernetes, by default at `127.0.0.1:9901`.
* On Universal, by default on the first available port greater or equal than `30001`, like `127.0.01:30001`.

The Envoy administration interface can also be [manually configured](./dps-and-data-model/#envoy) to listen on any arbitraty port by specifying the `--admin-port` argument when running `kuma-dp`.

## Service Discovery

Here we are going to be exploring the communication between `kuma-dp` and `kuma-cp`, and the communication between multiple `kuma-dp` to handle our service traffic.

Every time a data-plane (served by `kuma-dp`) connects to the control-plane, it initiates a gRPC streaming connection to Kuma (served by `kuma-cp`) in order to retrieve the latest policiy configuration, and send diagnostic information to the control-plane.

In [standalone mode](/docs/1.0.0/documentation/deployments/#standalone-mode) the `kuma-dp` process will connect directly to the `kuma-cp` instances.

In a [multi-zone deployment](/docs/1.0.0/documentation/deployments/#multi-zone-mode) the `kuma-dp` processes will connect to the remote control plane, while the remote control planes will connect to the global control plane over an extension of the xDS API that we have built called "KDS" (Kuma Discovery Service). In multi-zone mode, the data plane proxies never connect to the global control plane but only to the remote ones.

::: tip
The connection between the data-planes and the control-plane is not on the execution path of the service requests, which means that if the data-plane temporarily loses connection to the control-plane the service traffic won't be affected.
:::

While doing so, the data-planes also advertise the IP address of each service. The IP address is retrieved:

* On Kubernetes by looking at the address of the `Pod`.
* On Universal by looking at the inbound listeners that have been configured in the [`inbound` property](./dps-and-data-model/#dataplane-specification) of the data-plane specification.

The IP address that's being advertised by every data-plane to the control-plane is also being used to route service traffic from one `kuma-dp` to another `kuma-dp`. This means that Kuma knows at any given time what are all the IP addresses associated to every replica of every service. Another use-case where the IP address of the data-planes is being used is for metrics scraping by Prometheus.

Kuma already ships with its own [DNS service discovery](/docs/1.0.0/documentation/networking/#kuma-dns) on both standalone and multi-zone modes. 

Connectivity among the `kuma-dp` instances can happen in two ways:

* In [standalone mode](/docs/1.0.0/documentation/deployments/#standalone-mode) `kuma-dp` processes communicate with each other in a flat networking topology. This means that every data-plane must be able to consume another data-plane by directly sending requests to its IP address. In this mode, every `kuma-dp` must be able to send requests to every other `kuma-dp` on the specific ports that govern service traffic, as described in the `kuma-dp` [ports section](#kuma-dp-ports).
* In [multi-zone mode](/docs/1.0.0/documentation/deployments/#multi-zone-mode) connectivity is being automatically resolved by Kuma to either a data-plane running in the same zone, or through the address of a [Kuma ingress](/docs/1.0.0/documentation/dps-and-data-model/#ingress) in another zone for cross-zone connectivity. This means that multi-zone connectivity can be used to connect services running in different clusters, platforms or clouds in an automated way. Kuma also creates a `.mesh` zone via its [native DNS resolver](/docs/1.0.0/documentation/networking/#kuma-dns). The automatically created `kuma.io/zone` tag can be used with Kuma policies in order to determine how traffic flow across a multi-zone setup.

::: tip
By default cross-zone connectivity requires [mTLS](/docs/1.0.0/policies/mutual-tls/) to be enabled on the [Mesh](/docs/1.0.0/policies/mesh/) with the appropriate [Traffic Permission](/docs/1.0.0/policies/traffic-permissions/) to enable the flow of traffic. Otherwise, unsecured traffic won't be permitted outside of each zone.
:::

## Kuma DNS

The Kuma control plane deploys its Domain Name Service resolver, which is available in `standalone` and `remote` [multi-zone mode](./deployments/#multi-zone-mode) on UDP port `5653` (resembling the standard port `53`). Its purpose is to allow for decoupling the service name resolving from the underlying infrastructure and thus make Kuma more flexible. When Kuma is deployed as a distributed control plane, the Kuma DNS enables cross-cluster service discovery.

### Deployment

To enable the redirection of the DNS requests for the `.mesh` DNS zone (the default), within a Kubernetes, use `kumactl install dns | kubectl apply -f -`. This invocation of `kumactl` expects to find the environment variable `KUBECONFIG` set, so it can fetch the active Kubernetes DNS server configuration. Once this is done, `kumactl install dns` will output a patched resource ready to be applied through `kubectl apply`. Since this is a modification to system resources, it is strongly recommended that you first inspect the resulting configuration.

`kumactl install dns` is recognizing and supports the major flavors of CoreDNS as well as Kube DNS resources.

::: tip
The typical environment where Kuma DNS will be used is Kubernetes. It leverages the transparent proxy by default, which is a strict requirement for utilizing the Kuma DNS virtual IPs (VIP). In the future, Kuma will provide DNS support in Universal mode too.
:::

### Configuration

Kuma DNS can be configured by the configuration file, or by the respective environment variables as follows:

```yaml
# DNS Server configuration
dnsServer:
  # The domain that the server will resolve the services for
  domain: "mesh" # ENV: KUMA_DNS_SERVER_DOMAIN
  # Port on which the server is exposed
  port: 5653 # ENV: KUMA_DNS_SERVER_PORT
  # The CIDR range used to allocate
  CIDR: "240.0.0.0/4" # ENV: KUMA_DNS_SERVER_CIDR
```

The `domain` field can change the default `.mesh` DNS zone that Kuma DNS will resolve for. If this is changed, please check the output of `kumactl install dns` and change the zone accordingly, so that your Kube DNS or Core DNS server will redirect all the relevant DNS requests.

The `port` can set the port on which the Kuma DNS is accepting requests. Changing this value on Kubernetes shall be reflected in the respective port setting in the `kuma-control-plane` service. 

The `CIDR` field sets the IP range of virtual IPs. The default `240.0.0.0/4` is reserved for future use IPv4 range and is guaranteed to be non-routable. We strongly recommend to not change this, unless it is needed.

### Operation 

The basic operation of Kuma DNS includes a couple of main components: DNS server, VIPs allocator, cross-replica persistence.

The DNS server listens on port `5653` and reponds for type `A` DNS requests and answers with `A` record, e.g. ```<service>.mesh. 60 IN A  240.0.0.100```. The default TTL is set to 60 seconds, to ensure the client will synchronize with Kuma DNS and account for any changes happening meanwhile.

Kuma DNS allocates the virtual IPs from the configured CIDR, by constantly scanning the services available in all Kuma meshes. When a service is removed its VIP is freed too and Kuma DNS will not respond for it with `A` DNS record.

::: tip
Kuma DNS is not a service discovery mechanism, instead it returns a single VIP, mapped to the relevant service in the mesh. This makes for a unified view of all services within the zone or cross-zones.
:::

### Usage

Consuming a service handled by Kuma DNS from inside a Kubernetes container is based on the automatically generated `kuma.io/service` tag. The resulting domain name has the format `{service tag}.mesh`, for example:
```bash
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh:80
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh
```

Since the default VIP created listeners will default to port `80`, it can be omitted when using a standard HTTP client.
 
Kuma DNS allocates a VIP for every Service within a mesh. Then, it creates outbound virtual listener for every VIP. However, by inspecting `curl localhost:9901/config_dump`, we can see sections similar to this one:

```json
    {
     "name": "outbound:240.0.0.1:80",
     "active_state": {
      "version_info": "51adf4e6-287e-491a-9ae2-e6eeaec4e982",
      "listener": {
       "@type": "type.googleapis.com/envoy.api.v2.Listener",
       "name": "outbound:240.0.0.1:80",
       "address": {
        "socket_address": {
         "address": "240.0.0.1",
         "port_value": 80
        }
       },
       "filter_chains": [
        {
         "filters": [
          {
           "name": "envoy.tcp_proxy",
           "typed_config": {
            "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
            "stat_prefix": "echo-server_kuma-test_svc_80",
            "cluster": "echo-server_kuma-test_svc_80"
           }
          }
         ]
        }
       ],
       "deprecated_v1": {
        "bind_to_port": false
       },
       "traffic_direction": "OUTBOUND"
      },
      "last_updated": "2020-07-06T14:32:59.732Z"
     }
    },
```

## Transparent Proxying

There are two ways of how the service can interact with its sidecar to connect to other services.
One is explicitly defining outbounds in the Dataplane:
```yaml
type: Dataplane
...
networking:
  ...
  outbound:
  - port: 10000
    tags:
      kuma.io/service: backend
```
This approach is simple, but it has the disadvantage that you need to reconfigure the service to use `http://localhost:10000` when it wants to connect with service `backend`.
This strategy is used on Universal deployments.

The alternative approach is Transparent Proxying. With Transparent Proxying before we start a service, we apply [`iptables`](https://linux.die.net/man/8/iptables) that intercept all the traffic on VM/Pod and redirect it to Envoy.
The main advantage of this mode is when you integrate with the current hostname resolving mechanism, you can deploy Service Mesh _transparently_ on the platform without reconfiguring applications.

Kuma provides support for Transparent Proxying on Kubernetes.

### Configure intercepted traffic

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
Kuma deploys `iptables` rules either with `kuma-init` Init Container or with `cni` when deployed with CNI mode.

By default, all the traffic is intercepted by Envoy. You can exclude which ports are intercepted by Envoy with the following annotations placed on the Pod
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        # all incomming connections on ports 1234 won't be intercepted by Envoy
        traffic.kuma.io/exclude-inbound-ports: "1234"
        # all outgoing connections on ports 5678, 8900 won't be intercepted by Envoy
        traffic.kuma.io/exclude-outbound-ports: "5678,8900"
    spec:
      containers:
        ...
```  
:::

You can also control this value on whole Kuma deployment with the following Kuma CP configuration
```sh
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS=1234
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS=5678,8900
``` 

Global settings can be always overridden with annotations on the individual Pods. 

::: tip
When deploying Kuma with `kumactl install control-plane` you can set those settings with
```sh
kumactl install control-plane \
  --env-var KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS=1234
  --env-var KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS=5678,8900
```

When deploying Kuma with HELM, use `controlPlane.envVar` value
```yaml
envVar:
  KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS: "1234"
  KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS=5678,8900
```
:::
::::
 
