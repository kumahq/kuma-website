# Documentation

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

It's time to start using Kuma and build your Service Mesh. In this section you will find the technical material to get up and running 🚀.

If you haven't read the first [Welcome to Kuma](/docs/DRAFT) section, we strongly suggest to start from here.

## Overview

As we have [already learned](/docs/DRAFT), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

The first step is obviously to [download and install Kuma](/install/DRAFT) on the platform of your choice. Different distributions will present different installation instructions that follow the best practices for the platform you have selected.

Regardless of what platform you decide to use, the fundamental behavior of Kuma at runtime will not change across different distributions. These fundamentals are important to explore in order to understand what Kuma is and how it works.

::: tip
Installing Kuma on Kubernetes is fully automated, while installing Kuma on Linux requires the user to run the Kuma executables. Both ways are very simple, and can be explored from the [installation page](/install/DRAFT).
:::

There are two main components of Kuma that are very important to understand:

- **Control-Plane**: Kuma is first and foremost a control-plane that will accept user input (you are the user) in order to create and configure [Policies](/docs/DRAFT/policies) like [Service Meshes](/docs/DRAFT/policies/#mesh), and in order to add services and configure their behavior within the Meshes you have created.
- **Data-Plane**: Kuma also bundles a data-plane implementation based on top of [Envoy](https://www.envoyproxy.io/) for convenience, in order to get up and running quickly. An instance of the data-plane will run alongside every instance of our services, and it will process both incoming and outgoing requests for the service.

::: tip
**Multi-Mesh**: Kuma ships with multi-tenancy support since day one. This means you can create and configure multiple isolated Service Meshes from **one** control-plane. By doing so we lower the complexity and the operational cost of supporting multiple meshes. [Explore Kuma's Policies](/docs/DRAFT/policies).
:::

Since Kuma bundles a data-plane in addition to the control-plane, we decided to call the executables `kuma-cp` and `kuma-dp` to differentiate them. Let's take a look at all the executables that ship with Kuma:

- `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
- `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
- `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
- `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
- `kuma-prometheus-sd`: this is a helper tool that enables native integration between `Kuma` and `Prometheus`. Thanks to it, `Prometheus` will be able to automatically find all dataplanes in your Mesh and scrape metrics out of them.
- `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

In addition to these binaries, there is another binary that will be executed when running on Kubernetes:

- `kuma-injector`: only for Kubernetes, this is a process that listens to events propagated by Kubernetes, and that automatically injects a `kuma-dp` sidecar container to our services.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data-planes (`kuma-dp`) which will connect to the control-plane as soon as they startup. Kuma supports two modes:

- `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
- `kubernetes`: when it's being deployed - well - on Kubernetes.

### Universal mode

When running in **Universal** mode, Kuma will require a PostgreSQL database to store its state. The PostgreSQL database and schema will have to be initialized accordingly to the installation instructions.

Unlike `kubernetes` mode, Kuma won't require the `kuma-injector` executable to run:

<center>
<img src="/images/docs/0.2.0/diagram-09.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Kubernetes mode

When running on **Kubernetes**, Kuma will store all of its state and configuration on the underlying Kubernetes API Server, therefore requiring no dependency to store the data. But it requires the `kuma-injector` executable to run in a Pod (only one instance per Kubernetes cluster) so that it can automatically inject `kuma-dp` on any Pod that belongs to a Namespace that includes the following label:

```
kuma.io/sidecar-injection: enabled
```

When following the installation instructions, `kuma-injector` will be automatically started.

<center>
<img src="/images/docs/0.2.0/diagram-08.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**Full CRD support**: When using Kuma in Kubernetes mode you can create [Policies](/docs/DRAFT/policies) with Kuma's CRDs applied via `kubectl`.
:::

### Last but not least

Once the `kuma-cp` process is started, it waits for [data-planes](#dps-and-data-model) to connect, while at the same time accepting user-defined configuration to start creating Service Meshes and configuring the behavior of those meshes via Kuma [Policies](/docs/DRAFT/policies).

When we look at a typical Kuma installation, at a higher level it works like this:

<center>
<img src="/images/docs/0.2.0/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

When we unpack the underlying behavior, it looks like this:

<center>
<img src="/images/docs/0.2.0/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**xDS APIs**: Kuma implements the [xDS](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/v2_overview) APIs of Envoy in the `kuma-cp` application so that the Envoy DPs can connect to it and retrieve their configuration.
:::

## Backends

As explained in the [Overview](#overview), when Kuma (`kuma-cp`) is up and running it needs to store data somewhere. The data will include the state, the policies configured, the data-planes status, and so on.

Kuma supports a few different backends that we can use when running `kuma-cp`. You can configure the backend storage by setting the `KUMA_STORE_TYPE` environment variable when running the control plane.

::: tip
This information has been documented for clarity, but when following the [installation instructions](/install/DRAFT) these settings will be automatically configured.
:::

The backends are:

- `memory` (**default**): Kuma stores all the state in-memory. This means that restarting Kuma will delete all the data. Only reccomend when playing with Kuma locally. For example:

```sh
$ KUMA_STORE_TYPE=memory kuma-cp run
```

This is the **default** memory store if `KUMA_STORE_TYPE` is not being specified.

- `postgres`: Kuma stores all the state in a PostgreSQL database. Used when running in Universal mode. You can also use a remote PostgreSQL database offered by any cloud vendor. For example:

```sh
$ KUMA_STORE_TYPE=postgres \
  KUMA_STORE_POSTGRES_HOST=localhost \
  KUMA_STORE_POSTGRES_PORT=5432 \
  KUMA_STORE_POSTGRES_USER=kuma-user \
  KUMA_STORE_POSTGRES_PASSWORD=kuma-password \
  KUMA_STORE_POSTGRES_DB_NAME=kuma \
  kuma-cp run
```

- `kubernetes`: Kuma stores all the state in the underlying Kubernetes cluster. User when running in Kubernetes mode. For example:

```sh
$ KUMA_STORE_TYPE=kubernetes kuma-cp run
```

## Dependencies

Kuma (`kuma-cp`) is one single executable written in GoLang that can be installed anywhere, hence why it's both universal and simple to deploy.

- Running on **Kubernetes**: No external dependencies required, since it leverages the underlying K8s API server to store its configuration. A `kuma-injector` service will also start in order to automatically inject sidecar data-plane proxies without human intervention.

- Running on **Universal**: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any managed PostgreSQL offering as well, like AWS RDS or Aurora. Out of sight, out of mind!

Out of the box, Kuma ships with a bundled [Envoy](https://www.envoyproxy.io/) data-plane ready to use for our services, so that you don't have to worry about putting all the pieces together.

::: tip
Kuma ships with an executable `kuma-dp` that will execute the bundled `envoy` executable in order to execute the data-plane proxy. The behavior of the data-plane executable is being explained in the [Overview](#overview).
:::

[Install Kuma](/install/DRAFT) and follow the instructions to get up and running in a few steps.

## DPs and Data Model

When Kuma (`kuma-cp`) runs, it will be waiting for the data-planes to connect and register themselves. In order for a data-plane to successfully run, two things have to happen before being executed:

- There must exist at least one [`Mesh`](/docs/DRAFT/policies/#mesh) in Kuma. By default the system auto-generates a `default` Mesh when the control-plane is run for the first time.
- There must exist a [`Dataplane`](#dataplane-entity) entity in Kuma **before** the actual data-plane tries to connect to it via `kuma-dp`.

<center>
<img src="/images/docs/0.2.0/diagram-10.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
On Universal the [`Dataplane`](#dataplane-entity) entity must be **manually** created before starting `kuma-dp`, on Kubernetes it is **automatically** created.
:::

### Dataplane Entity

A `Dataplane` entity must be created on the CP `kuma-cp` before a `kuma-dp` instance attempts to connect to the control-plane. On Kubernetes, this operation is fully **automated**. On Universal, it must be executed **manually**.

To understand why the `Dataplane` entity is required, we must take a step back. As we have explained already, Kuma follow a sidecar proxy model for the data-planes, where we have an instance of a data-plane for every instance of our services. Each Service and DP will communicate with each other on the same machine, therefore on `127.0.0.1`.

For example, if we have 6 replicas of a "Redis" service, then we must have one instances of `kuma-dp` running alongside each replica of the service, therefore 6 replicas of `kuma-dp` as well.

<center>
<img src="/images/docs/0.2.0/diagram-11.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**Many DPs!** The number of data-planes that we have running can quickly add up, since we have one replica of `kuma-dp` for every replica of every service. That's why it's important for the DP process to be lightweight and consume a few resources, otherwise we would quickly run out of memory, especially on platforms like Kubernetes where multiple services are running on the same underlying host machine. And that's one of the reasons why Kuma leverages Envoy for this task.
:::

When we start a new data-plane in Kuma, **two things** have to happen:

1. The data-plane needs to advertise what service it is responsible for. This is what the `Dataplane` entity does.
2. The data-plane process needs to start accepting incoming and outgoing requests.

These steps are being executed in **two separate** commands:

1. We register the `Dataplane` object via the `kumactl` or HTTP API.
2. Once we have registered the DP, we can start it by running `kuma-dp run`.

::: tip
**Remember**: this is all automated if you are running Kuma on Kubernetes!
:::

The registration of the `Dataplane` includes two main sections that are described below in the [Dataplane Specification](#dataplane-specification):

- `inbound` networking configuration, to configure on what port the DP will listen to accept external requests, specify on what port the service is listening on the same machine (for internal DP <> Service communication), and the [Tags](#tags) that belong to the service.
- `outbound` networking configuration, to enable the local service to consume other services.

For example, this is how we register a `Dataplane` for an hypotetical Redis service and then start the `kuma-dp` process:

```sh
echo "type: Dataplane
mesh: default
name: redis-1
networking:
  inbound:
  - interface: 127.0.0.1:9000:6379
    tags:
      service: redis" | kumactl apply -f -

kuma-dp run \
  --name=redis-1 \
  --mesh=default \
  --cp-address=http://127.0.0.1:5681 \
  --dataplane-token-file=/tmp/kuma-dp-redis-1-token
```

In the example above, any external client who wants to consume Redis will have to make a request to the DP on port `9000`, which internally will be redirected to the Redis service listening on port `6379`.

Now let's assume that we have another service called "Backend" that internally listens on port `80`, and that makes outgoing requests to the `redis` service:

```sh
echo "type: Dataplane
mesh: default
name: backend-1
networking:
  inbound:
  - interface: 127.0.0.1:8000:80
    tags:
      service: backend
  outbound:
  - interface: :10000
    service: redis" | kumactl apply -f -

kuma-dp run \
  --name=backend-1 \
  --mesh=default \
  --cp-address=http://127.0.0.1:5681 \
  --dataplane-token-file=/tmp/kuma-dp-backend-1-token
```

In order for the `backend` service to successfully consume `redis`, we specify an `outbound` networking section in the `Dataplane` configuration instructing the DP to listen on a new port `10000` and to proxy any outgoing request on port `10000` to the `redis` service. For this to work, we must update our application to consume `redis` on `127.0.0.1:10000`.

::: tip
As mentioned before, this is only required in Universal. In Kubernetes no change to our applications are required thanks to automated transparent proxying.
:::

### Envoy

`kuma-dp` is built on top of `Envoy`, which has a powerful [Admin API](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) that enables monitoring and troubleshooting of a running dataplane.

By default, `kuma-dp` starts `Envoy Admin API` on the loopback interface (that is only accessible from the local host) and the first available port from the range `30001-65535`.

If you need to override that behaviour, you can use `--admin-port` command-line option or `KUMA_DATAPLANE_ADMIN_PORT` environment variable.

E.g.,

* you can change the default port range by using `--admin-port=10000-20000`
* you can narrow it down to a single port by using `--admin-port=9901`
* you can turn `Envoy Admin API` off by using `--admin-port=`

::: warning
If you choose to turn `Envoy Admin API` off, you will not be able to leverage some of `Kuma` features, such as enabling `Prometheus` metrics on that dataplane.
:::

### Tags

A data-plane can have many labels that define its role within your architecture. It is obviously associated to a service, but can also have some other properties that we might want to define. For example, if it runs in a specific world region, or a specific cloud vendor. In Kuma these labels are called `tags` and they are being set in the [`Dataplane`](#dataplane-entity) entity.

::: tip
There is one special tag, the `service` tag, that must always be set.
:::

Tags are important because can be used later on by any [Policy](/docs/DRAFT/policies) that Kuma supports now and in the future. For example, it will be possible to route requests from one region to another assuming there is a `region` tag associated to the data-planes.

### Dataplane Specification

The [`Dataplane`](#dataplane-entity) entity includes the networking and naming configuration that a data-plane proxy (`kuma-dp`) must have attempting to connect to the control-plane (`kuma-cp`).

In Universal mode we must manually create the [`Dataplane`](#dataplane-entity) entity before running `kuma-dp`. A [`Dataplane`](#dataplane-entity) entity can be created with [`kumactl`](#kumactl) or by using the [HTTP API](#http-api). When using [`kumactl`](#kumactl), the normal entity definition will look like:

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  inbound:
    - interface: 127.0.0.1:11011:11012
      tags:
        service: backend
  outbound:
    - interface: :33033
      service: redis
```
And the [`Gateway mode`](#gateway)'s entity definition will look like:
```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  gateway:
    tags:
      service: kong
  outbound:
  - interface: :33033
    service: backend
```

The `Dataplane` entity includes a few sections:

* `type`: must be `Dataplane`.
* `mesh`: the `Mesh` name we want to associate the data-plane with.
* `name`: this is the name of the data-plane instance, and it must be **unique** for any given `Mesh`. We might have multiple instances of a Service, and therefore multiple instances of the sidecar data-plane proxy. Each one of those sidecar proxy instances must have a unique `name`.
* `networking`: this is the meaty part of the configuration. It determines the behavior of the data-plane on incoming (`inbound`) and outgoing (`outbound`) requests.
  * `inbound`: an array of `interface` objects that determines what services are being exposed via the data-plane. Each `interface` object only supports one port at a time, and you can specify more than one `interface` in case the service opens up more than one port.
    * `interface`: determines the routing logic for incoming requests in the format of `{address}:{dataplane-port}:{service-port}`.
    * `tags`: each data-plane can include any arbitrary number of tags, with the only requirement that `service` is **mandatory** and it identifies the name of service. You can include tags like `version`, `cloud`, `region`, and so on to give more attributes to the `Dataplane` (attributes that can later on be used to apply policies).
  * `gateway`: determines if the data-plane will operate in Gateway mode. It replaces the `inbound` object and enables Kuma to integrate with existing API gateways like [Kong](https://github.com/Kong/kong). 
    * `tags`: each data-plane can include any arbitrary number of tags, with the only requirement that `service` is **mandatory** and it identifies the name of service. You can include tags like `version`, `cloud`, `region`, and so on to give more attributes to the `Dataplane` (attributes that can later on be used to apply policies).
  * `outbound`: every outgoing request made by the service must also go thorugh the DP. This object specifies ports that the DP will have to listen to when accepting outgoing requests by the service: 
    * `interface`: the address inclusive of the port that the service needs to consume locally to make a request to the external service
    * `service`: the name of the service associated with the interface.

::: tip
On Kubernetes this whole process is automated via transparent proxying and without changing your application's code. On Universal Kuma doesn't support transparent proxying yet, and the outbound service dependencies have to be manually specified in the [`Dataplane`](#dataplane-entity) entity. This also means that in Universal **you must update** your codebases to consume those external services on `127.0.0.1` on the port specified in the `outbound` section.
:::

### Kubernetes

On Kubernetes the data-planes are automatically injected via the `kuma-injector` executable as long as the K8s Namespace includes the following label:

```
kuma.io/sidecar-injection: enabled
```

On Kubernetes the [`Dataplane`](#dataplane-entity) entity is also automatically created for you, and because transparent proxying is being used to communicate between the service and the sidecar proxy, no code changes are required in your applications.

### Gateway

The `Dataplane` can operate in Gateway mode. This way you can integrate Kuma with existing API Gateways like [Kong](https://github.com/Kong/kong).

When you use a Dataplane with a service, both inbound traffic to a service and outbound traffic from the service flows through the Dataplane.
API Gateway should be deployed as any other service withing the mesh. However, in this case we want inbound traffic to go directly to API Gateway,
otherwise clients would have to be provided with certificates that are generated dynamically for communication between services within the mesh.
Security for an entrance to the mesh should be handled by API Gateway itself.

Gateway mode lets you skip exposing inbound listeners so it won't be intercepting ingress traffic.

#### Universal

On Universal, you can define such Dataplane like this:

```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  gateway:
    tags:
      service: kong
  outbound:
  - interface: :33033
    service: backend
```

When configuring your API Gateway to pass traffic to _backend_ set the url to `http://localhost:33033` 

#### Kubernetes

On Kubernetes, `Dataplane` entities are automatically generated. To inject gateway Dataplane, mark your API Gateway's Pod with `kuma.io/gateway: enabled` annotation. Here is example with Kong for Kubernetes:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ingress-kong
  name: ingress-kong
  namespace: kong
spec:
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
    spec:
      containers:
        image: kong:1.3
      ...
```

::: tip
When integrating [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller) with Kuma you have to annotate every `Service` that you want to pass traffic to with [`ingress.kubernetes.io/service-upstream=true`](https://github.com/Kong/kubernetes-ingress-controller/blob/master/docs/references/annotations.md#ingresskubernetesioservice-upstream) annotation.
Otherwise Kong will do the load balancing which unables Kuma to do the load balancing and apply policies. 
:::

## CLI

Kuma ships in a bundle that includes a few executables:

- `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
- `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
- `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
- `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
- `kuma-prometheus-sd`: this is a helper tool that enables native integration between `Kuma` and `Prometheus`. Thanks to it, `Prometheus` will be able to automatically find all dataplanes in your Mesh and scrape metrics out of them.
- `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

According to the [installation instructions](/install/DRAFT), some of these executables are automatically executed as part of the installation workflow, while some other times you will have to execute them directly.

You can check the usage of the executables by running the `-h` flag, like:

```sh
$ kuma-cp -h
```

and you can check their version by running the `version [--detailed]` command like:

```sh
$ kuma-cp version --detailed
```

## kumactl

The `kumactl` executable is a very important component in your journey with Kuma. It allows to:

- Retrieve the state of Kuma and the configured [policies](/docs/DRAFT/policies) in every environment.
- On **Universal** environments, it allows to change the state of Kuma by applying new policies with the `kumactl apply [..]` command.
- On **Kubernetes** it is **read-only**, because you are supposed to change the state of Kuma by leveraging Kuma's CRDs.
- It provides helpers to install Kuma on Kubernetes, and to configure the PostgreSQL schema on Universal (`kumactl install [..]`).

::: tip
The `kumactl` application is a CLI client for the underlying [HTTP API](#http-api) of Kuma. Therefore, you can access the state of Kuma by leveraging with the API directly. On Universal you will be able to also make changes via the HTTP API, while on Kubernetes the HTTP API is read-only.
:::

Available commands on `kumactl` are:

- `kumactl install [..]`: provides helpers to install Kuma in Kubernetes, or to configure the PostgreSQL database on Universal.
- `kumactl config [..]`: configures the local or remote control-planes that `kumactl` should talk to. You can have more than one enabled, and the configuration will be stored in `~/.kumactl/config`.
- `kumactl apply [..]`: used to change the state of Kuma. Only available on Universal.
- `kumactl get [..]`: used to retrieve the raw state of entities Kuma.
- `kumactl inspect [..]`: used to retrieve an augmented state of entities in Kuma.
- `kumactl generate dataplane-token`: used to generate [Dataplane Token](#dataplane-token).
- `kumactl generate tls-certificate`: used to generate a TLS certificate for client or server.
- `kumactl manage ca [..]`: used to manage certificate authorities.
- `kumactl help [..]`: help dialog that explains the commands available.
- `kumactl version [--detailed]`: shows the version of the program.

## GUI

Kuma now ships with a basic web-based GUI that will serve as a visual overview of your dataplanes, meshes, and various traffic policies.

::: tip
The GUI pairs with the HTTP API — Read more about the HTTP API [here](#http-api)
:::

When launching Kuma, the GUI will start by default on port `:5683`. You can access it in your web browser by going to `http://localhost:5683/`.

### Getting Started

When you run the GUI for the first time, you’ll be presented with the Wizard:

<center>
<img src="/images/docs/0.3.2/gui-wizard-step-1.png" alt="A screenshot of the first step of the Kuma GUI Wizard" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

#### This tool will:

1. Confirm that Kuma is running
2. Determine if your environment is either Universal or Kubernetes
3. Provide instructions on how to add dataplanes (if none have yet been added). The instructions provided will be based on your Kuma environment -- Universal or Kubernetes
4. Provide a short list of dataplanes found and their status (online or offline), in order to confirm that things are working accordingly and the app can display information

### Mesh Overview

Once you’ve completed the setup process, you’ll be sent to the Mesh Overview. This is a general overview of all of the meshes found. You can then view each entity and see how many dataplanes and traffic permissions, routes, and logs are associated with that mesh.

<center>
<img src="/images/docs/0.3.2/gui-mesh-overview.png" alt="A screenshot of the Mesh Overview of the Kuma GUI" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Mesh Details

If you want to view information regarding a specific mesh, you can select the desired mesh from the pulldown at the top of the sidebar. You can then click on any of the overviews in the sidebar to view the entities and policies associated with that mesh.

::: tip
If you haven't yet created any meshes, this will default to the `default` mesh.
:::

Each of these views will provide you with a table that displays helpful at-a-glance information. The Dataplanes table will display helpful information, including whether or not a dataplane is online, when it was last connected, how many connections it has, etc. This view also provides a control for refreshing your data on the fly without having to do a full page reload each time you've made changes:

<center>
<img src="/images/docs/0.3.2/gui-dataplanes-table.png" alt="A screenshot of the Dataplanes information table" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

We also provide an easy way to view your entity in YAML format, as well as an control to copy it to your clipboard:

<center>
<img src="/images/docs/0.3.2/gui-yaml-to-clipboard.png" alt="A screenshot of the YAML to clipboard feature in the Kuma GUI" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

### What’s to come

The GUI will eventually serve as a hub to view various metrics, such as latency and number of requests (total and per entity). We will also have charts and other visual tools for measuring and monitoring performance.

## HTTP API

Kuma ships with a RESTful HTTP interface that you can use to retrieve the state of your configuration and policies on every environment, and when running on Universal mode it will also allow to make changes to the state. On Kubernetes, you will use native CRDs to change the state in order to be consistent with Kubernetes best practices.

::: tip
**CI/CD**: The HTTP API can be used for infrastructure automation to either retrieve data, or to make changes when running in Universal mode. The [`kumactl`](#kumactl) CLI is built on top of the HTTP API, which you can also access with any other HTTP client like `curl`.
:::

By default the HTTP API is listening on port `5681`. The endpoints available are:

- `/config`
- `/meshes`
- `/meshes/{name}`
- `/meshes/{name}/dataplanes`
- `/meshes/{name}/dataplanes/{name}`
- `/meshes/{name}/dataplanes+insights`
- `/meshes/{name}/dataplanes+insights/{name}`
- `/meshes/{name}/health-checks`
- `/meshes/{name}/health-checks/{name}`
- `/meshes/{name}/proxytemplates`
- `/meshes/{name}/proxytemplates/{name}`
- `/meshes/{name}/traffic-logs`
- `/meshes/{name}/traffic-logs/{name}`
- `/meshes/{name}/traffic-permissions`
- `/meshes/{name}/traffic-permissions/{name}`
- `/meshes/{name}/traffic-routes`
- `/meshes/{name}/traffic-routes/{name}`

You can use `GET` requests to retrieve the state of Kuma on both Universal and Kubernetes, and `PUT` and `DELETE` requests on Universal to change the state.

### Control Plane configuration

#### Get effective configuration of the Control Plane

Request: `GET /config`

Response: `200 OK` with the effective configuration of the Control Plane (notice that secrets, such as database passwords, will never appear in the response)

Example:

```bash
curl http://localhost:5681/config
```

```json
{
  "adminServer": {
    "apis": {
      "dataplaneToken": {
        "enabled": true
      }
    },
    "local": {
      "port": 5679
    },
    "public": {
      "clientCertsDir": "/etc/kuma.io/kuma-cp/admin-api/tls/allowed-client-certs.d",
      "enabled": true,
      "interface": "0.0.0.0",
      "port": 5684,
      "tlsCertFile": "/etc/kuma.io/kuma-cp/admin-api/tls/server.cert",
      "tlsKeyFile": "/etc/kuma.io/kuma-cp/admin-api/tls/server.key"
    }
  },
  "apiServer": {
    "corsAllowedDomains": [".*"],
    "port": 5681,
    "readOnly": false
  },
  "bootstrapServer": {
    "params": {
      "adminAccessLogPath": "/dev/null",
      "adminAddress": "127.0.0.1",
      "adminPort": 0,
      "xdsConnectTimeout": "1s",
      "xdsHost": "kuma-control-plane.internal",
      "xdsPort": 5678
    },
    "port": 5682
  },
  "dataplaneTokenServer": {
    "enabled": true,
    "local": {
      "port": 5679
    },
    "public": {
      "clientCertsDir": "/etc/kuma.io/kuma-cp/admin-api/tls/allowed-client-certs.d",
      "enabled": true,
      "interface": "0.0.0.0",
      "port": 5684,
      "tlsCertFile": "/etc/kuma.io/kuma-cp/admin-api/tls/server.cert",
      "tlsKeyFile": "/etc/kuma.io/kuma-cp/admin-api/tls/server.key"
    }
  },
  "defaults": {
    "mesh": "type: Mesh\nname: default\nmtls:\n  ca: {}\n  enabled: false\n"
  },
  "discovery": {
    "universal": {
      "pollingInterval": "1s"
    }
  },
  "environment": "universal",
  "general": {
    "advertisedHostname": "kuma-control-plane.internal"
  },
  "guiServer": {
    "port": 5683
  },
  "monitoringAssignmentServer": {
    "assignmentRefreshInterval": "1s",
    "grpcPort": 5676
  },
  "reports": {
    "enabled": true
  },
  "runtime": {
    "kubernetes": {
      "admissionServer": {
        "address": "",
        "certDir": "",
        "port": 5443
      }
    }
  },
  "sdsServer": {
    "grpcPort": 5677,
    "tlsCertFile": "/tmp/117637813.crt",
    "tlsKeyFile": "/tmp/240596112.key"
  },
  "store": {
    "kubernetes": {
      "systemNamespace": "kuma-system"
    },
    "postgres": {
      "connectionTimeout": 5,
      "dbName": "kuma",
      "host": "127.0.0.1",
      "password": "*****",
      "port": 15432,
      "user": "kuma"
    },
    "type": "memory"
  },
  "xdsServer": {
    "dataplaneConfigurationRefreshInterval": "1s",
    "dataplaneStatusFlushInterval": "1s",
    "diagnosticsPort": 5680,
    "grpcPort": 5678
  }
}
```

### Meshes

#### Get Mesh

Request: `GET /meshes/{name}`

Response: `200 OK` with Mesh entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1
```

```json
{
  "name": "mesh-1",
  "type": "Mesh",
  "mtls": {
    "ca": {
      "builtin": {}
    },
    "enabled": true
  },
  "tracing": {},
  "logging": {
    "backends": [
      {
        "name": "file-tmp",
        "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
        "file": {
          "path": "/tmp/access.log"
        }
      },
      {
        "name": "logstash",
        "tcp": {
          "address": "logstash.internal:9000"
        }
      }
    ]
  }
}
```

#### Create/Update Mesh

Request: `PUT /meshes/{name}` with Mesh entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1 --data @mesh.json -H'content-type: application/json'
```

```json
{
  "name": "mesh-1",
  "type": "Mesh",
  "mtls": {
    "ca": {
      "builtin": {}
    },
    "enabled": true
  },
  "tracing": {},
  "logging": {
    "backends": [
      {
        "name": "file-tmp",
        "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
        "file": {
          "path": "/tmp/access.log"
        }
      },
      {
        "name": "logstash",
        "tcp": {
          "address": "logstash.internal:9000"
        }
      }
    ]
  }
}
```

#### List Meshes

Request: `GET /meshes`

Response: `200 OK` with body of Mesh entities

Example:

```bash
curl http://localhost:5681/meshes
```

```json
{
  "items": [
    {
      "type": "Mesh",
      "name": "mesh-1",
      "mtls": {
        "ca": {
          "builtin": {}
        },
        "enabled": true
      },
      "tracing": {},
      "logging": {
        "backends": [
          {
            "name": "file-tmp",
            "format": "{ \"destination\": \"%KUMA_DESTINATION_SERVICE%\", \"destinationAddress\": \"%UPSTREAM_LOCAL_ADDRESS%\", \"source\": \"%KUMA_SOURCE_SERVICE%\", \"sourceAddress\": \"%KUMA_SOURCE_ADDRESS%\", \"bytesReceived\": \"%BYTES_RECEIVED%\", \"bytesSent\": \"%BYTES_SENT%\"}",
            "file": {
              "path": "/tmp/access.log"
            }
          },
          {
            "name": "logstash",
            "tcp": {
              "address": "logstash.internal:9000"
            }
          }
        ]
      }
    }
  ]
}
```

#### Delete Mesh

Request: `DELETE /meshes/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1
```

### Dataplanes

#### Get Dataplane

Request: `GET /meshes/{mesh}/dataplanes/{name}`

Response: `200 OK` with Mesh entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/dataplanes/backend-1
```

```json
{
  "type": "Dataplane",
  "name": "backend-1",
  "mesh": "mesh-1",
  "networking": {
    "inbound": [
      {
        "interface": "127.0.0.1:11011:11012",
        "tags": {
          "service": "backend",
          "version": "2.0",
          "env": "production"
        }
      }
    ],
    "outbound": [
      {
        "interface": ":33033",
        "service": "database"
      },
      {
        "interface": ":44044",
        "service": "user"
      }
    ]
  }
}
```

#### Create/Update Dataplane

Request: `PUT /meshes/{mesh}/dataplanes/{name}` with Dataplane entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/dataplanes/backend-1 --data @dataplane.json -H'content-type: application/json'
```

```json
{
  "type": "Dataplane",
  "name": "backend-1",
  "mesh": "mesh-1",
  "networking": {
    "inbound": [
      {
        "interface": "127.0.0.1:11011:11012",
        "tags": {
          "service": "backend",
          "version": "2.0",
          "env": "production"
        }
      }
    ],
    "outbound": [
      {
        "interface": ":33033",
        "service": "database"
      },
      {
        "interface": ":44044",
        "service": "user"
      }
    ]
  }
}
```

#### List Dataplanes

Request: `GET /meshes/{mesh}/dataplanes`

Response: `200 OK` with body of Dataplane entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/dataplanes
```

```json
{
  "items": [
    {
      "type": "Dataplane",
      "name": "backend-1",
      "mesh": "mesh-1",
      "networking": {
        "inbound": [
          {
            "interface": "127.0.0.1:11011:11012",
            "tags": {
              "service": "backend",
              "version": "2.0",
              "env": "production"
            }
          }
        ],
        "outbound": [
          {
            "interface": ":33033",
            "service": "database"
          },
          {
            "interface": ":44044",
            "service": "user"
          }
        ]
      }
    }
  ]
}
```

#### Delete Dataplane

Request: `DELETE /meshes/{mesh}/dataplanes/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/dataplanes/backend-1
```

### Dataplane Overviews

#### Get Dataplane Overview

Request: `GET /meshes/{mesh}/dataplane+insights/{name}`

Response: `200 OK` with Dataplane entity including insight

Example:

```bash
curl http://localhost:5681/meshes/default/dataplanes+insights/example
```

```json
{
  "type": "DataplaneOverview",
  "mesh": "default",
  "name": "example",
  "dataplane": {
    "networking": {
      "inbound": [
        {
          "interface": "127.0.0.1:11011:11012",
          "tags": {
            "env": "production",
            "service": "backend",
            "version": "2.0"
          }
        }
      ],
      "outbound": [
        {
          "interface": ":33033",
          "service": "database"
        }
      ]
    }
  },
  "dataplaneInsight": {
    "subscriptions": [
      {
        "id": "426fe0d8-f667-11e9-b081-acde48001122",
        "controlPlaneInstanceId": "06070748-f667-11e9-b081-acde48001122",
        "connectTime": "2019-10-24T14:04:56.820350Z",
        "status": {
          "lastUpdateTime": "2019-10-24T14:04:57.832482Z",
          "total": {
            "responsesSent": "3",
            "responsesAcknowledged": "3"
          },
          "cds": {
            "responsesSent": "1",
            "responsesAcknowledged": "1"
          },
          "eds": {
            "responsesSent": "1",
            "responsesAcknowledged": "1"
          },
          "lds": {
            "responsesSent": "1",
            "responsesAcknowledged": "1"
          },
          "rds": {}
        }
      }
    ]
  }
}
```

#### List Dataplane Overviews

Request: `GET /meshes/{mesh}/dataplane+insights/`

Response: `200 OK` with Dataplane entities including insight

Example:

```bash
curl http://localhost:5681/meshes/default/dataplanes+insights
```

```json
{
  "items": [
    {
      "type": "DataplaneOverview",
      "mesh": "default",
      "name": "example",
      "dataplane": {
        "networking": {
          "inbound": [
            {
              "interface": "127.0.0.1:11011:11012",
              "tags": {
                "env": "production",
                "service": "backend",
                "version": "2.0"
              }
            }
          ],
          "outbound": [
            {
              "interface": ":33033",
              "service": "database"
            }
          ]
        }
      },
      "dataplaneInsight": {
        "subscriptions": [
          {
            "id": "426fe0d8-f667-11e9-b081-acde48001122",
            "controlPlaneInstanceId": "06070748-f667-11e9-b081-acde48001122",
            "connectTime": "2019-10-24T14:04:56.820350Z",
            "status": {
              "lastUpdateTime": "2019-10-24T14:04:57.832482Z",
              "total": {
                "responsesSent": "3",
                "responsesAcknowledged": "3"
              },
              "cds": {
                "responsesSent": "1",
                "responsesAcknowledged": "1"
              },
              "eds": {
                "responsesSent": "1",
                "responsesAcknowledged": "1"
              },
              "lds": {
                "responsesSent": "1",
                "responsesAcknowledged": "1"
              },
              "rds": {}
            }
          }
        ]
      }
    }
  ]
}
```

### Health Check

#### Get Health Check

Request: `GET /meshes/{mesh}/health-checks/{name}`

Response: `200 OK` with Health Check entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/health-checks/web-to-backend
```

```json
{
  "conf": {
    "activeChecks": {
      "interval": "10s",
      "timeout": "2s",
      "unhealthyThreshold": 3,
      "healthyThreshold": 1
    }
  },
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "mesh": "mesh-1",
  "name": "web-to-backend",
  "sources": [
    {
      "match": {
        "service": "web"
      }
    }
  ],
  "type": "HealthCheck"
}
```

#### Create/Update Health Check

Request: `PUT /meshes/{mesh}/health-checks/{name}` with Health Check entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/health-checks/web-to-backend --data @healthcheck.json -H'content-type: application/json'
```

```json
{
  "type": "HealthCheck",
  "mesh": "mesh-1",
  "name": "web-to-backend",
  "sources": [
    {
      "match": {
        "service": "web"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "conf": {
    "activeChecks": {
      "interval": "10s",
      "timeout": "2s",
      "unhealthyThreshold": 3,
      "healthyThreshold": 1
    }
  }
}
```

#### List Health Checks

Request: `GET /meshes/{mesh}/health-checks`

Response: `200 OK` with body of Health Check entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/health-checks
```

```json
{
  "items": [
    {
      "conf": {
        "activeChecks": {
          "interval": "10s",
          "timeout": "2s",
          "unhealthyThreshold": 3,
          "healthyThreshold": 1
        }
      },
      "destinations": [
        {
          "match": {
            "service": "backend"
          }
        }
      ],
      "mesh": "mesh-1",
      "name": "web-to-backend",
      "sources": [
        {
          "match": {
            "service": "web"
          }
        }
      ],
      "type": "HealthCheck"
    }
  ]
}
```

#### Delete Health Check

Request: `DELETE /meshes/{mesh}/health-checks/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/health-checks/web-to-backend
```

### Proxy Template

#### Get Proxy Template

Request: `GET /meshes/{mesh}/proxytemplates/{name}`

Response: `200 OK` with Proxy Template entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1
```

```json
{
  "conf": {
    "imports": ["default-proxy"],
    "resources": [
      {
        "name": "raw-name",
        "version": "raw-version",
        "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
      }
    ]
  },
  "mesh": "mesh-1",
  "name": "pt-1",
  "selectors": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "type": "ProxyTemplate"
}
```

#### Create/Update Proxy Template

Request: `PUT /meshes/{mesh}/proxytemplates/{name}` with Proxy Template entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1 --data @proxytemplate.json -H'content-type: application/json'
```

```json
{
  "type": "ProxyTemplate",
  "name": "pt-1",
  "mesh": "mesh-1",
  "selectors": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "conf": {
    "imports": ["default-proxy"],
    "resources": [
      {
        "name": "raw-name",
        "version": "raw-version",
        "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
      }
    ]
  }
}
```

#### List Proxy Templates

Request: `GET /meshes/{mesh}/proxytemplates`

Response: `200 OK` with body of Proxy Template entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/proxytemplates
```

```json
{
  "items": [
    {
      "conf": {
        "imports": ["default-proxy"],
        "resources": [
          {
            "name": "raw-name",
            "version": "raw-version",
            "resource": "'@type': type.googleapis.com/envoy.api.v2.Cluster\nconnectTimeout: 5s\nloadAssignment:\n  clusterName: localhost:8443\n  endpoints:\n    - lbEndpoints:\n        - endpoint:\n            address:\n              socketAddress:\n                address: 127.0.0.1\n                portValue: 8443\nname: localhost:8443\ntype: STATIC\n"
          }
        ]
      },
      "mesh": "mesh-1",
      "name": "pt-1",
      "selectors": [
        {
          "match": {
            "service": "backend"
          }
        }
      ],
      "type": "ProxyTemplate"
    }
  ]
}
```

#### Delete Proxy Template

Request: `DELETE /meshes/{mesh}/proxytemplates/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/proxytemplates/pt-1
```

### Traffic Permission

#### Get Traffic Permission

Request: `GET /meshes/{mesh}/traffic-permissions/{name}`

Response: `200 OK` with Traffic Permission entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-permissions/tp-1
```

```json
{
  "destinations": [
    {
      "match": {
        "service": "redis"
      }
    }
  ],
  "mesh": "mesh-1",
  "name": "tp-1",
  "sources": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "type": "TrafficPermission"
}
```

#### Create/Update Traffic Permission

Request: `PUT /meshes/{mesh}/trafficpermissions/{name}` with Traffic Permission entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-permissions/tp-1 --data @trafficpermission.json -H'content-type: application/json'
```

```json
{
  "type": "TrafficPermission",
  "name": "tp-1",
  "mesh": "mesh-1",
  "sources": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "redis"
      }
    }
  ]
}
```

#### List Traffic Permissions

Request: `GET /meshes/{mesh}/traffic-permissions`

Response: `200 OK` with body of Traffic Permission entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-permissions
```

```json
{
  "items": [
    {
      "destinations": [
        {
          "match": {
            "service": "redis"
          }
        }
      ],
      "mesh": "mesh-1",
      "name": "tp-1",
      "sources": [
        {
          "match": {
            "service": "backend"
          }
        }
      ],
      "type": "TrafficPermission"
    }
  ]
}
```

#### Delete Traffic Permission

Request: `DELETE /meshes/{mesh}/traffic-permissions/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-permissions/pt-1
```

### Traffic Log

#### Get Traffic Log

Request: `GET /meshes/{mesh}/traffic-logs/{name}`

Response: `200 OK` with Traffic Log entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1
```

```json
{
  "conf": {
    "backend": "file"
  },
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "mesh": "mesh-1",
  "name": "tl-1",
  "sources": [
    {
      "match": {
        "service": "web",
        "version": "1.0"
      }
    }
  ],
  "type": "TrafficLog"
}
```

#### Create/Update Traffic Log

Request: `PUT /meshes/{mesh}/traffic-logs/{name}` with Traffic Log entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1 --data @trafficlog.json -H'content-type: application/json'
```

```json
{
  "type": "TrafficLog",
  "mesh": "mesh-1",
  "name": "tl-1",
  "sources": [
    {
      "match": {
        "service": "web",
        "version": "1.0"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "conf": {
    "backend": "file"
  }
}
```

#### List Traffic Logs

Request: `GET /meshes/{mesh}/traffic-logs`

Response: `200 OK` with body of Traffic Log entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-logs
```

```json
{
  "items": [
    {
      "conf": {
        "backend": "file"
      },
      "destinations": [
        {
          "match": {
            "service": "backend"
          }
        }
      ],
      "mesh": "mesh-1",
      "name": "tl-1",
      "sources": [
        {
          "match": {
            "service": "web",
            "version": "1.0"
          }
        }
      ],
      "type": "TrafficLog"
    }
  ]
}
```

#### Delete Traffic Log

Request: `DELETE /meshes/{mesh}/traffic-logs/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-logs/tl-1
```

### Traffic Route

#### Get Traffic Route

Request: `GET /meshes/{mesh}/traffic-routes/{name}`

Response: `200 OK` with Traffic Route entity

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend
```

```json
{
  "conf": [
    {
      "weight": 90,
      "destination": {
        "region": "us-east-1",
        "service": "backend",
        "version": "v2"
      }
    },
    {
      "weight": 10,
      "destination": {
        "service": "backend",
        "version": "v3"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "mesh": "mesh-1",
  "name": "web-to-backend",
  "sources": [
    {
      "match": {
        "region": "us-east-1",
        "service": "web",
        "version": "v10"
      }
    }
  ],
  "type": "TrafficRoute"
}
```

#### Create/Update Traffic Route

Request: `PUT /meshes/{mesh}/traffic-routes/{name}` with Traffic Route entity in body

Response: `201 Created` when the resource is created and `200 OK` when it is updated

Example:

```bash
curl -XPUT http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend --data @trafficroute.json -H'content-type: application/json'
```

```json
{
  "type": "TrafficRoute",
  "name": "web-to-backend",
  "mesh": "mesh-1",
  "sources": [
    {
      "match": {
        "region": "us-east-1",
        "service": "web",
        "version": "v10"
      }
    }
  ],
  "destinations": [
    {
      "match": {
        "service": "backend"
      }
    }
  ],
  "conf": [
    {
      "weight": 90,
      "destination": {
        "region": "us-east-1",
        "service": "backend",
        "version": "v2"
      }
    },
    {
      "weight": 10,
      "destination": {
        "service": "backend",
        "version": "v3"
      }
    }
  ]
}
```

#### List Traffic Routes

Request: `GET /meshes/{mesh}/traffic-routes`

Response: `200 OK` with body of Traffic Route entities

Example:

```bash
curl http://localhost:5681/meshes/mesh-1/traffic-routes
```

```json
{
  "items": [
    {
      "conf": [
        {
          "weight": 90,
          "destination": {
            "region": "us-east-1",
            "service": "backend",
            "version": "v2"
          }
        },
        {
          "weight": 10,
          "destination": {
            "service": "backend",
            "version": "v3"
          }
        }
      ],
      "destinations": [
        {
          "match": {
            "service": "backend"
          }
        }
      ],
      "mesh": "mesh-1",
      "name": "web-to-backend",
      "sources": [
        {
          "match": {
            "region": "us-east-1",
            "service": "web",
            "version": "v10"
          }
        }
      ],
      "type": "TrafficRoute"
    }
  ]
}
```

#### Delete Traffic Route

Request: `DELETE /meshes/{mesh}/traffic-routes/{name}`

Response: `200 OK`

Example:

```bash
curl -XDELETE http://localhost:5681/meshes/mesh-1/traffic-routes/web-to-backend
```

::: tip
The [`kumactl`](/kumactl) CLI under the hood makes HTTP requests to this API.
:::

## Security

Kuma helps you secure your existing infrastructure with mTLS. The following sections cover details of how it works.

### Certificates

Kuma uses a built-in CA (Certificate Authority) to issue certificates for dataplanes. The root CA certificate is unique for each mesh
in the system. On Kubernetes, the root CA certificate is stored as a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/).
On Universal, we leverage the same storage (Postgres) that is used for storing policies.
Certificates for dataplanes are ephemeral, re-created on dataplane restart and never persisted on disk.

Dataplane certificates generated by Kuma are X.509 certificates that are [SPIFFE](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md) compliant. The SAN of certificate is set to `spiffe://<mesh name>/<service name>`

Kuma also supports external CA. By changing the `ca` in the mesh resource to `provided`, you can use a CA of your choice.

```yaml
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    provided: {}
```

To manage external CAs after you update the mesh resource, `kumactl` now supports a new command: `kumactl manage ca`. With this new command, you can do add and delete certificates.

### Dataplane Token

In order to obtain an mTLS certificate from the server ([SDS](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) built-in in the control plane), a dataplane must prove it's identity.

#### Kubernetes

On Kubernetes, a dataplane proves its identity by leveraging [ServiceAccountToken](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#service-account-automation) that is mounted in every pod.

#### Universal

On Universal, a dataplane must be explicitly configured with a unique security token (Dataplane Token) that will be used to prove its identity.
Dataplane Token is a signed [JWT token](https://jwt.io) that the carries dataplane name and name of the mesh it's allowed to join to.
It is signed by an RSA key auto-generated by the control plane on first run. Tokens are not stored in the control plane,
the only thing that is stored is a signing key that is used to verify if a token is valid.

You can generate token either by REST API

```bash
curl -XPOST http://localhost:5679/tokens --data '{"name:" "dp-echo-1", "mesh": "default"}'
```

or by using `kumactl`

```bash
kumactl generate dataplane-token --name=dp-echo-1 --mesh=default > /tmp/kuma-dp-echo1-token
```

The token should be stored in a file and then used when starting `kuma-dp`

```bash
$ kuma-dp run \
  --name=dp-echo-1 \
  --mesh=default \
  --cp-address=http://127.0.0.1:5681 \
  --dataplane-token-file=/tmp/kuma-dp-echo-1-token
```

##### Accessing Admin Server from a different machine

By default, the Admin Server that is serving Dataplane Tokens is exposed only on localhost. If you want to generate tokens from a different machine than control plane you have to secure the connection:

1. Enable public server by setting `KUMA_ADMIN_SERVER_PUBLIC_ENABLED` to `true`. Make sure to specify hostname which can be used to access Kuma from other machine via `KUMA_GENERAL_ADVERTISED_HOSTNAME`.
2. Generate certificate for the HTTPS Admin Server and set via `KUMA_ADMIN_SERVER_PUBLIC_TLS_CERT_FILE` and `KUMA_ADMIN_SERVER_PUBLIC_TLS_KEY_FILE` config environment variable.
   For generating self signed certificate you can use `kumactl`

```bash
$ kumactl generate tls-certificate --cert-file=/path/to/cert --key-file=/path/to/key --type=server --cp-hostname=<name from KUMA_GENERAL_ADVERTISED_HOSTNAME>
```

3. Pick a public interface on which HTTPS server will be exposed and set it via `KUMA_ADMIN_SERVER_PUBLIC_INTERFACE`.
   Optionally pick the port via `KUMA_ADMIN_SERVER_PUBLIC_PORT`. By default, it will be the same as the port for the HTTP server exposed on localhost.
4. Generate one or more certificates for the clients of this server. Pass the path to the directory with client certificates (without keys) via `KUMA_ADMIN_SERVER_PUBLIC_CLIENT_CERTS_DIR`.
   For generating self signed client certificates you can use `kumactl`

```bash
$ kumactl generate tls-certificate --cert-file=/path/to/cert --key-file=/path/to/key --type=client
```

5. Configure `kumactl` with client certificate.

```bash
$ kumactl config control-planes add \
  --name <NAME> --address http://<KUMA_CP_DNS_NAME>:5681 \
  --admin-client-cert <CERT.PEM> \
  --admin-client-key <KEY.PEM>
```

### mTLS

Once a dataplane has proved its identity, it will be allowed to fetch its own identity certificate and a root CA certificate of the mesh.
When establishing a connection between two dataplanes each side validates each other dataplane certificate confirming the identity using the root CA of the mesh.

mTLS is _not_ enabled by default. To enable it, apply proper settings in [Mesh](/docs/DRAFT/policies/#mesh) policy.
Additionaly, when running on Universal you have to ensure that every dataplane in the mesh has been configured with a Dataplane Token.

#### TrafficPermission

When mTLS is enabled, every connection between dataplanes is denied by default, so you have to explicitly allow it using [TrafficPermission](/docs/DRAFT/policies/#traffic-permissions).

### Postgres

Since on Universal, the secrets such as "provided" CA's private key, are stored in Postgres, a connection between Postgres and Kuma CP should be secured with TLS.
To secure the connection, first pick the security mode using `KUMA_STORE_POSTGRES_TLS_MODE`. There are several modes:

- `disable` - is not secured with TLS (secrets will be transmitted over network in plain text).
- `verifyNone` - the connection is secured but neither hostname, nor by which CA the certificate is signed is checked.
- `verifyCa` - the connection is secured and the certificate presented by the server is verified using the provided CA.
- `verifyFull` - the connection is secured, certificate presented by the server is verified using the provided CA and server hostname must match the one in the certificate.

The CA for verification server's certificate can be set using `KUMA_STORE_POSTGRES_TLS_CA_PATH`.

Once secured connections are configured in Kuma CP, you have to configure Postgres' [`pg_hba.conf`](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html) file to restrict unsecured connections.
Here is an example configuration that will allow only TLS connections and will require username and password:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
hostssl all             all             0.0.0.0/0               password
```

You can also provide client key and certificate for mTLS using `KUMA_STORE_POSTGRES_TLS_CERT_PATH` and `KUMA_STORE_POSTGRES_TLS_KEY_PATH`.
This pair can be used for auth-method `cert` described [here](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html).

## Ports

When `kuma-cp` starts up, by default it listens on a few ports:

- `5676`: the Monitoring Assignment server that responds to discovery requests from monitoring tools, such as `Prometheus`, that are looking for a list of targets to scrape metrics from, e.g. a list of all dataplanes in the mesh.
- `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
- `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
- `5679`: the Admin Server that serves Dataplane Tokens and manages Provided Certificate Authority
- `5680`: the HTTP server that returns the health status of the control-plane.
- `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when runnning in `universal` - that you can use to apply new policies.
- `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.
- `5683`: the HTTP server that exposes Kuma UI.

## Quickstart

The getting started for Kuma can be found in the [installation page](/install/DRAFT) where you can follow the instructions to get up and running with Kuma.

If you need help, you can chat with the [Community](/community) where you can ask questions, contribute back to Kuma and send feedback.
