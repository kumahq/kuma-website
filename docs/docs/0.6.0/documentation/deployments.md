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

<center>
<img src="/images/docs/0.6.0/flat-diagram.png" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Although flat mode can support complex multi-cluster or hybrid deployments (Kubernetes + VMs) as long as the networking requirements are satisfied, typically in most use cases our connectivity cannot be flattened out across multiple clusters. Therefore flat mode is usually a great choice within the context of one cluster (ie: within one Kubernetes cluster or one AWS VPC).

For those situations where the flat deployment mode doesn't satistfy our architecture, Kuma provides a [distributed mode](#distributed-mode) which is more powerful and provides a greater degree of flexibility in more complex environments.

### Usage

In order to deploy Kuma in a flat deployment, the `kuma-cp` control plane must be started in `standalone` mode:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
This is the standard installation method as described in the [installation page](/install).
```sh
$ kumactl install control-plane | kubectl apply -f -
```
:::
::: tab "Universal"
This is the standard installation method as described in the [installation page](/install).
```sh
$ kuma-cp run
```
:::
::::

Once Kuma is up and running, data plane proxies can now [connect](/docs/0.6.0/documentation/dps-and-data-model) directly to it. 

:::tip
When the mode is not specified, Kuma will always start in `standalone` mode by default.
:::

## Distributed Mode

This is a more advanced deployment mode for Kuma that allow us to support service meshes that are running on many clusters, including hybrid deployments on both Kubernetes and VMs.

* **Control plane**: There is one `global` control plane, and many `remote` control planes. A global control plane only accepts connections from remote control planes.
* **Data planes**: The data planes connect to the closest `remote` control plane in the same zone. Additionally, we need to start an `ingress` data plane on every zone.
* **Service Connectivity**: Automatically resolved via the built-in DNS resolver that ships with Kuma. When a service wants to consume another service, it will resolve the DNS address of the desired service with Kuma, and Kuma will respond with a Virtual IP address, that corresponds to that service in the Kuma service domain.

:::tip
We can support multiple isolated service meshes thanks to Kuma's multi-tenancy support, and workloads from both Kubernetes or any other supported Universal environment can participate in the Service Mesh across different regions, clouds and datacenters while not compromizing the ease of use and still allowing for end-to-end service connectivity.
:::

When running in distributed mode, we introduce the notion of a `global` and `remote` control planes for Kuma:

* **Global**: this control plane will be used to configure the global Service Mesh [policies](/policies) that we want to apply to our data plane proxies. Data plane proxies **cannot** connect direclty to a global control plane, but can connect to `remote` control planes that are being deployed on each underlying zone that we want to include as part of the Service Mesh (can be a Kubernetes cluster, or a VM based cluster). Only one deployment of the global control plane is required, and it can be scaled horizontally.
* **Remote**: we are going to have as many remote control planes as the number of underlying Kubernetes or VM zones that we want to include in a Kuma [mesh](/docs/latest/policies/mesh/). Remote control planes will accept connections from data planes that are being started in the same underlying zone, and they will themselves connect to the `global` control plane in order to fetch the service mesh policies that have been configured. Remote control plane policy APIs are read-only and **cannot** accept Service Mesh policies to be directly configured on them. They can be scaled horizontally within their zone.

In this deployment, a Kuma cluster is made of one global control plane and as many remote control planes as the number of zones that we want to support:

* **Zone**: A zone identifies a Kubernetes cluster, a VPC, or any other cluster that we want to include in a Kuma service mesh.

<center>
<img src="/images/docs/0.6.0/distributed-diagram.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

In a distributed deployment mode, services will be running on multiple platforms, clouds or Kubernetes clusters (which are identifies as `zones` in Kuma). While all of them will be part of a Kuma mesh by connecting their data plane proxies to the local `remote` control plane in the same zone, implementing service to service connectivity would be tricky since a source service may not know where a destination service is being hosted at (for instance, in another zone).

To implement easy service connectivity, Kuma ships with:

* **DNS Resolver**: Kuma provides an out of the box DNS server on every `remote` control plane that will be used to resolve service addresses when estabilishing any service-to-service communication. It scales horizontally as we scale the `remote` control plane.
* **Ingress Data Plane**: Kuma provides an out of the box `ingress` data plane mode that will be used to enable traffic to enter a zone from another zone. It can be scaled horizontally. Each zone must have an `ingress` data plane deployed. 

:::tip
An `ingress` data plane is specific to internal communication within a mesh and it is not to be considered an API gateway. API gateways are supported via Kuma's [gateway mode](/docs/0.6.0/documentation/dps-and-data-model/#gateway) which can be deployed **in addition** to `ingress` data planes.
:::

The global control plane and the remote control planes communicate with each other via xDS in order to synchronize the resources that are being created to configure Kuma, like policies.

:::warning
**For Kubernetes**: The global control plane on Kubernetes must reside on its own Kubernetes cluster, in order to keep the CRDs separate from the ones that the remote control planes will create during the synchronization process.
:::

### Usage

In order to deploy Kuma in a distributed deployment, we must start a `global` and as many `remote` control planes as the number of zones that we want to support.

It is recommended that we start the `remote` control planes in each zone we want to connect.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
$ kumactl install control-plane --mode=remote --zone=<zone name> | kubectl apply -f -
$ kumactl install ingress | kubectl apply -f -
$ kumactl install dns | kubectl apply -f -
```

Get the address of the Kuma syncronization service by listing all the

```bash
$ kubectl get services -n kuma-system
NAMESPACE     NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                  AGE
kuma-system   global-remote-sync     LoadBalancer   10.105.9.10     35.226.196.103   5685:30685/TCP                                                           89s
kuma-system   kuma-control-plane     ClusterIP      10.105.12.133   <none>           5681/TCP,443/TCP,5676/TCP,5677/TCP,5678/TCP,5679/TCP,5682/TCP,5653/UDP   90s
kuma-system   kuma-ingress           LoadBalancer   10.105.10.20    34.68.185.18     10001:30991/TCP                                                          29s
```

In this example these would be `global-remote-sync` at `35.226.196.103:5685` and `kuma-ingress` at `34.68.185.18:10001`.

:::tip
Kuma DNS installation supports several flavors of Core DNS and Kube DNS. We recommend to check the configuration of the Kubernetes cluster after deploying Kuma remote control plane. 

:::
::: tab "Universal"

Run the `kuma-cp` in `remote` mode.

```sh
$ KUMA_MODE_MODE=remote KUMA_MODE_REMOTE_ZONE=<zone name> kuma-cp run 
```

Add an `ingress` dataplane, so `kuma-cp` can expose its services for cross-cluster communication.
```bash
$ echo "type: Dataplane
mesh: default
name: ingress-01
networking:
  address: 127.0.0.1
  ingress: {}
  inbound:
  - port: 10000
    tags:
      service: ingress" | kumactl appy -f -

$ kumactl generate dataplane-token --dataplane=ingress-01 > /tmp/cluster1-ingress-token
$ kuma-dp run --name=ingress-01 --cp-address=http://localhost:15681 --dataplane-token-file=/tmp/cluster1-ingress-token --log-level=debug
```

Adding more dataplanes can be done locally by following the Use Kuma section in the [installation page](/install).
:::
::::


The next step is to start the `global` control plane and configure the `remote` control planes connectivity.


:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

Install the `global` control plane.
```bash
$ kumactl install control-plane --mode=global | kubectl apply -f -
```

Modify the configuration with the `remote` control plane details

```bash
$ echo "apiVersion: v1
kind: ConfigMap
metadata:
  name: kuma-control-plane-config
  namespace: kuma-system
data:
  config.yaml: |
    mode:
      global:
        lbaddress: grpcs://<global_cp_ip>:5685
        zones:
          - remote:
              address: grpcs://<zone-1_ip>:5685
            ingress:
              address: <zone-1_ip>:8080
          - remote:
              address: grpcs://<zone-2_ip>:5685
            ingress:
              address: <zone-2_ip>:8080" | kubectl apply -f - 
```

Restart the `global` control plane to make it connect ot all the new `remote` control planes.
```bash
$ kubectl delete -n kuma-system pod --all
```

:::
::: tab "Universal"

Make sure your config file contains a section that describes the `remote` control planes connectivity. 
```yaml
mode:
  global:
    lbaddress: grpcs://<global_cp_ip>:5685
    zones:
      - remote:
          address: grpcs://<zone-1_ip>:5685
        ingress:
          address: <zone-1_ip>:8080
      - remote:
          address: grpcs://<zone-2_ip>:5685
        ingress:
          address: <zone-2_ip>:8080
```

Then run it like this:
```sh
$ KUMA_MODE_MODE=global kuma-cp run --config-file=global.yaml
```
:::
::::

Where `<global_cp_ip>` is the IP address of the Load Balancer that expose the `global` control plane synchronisation service.
`<zone-1_ip>` is the IP address of the Load Balancer of the `remote` control plane. The latter can be used for both the sync service `remote:`
and the `ingress:`.


To utilize the distributed Kuma deployment follow the steps below
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

To figure out the service names that we can use in the applications for cross-cluster communication, we can look at the 
service tag in the deployed dataplanes: 

```bash
$ kubectl get dataplanes -n echo-example -o yaml | grep service
           service: echo-server_echo-example_svc_1010
```

On Kubernetes, Kuma uses transparent proxy. In this mode, `kuma-dp` is listening on port 80 for all the virtual IPs that 
Kuma DNS assigns to services in the `.mesh` DNS zone. Therefore, we have three ways to consume a service from within the mesh:

```bash
<kuma-enabled-pod>$ curl http://echo-server:1010
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh:80
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh
```
The first method still works, but is limited to endpoints implemented within the same Kuma zone (i.e. the same Kubernetes cluster).
The second option allows to consume a service that is distributed cross the distributed Kuma cluster (bound by the same `global` control plane). For
example the there can be an endpoint running in another Kuma zone in a different data-center.

Since most HTTP clients (such as `curl`) will default to port 80, the port can be omitted, like in the third option above.
:::
::: tab "Universal"

In hybrid (Kubernetes and Universal) deployments, the service tag should be the same in both environments (e.g `echo-server_echo-example_svc_1010`)

```yaml
type: Dataplane
mesh: default
name: backend-02 
networking:
  address: 127.0.0.1
  inbound:
  - port: 2010
    servicePort: 1010
    tags:
      service: echo-server_echo-example_svc_1010
      version: "2"
```

If a distributed Universal control plane is used, the service tag has no such limitation.

And to consume the distributed service from Universal deployment, where the application will use `http://localhost:20012`.

```yaml
type: Dataplane
mesh: default
name: backend-02 
networking:
  address: 127.0.0.1
  outbound:
  - port: 20012
    tags:
      service: echo-server_echo-example_svc_1010
      version: "2"
```

:::
::::

::: tip
The Kuma DNS service format (e.g. `echo-server_kuma-test_svc_1010.mesh`) is a composition of Kubernetes Service Name (`echo-server`),
Namespace (`kuma-test`), a fixed string (`svc`), the service port (`1010`). The service is resolvable in the DNS zone `.mesh` where
the Kuma DNS service is hooked.
:::
