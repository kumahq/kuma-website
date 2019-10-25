# Documentation

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

It's time to start using Kuma and build your Service Mesh. In this section you will find the technical material to get up and running 🚀. 

If you haven't read the first [Welcome to Kuma](/docs/%%VER%%) section, we strongly suggest to start from here.

## Overview

As we have [already learned](/docs/%%VER%%), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

The first step is obviously to [download and install Kuma](/install/%%VER%%) on the platform of your choice. Different distributions will present different installation instructions that follow the best practices for the platform you have selected.

Regardless of what platform you decide to use, the fundamental behavior of Kuma at runtime will not change across different distributions. These fundamentals are important to explore in order to understand what Kuma is and how it works.

::: tip
Installing Kuma on Kubernetes is fully automated, while installing Kuma on Linux requires the user to run the Kuma executables. Both ways are very simple, and can be explored from the [installation page](/install/%%VER%%).
:::

There are two main components of Kuma that are very important to understand:

* **Control-Plane**: Kuma is first and foremost a control-plane that will accept user input (you are the user) in order to create and configure [Policies](/docs/%%VER%%/policies) like [Service Meshes](/docs/%%VER%%/policies/#mesh), and in order to add services and configure their behavior within the Meshes you have created.
* **Data-Plane**: Kuma also bundles a data-plane implementation based on top of [Envoy](https://www.envoyproxy.io/) for convenience, in order to get up and running quickly. An instance of the data-plane will run alongside every instance of our services, and it will process both incoming and outgoing requests for the service.

::: tip
**Multi-Mesh**: Kuma ships with multi-tenancy support since day one. This means you can create and configure multiple isolated Service Meshes from **one** control-plane. By doing so we lower the complexity and the operational cost of supporting multiple meshes. [Explore Kuma's Policies](/docs/%%VER%%/policies).
:::

Since Kuma bundles a data-plane in addition to the control-plane, we decided to call the executables `kuma-cp` and `kuma-dp` to differentiate them. Let's take a look at all the executables that ship with Kuma:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

In addition to these binaries, there is another binary that will be executed when running on Kubernetes:

* `kuma-injector`: only for Kubernetes, this is a process that listens to events propagated by Kubernetes, and that automatically injects a `kuma-dp` sidecar container to our services.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data-planes (`kuma-dp`) which will connect to the control-plane as soon as they startup. Kuma supports two modes:

* `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
* `kubernetes`: when it's being deployed - well - on Kubernetes.

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
**Full CRD support**: When using Kuma in Kubernetes mode you can create [Policies](/docs/%%VER%%/policies) with Kuma's CRDs applied via `kubectl`.
:::

### Last but not least

Once the `kuma-cp` process is started, it waits for [data-planes](#dps-and-data-model) to connect, while at the same time accepting user-defined configuration to start creating Service Meshes and configuring the behavior of those meshes via Kuma [Policies](/docs/%%VER%%/policies).

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
This information has been documented for clarity, but when following the [installation instructions](/install/%%VER%%) these settings will be automatically configured.
:::

The backends are:

* `memory` (**default**): Kuma stores all the state in-memory. This means that restarting Kuma will delete all the data. Only reccomend when playing with Kuma locally. For example:

```sh
$ KUMA_STORE_TYPE=memory kuma-cp run
```

This is the **default** memory store if `KUMA_STORE_TYPE` is not being specified.

* `postgres`: Kuma stores all the state in a PostgreSQL database. Used when running in Universal mode. You can also use a remote PostgreSQL database offered by any cloud vendor. For example:

```sh
$ KUMA_STORE_TYPE=postgres \
  KUMA_STORE_POSTGRES_HOST=localhost \
  KUMA_STORE_POSTGRES_PORT=5432 \
  KUMA_STORE_POSTGRES_USER=kuma-user \
  KUMA_STORE_POSTGRES_PASSWORD=kuma-password \
  KUMA_STORE_POSTGRES_DB_NAME=kuma \
  kuma-cp run
```

* `kubernetes`: Kuma stores all the state in the underlying Kubernetes cluster. User when running in Kubernetes mode. For example:

```sh
$ KUMA_STORE_TYPE=kubernetes kuma-cp run
```

## Dependencies

Kuma (`kuma-cp`) is one single executable written in GoLang that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on **Kubernetes**: No external dependencies required, since it leverages the underlying K8s API server to store its configuration. A `kuma-injector` service will also start in order to automatically inject sidecar data-plane proxies without human intervention.

* Running on **Universal**: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any managed PostgreSQL offering as well, like AWS RDS or Aurora. Out of sight, out of mind!

Out of the box, Kuma ships with a bundled [Envoy](https://www.envoyproxy.io/) data-plane ready to use for our services, so that you don't have to worry about putting all the pieces together.

::: tip
Kuma ships with an executable `kuma-dp` that will execute the bundled `envoy` executable in order to execute the data-plane proxy. The behavior of the data-plane executable is being explained in the [Overview](#overview).
:::

[Install Kuma](/install/%%VER%%) and follow the instructions to get up and running in a few steps.

## DPs and Data Model

When Kuma (`kuma-cp`) runs, it will be waiting for the data-planes to connect and register themselves. In order for a data-plane to successfully run, two things have to happen before being executed:

* There must exist at least one [`Mesh`](/docs/%%VER%%/policies/#mesh) in Kuma. By default the system auto-generates a `default` Mesh when the control-plane is run for the first time.
* There must exist a [`Dataplane`](#dataplane-entity) entity in Kuma **before** the actual data-plane tries to connect to it via `kuma-dp`.

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

* `inbound` networking configuration, to configure on what port the DP will listen to accept external requests, specify on what port the service is listening on the same machine (for internal DP <> Service communication), and the [Tags](#tags) that belong to the service. 
* `outbound` networking configuration, to enable the local service to consume other services.

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

KUMA_CONTROL_PLANE_BOOTSTRAP_SERVER_URL=http://control-plane:5682 \
KUMA_DATAPLANE_MESH=default \
KUMA_DATAPLANE_NAME=redis-1 \
kuma-dp run
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

KUMA_CONTROL_PLANE_BOOTSTRAP_SERVER_URL=http://control-plane:5682 \
KUMA_DATAPLANE_MESH=default \
KUMA_DATAPLANE_NAME=backend-1 \
kuma-dp run
```

In order for the `backend` service to successfully consume `redis`, we specify an `outbound` networking section in the `Dataplane` configuration instructing the DP to listen on a new port `10000` and to proxy any outgoing request on port `10000` to the `redis` service. For this to work, we must update our application to consume `redis` on `127.0.0.1:10000`.

::: tip
As mentioned before, this is only required in Universal. In Kubernetes no change to our applications are required thanks to automated transparent proxying.
:::

### Envoy

Since `kuma-dp` is built on top of Envoy, you can enable the [Envoy HTTP API](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) by starting `kuma-dp` with an additional `KUMA_DATAPLANE_ADMIN_PORT=9901` environment variable (or by setting the `--admin-port=9901` argument). This can be very useful for debugging purposes.

### Tags

A data-plane can have many labels that define its role within your architecture. It is obviously associated to a service, but can also have some other properties that we might want to define. For example, if it runs in a specific world region, or a specific cloud vendor. In Kuma these labels are called `tags` and they are being set in the [`Dataplane`](#dataplane-entity) entity.

::: tip
There is one special tag, the `service` tag, that must always be set.
:::

Tags are important because can be used later on by any [Policy](/docs/%%VER%%/policies) that Kuma supports now and in the future. For example, it will be possible to route requests from one region to another assuming there is a `region` tag associated to the data-planes.

### Dataplane Specification

The [`Dataplane`](#dataplane-entity) entity includes the networking and naming configuration that a data-plane proxy (`kuma-dp`) must have attempting to connect to the control-plane (`kuma-cp`).

In Universal mode we must manually create the [`Dataplane`](#dataplane-entity) entity before running `kuma-dp`. A [`Dataplane`](#dataplane-entity) entity can be created with [`kumactl`](#kumactl) or by using the [HTTP API](#http-api). When using [`kumactl`](#kumactl), the entity definition will look like:

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

The `Dataplane` entity includes a few sections:

* `type`: must be `Dataplane`.
* `mesh`: the `Mesh` name we want to associate the data-plane with.
* `name`: this is the name of the data-plane instance, and it must be **unique** for any given `Mesh`. We might have multiple instances of a Service, and therefore multiple instances of the sidecar data-plane proxy. Each one of those sidecar proxy instances must have a unique `name`.
* `networking`: this is the meaty part of the configuration. It determines the behavior of the data-plane on incoming (`inbound`) and outgoing (`outbound`) requests.
  * `inbound`: an array of `interface` objects that determines what services are being exposed via the data-plane. Each `interface` object only supports one port at a time, and you can specify more than one `interface` in case the service opens up more than one port.
    * `interface`: determines the routing logic for incoming requests in the format of `{address}:{dataplane-port}:{service-port}`.
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

## CLI

Kuma ships in a bundle that includes a few executables:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

According to the [installation instructions](/install/%%VER%%), some of these executables are automatically executed as part of the installation workflow, while some other times you will have to execute them directly.

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

* Retrieve the state of Kuma and the configured [policies](/docs/%%VER%%/policies) in every environment.
* On **Universal** environments, it allows to change the state of Kuma by applying new policies with the `kumactl apply [..]` command.
* On **Kubernetes** it is **read-only**, because you are supposed to change the state of Kuma by leveraging Kuma's CRDs.
* It provides helpers to install Kuma on Kubernetes, and to configure the PostgreSQL schema on Universal (`kumactl install [..]`).

::: tip
The `kumactl` application is a CLI client for the underlying [HTTP API](#http-api) of Kuma. Therefore, you can access the state of Kuma by leveraging with the API directly. On Universal you will be able to also make changes via the HTTP API, while on Kubernetes the HTTP API is read-only.
:::

Available commands on `kumactl` are:

* `kumactl install [..]`: provides helpers to install Kuma in Kubernetes, or to configure the PostgreSQL database on Universal.
* `kumactl config [..]`: configures the local or remote control-planes that `kumactl` should talk to. You can have more than one enabled, and the configuration will be stored in `~/.kumactl/config`.
* `kumactl apply [..]`: used to change the state of Kuma. Only available on Universal.
* `kumactl get [..]`: used to retrieve the raw state of entities Kuma.
* `kumactl inspect [..]`: used to retrieve an augmented state of entities in Kuma.
* `kumactl help [..]`: help dialog that explains the commands available.
* `kumactl version [--detailed]`: shows the version of the program.

## HTTP API

Kuma ships with a RESTful HTTP interface that you can use to retrieve the state of your configuration and policies on every environment, and when running on Universal mode it will also allow to make changes to the state. On Kubernetes, you will use native CRDs to change the state in order to be consistent with Kubernetes best practices.

::: tip
**CI/CD**: The HTTP API can be used for infrastructure automation to either retrieve data, or to make changes when running in Universal mode. The [`kumactl`](#kumactl) CLI is built on top of the HTTP API, which you can also access with any other HTTP client like `curl`.
:::

By default the HTTP API is listening on port `5681`. The endpoints available are:

* `/meshes`
* `/meshes/{name}`
* `/meshes/{name}/dataplanes`
* `/meshes/{name}/dataplanes/{name}`

You can use `GET` requests to retrieve the state of Kuma on both Universal and Kubernetes, and `PUT` and `DELETE` requests on Universal to change the state.

::: tip
The [`kumactl`](/kumactl) CLI under the hood makes HTTP requests to this API.
:::

## Ports

When `kuma-cp` starts up, by default it listens on a few ports:

* `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
* `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
* `5680`: the HTTP server that returns the health status of the control-plane.
* `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when runnning in `universal` - that you can use to apply new policies.
* `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.

## Quickstart

The getting started for Kuma can be found in the [installation page](/install/%%VER%%) where you can follow the instructions to get up and running with Kuma.

If you need help, you can chat with the [Community](/community) where you can ask questions, contribute back to Kuma and send feedback.
