# Documentation

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

It's time to start using Kuma and build your Service Mesh. In this section you will find the technical material to get up and running 🚀. 

If you haven't read the first [Welcome to Kuma](/docs) section, we strongly suggest to start from here.

## Overview

As we have [already learned](/docs), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

The first step is obviously to [download and install Kuma](/install) on the platform of your choice. Different distributions will present different installation instructions that follow the best practices for the platform you have selected.

Regardless of what platform you decide to use, the fundamental behavior of Kuma at runtime will not change across different distributions. These fundamentals are important to explore in order to understand what Kuma is and how it works.

::: tip
Installing Kuma on Kubernetes is fully automated, while installing Kuma on Linux requires the user to run the Kuma executables. Both ways are very simple, and can be explored from the [installation page](/install).
:::

There are two main components of Kuma that are very important to understand:

* **Control-Plane**: Kuma is first and foremost a control-plane that will accept user input (you are the user) in order to create and configure [Policies](#policies) like Service Meshes, and in order to add services and configure their behavior within the Meshes you have created.
* **Data-Plane**: Kuma also bundles a data-plane implementation based on top of [Envoy](https://www.envoyproxy.io/) for convenience, in order to get up and running quickly.

::: tip
**Multi-Mesh**: Kuma ships with multi-tenancy support since day one. This means you can create and configure multiple isolated Service Meshes from **one** control-plane. By doing so we lower the complexity and the operational cost of supporting multiple meshes. [Explore Kuma's Policies](#policies).
:::

Since Kuma bundles a data-plane in addition to the control-plane, we decided to call the executables `kuma-cp` and `kuma-dp` to differentiate them. Let's take a look at all the executables that ship with Kuma:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-injector`: only for Kubernetes, this is a process that listens to events propagated by Kubernetes, and that automatically injects a `kuma-dp` sidecar container to our services.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data-planes (`kuma-dp`) which will connect to the control-plane as soon as they startup. Kuma supports two modes:

* `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
* `kubernetes`: when it's being deployed - well - on Kubernetes.

### Universal mode

When running in **Universal** mode, Kuma will require a PostgreSQL database to store its state. Unlike `kubernetes` mode, Kuma won't require the `kuma-injector` executable to run:

TODO: IMAGE

### Kubernetes mode

When running on **Kubernetes**, Kuma will store all of its state and configuration on the underlying Kubernetes API Server, therefore requiring no dependency to store the data. But it requires the `kuma-injector` executable to run in a Pod so that it can automatically inject `kuma-dp` on any POD that includes the following label: `ENTER LABEL`:

TODO: IMAGE

Once the `kuma-cp` process is started, it waits for data-planes to connect, while at the same time accepting user-defined configuration to start creating Service Meshes and configuring the behavior of those meshes via Kuma [Policies](#policies).

### Last but not least

When we look at a typical Kuma installation, at a higher level it works like this:

<center>
<img src="/images/docs/0.1.0/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

When we unpack the underlying behavior, it looks like this:

<center>
<img src="/images/docs/0.1.0/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Quickstart

## CLI

## Backend Storage

## Ports

## 

* Talk about the CLI and how to start everything and CLI elements

* Talk about supported backends for storage
	* memory
	* postgres
	* kubernetes

* Talk about the ports that are opened by kuma-cp and what services are associated with (link to API reference for the HTTP API)

* Talk about a;



### Running locally


### Running on Linux

### Running on Kubernetes



Getting up and running with Kuma is very simple. The following tutorial demonstrates the steps that have to be executed in order to run a Kuma cluster.

The first step is downloading the software

## Concepts

## Dependencies

Kuma is one single executable that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on **Kubernetes**: No dependencies required, since it leverages the underlying K8s API server to store its configuration.

* Running on **Linux**: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any managed PostgreSQL offering as well, like AWS RDS or Aurora. Out of sight, out of mind!

Out of the box, Kuma ships with a bundled Envoy data-plane ready to use for our services, so that you don't have to worry about putting all the pieces together.

[Install Kuma](/install) and follow the instructions to get up and running in a few steps.

## Policies

## Roadmap