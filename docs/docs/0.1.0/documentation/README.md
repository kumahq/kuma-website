# Documentation

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

It's time to start using Kuma and build your Service Mesh. In this section you will find the technical material to get up and running 🚀. 

If you haven't read the first [Welcome to Kuma](/docs) section, we strongly suggest to start from here.

## Overview

As we have [already learned](/docs), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

Kuma natively supports and implements the xDS APIs of Envoy, so that we can use Kuma to configure and orchestrate as many Envoy-based data planes as we want pretty much across the entire organization.

TODO: Kuma <> xDS DIAGRAM

Kuma can runs in two modes:

* `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
* `kubernetes`: when it's being deployed - well - on Kubernetes.


Once the Kuma process is started, it operationally performs three main duties:

* **Accepting user-defined configuration**: Provide a way for the user (that's you) to configure the functionalities of the Service Mesh powered by Kuma by creating and accepting [policies](#policies). This happens via CRDs on Kubernetes, or via an HTTP RESTful API 
* **Registering data-planes**: Provide an xDS compatible API that the Envoy-based dataplanes will utilize to register themsleves to Kuma, and that Kuma will utilize to identify the services behind the data-planes.
* **Configuring data-planes**: Utilize the user-provided configuration stored in Kuma to automatically generate at runtime the proper low-level Envoy configuration for each data-plane connected to Kuma.

Every Kuma installation is made of one or more instances of Kuma that connect to any number of Envoy data planes deployed as sidecar proxies alongside our services.

TODO: DIAGRAM




At its core, the way Kuma works is straightforward and it can be explained as follows.











When downloading Kuma, you will notice several executables in the archive:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data plane executables that, under the hood, invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-injector`: this is a process that listens for new K8s pods and automatically injects `kuma-dp`.

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