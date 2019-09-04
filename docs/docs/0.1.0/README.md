# Welcome to Kuma

::: tip
**Protip**: Use `#kumamesh` on Twitter to chat about Kuma.
:::

Welcome to the official documentation for Kuma! 

Here you will find all you need to know about the product. While Kuma is ideal for Service Mesh and Microservices, you will soon realize that it can be used to modernize any architecture. That's why we call it *Universal Control Plane*.

## What is Kuma?

Kuma is a universal open-source control plane for Service Mesh and Microservices that can run natively across both Kubernetes and VM environments, in order to be easily adopted by every team in the organization. 

Built on top of Envoy, Kuma can instrument any L4/L7 traffic to secure, observe, route and enhance connectivity between any service or database. It can be used natively in Kubernetes via CRDs or via a RESTful API across other environments, and it doesn't require to change our application's code in order to be used.

While being simple to use for most use-cases, Kuma also provides policies to configure the underlying Envoy data-planes in a more fine grained way, therefore catering to both first time user of Service Mesh, as well as most experienced ones.

TODO: IMAGE DIAGRAM

Built by Kong with feedback from 150+ enterprise organizations running Service Mesh in production, Kuma implements a pragmatic approach that is very different from the 1st generation control planes: it runs with low operational overhead across all the organization, it supports every platform, and it's easy to use while relying on a solid networking foundation delivered by Envoy.

Built by Envoy contributors at Kong 🦍.

::: tip
**Need help?** Don't forget to check the [Community](/community) section! 
:::

## Why Kuma?

When building any software architecture inevitably we will introduce services that will communicate with each other by making requests on the network. 

For example, think of any application that communicates with a database to store or retrieve data, or think of a more complex microservice-oriented application that makes many requests across different services to execute its operations:

TODO: IMAGE DIAGRAM

Every time our services connect to each other via a network request we put the end-user experience at risk. As we all know the connectivity between different services can be slow and unpredictable, it can be unsecure, and it can be hard to trace, among the other problems (routing, versioning, canary deployments, and so on).

Usually at this point developers take one of the following actions to remedy the situation:

* **Write more code**: A *smart* client is being built that every service will have to utilize in the form of a library. Usually this approach introduces a few problems: it creates more technical debt, it is usually language-specific therefore it prevents innovation, or multiple implementations of the library exist which creates fragmentation in the long run.

* **Sidecar proxy**: The services delegate all the connectivity and observability concerns to an out-of-process runtime, that will be on the execution path of every request. It will proxy all the outgoing connections and accept all the incoming ones. By using this approach developers don't worry about connectivity and only focus on delivering business value from their services.

Kuma implements the sidecar proxy model, and it leverages Envoy as its dataplane technology.

::: tip
**Sidecar Proxy** It's called *sidecar* proxy because it's another process running alongside our service on the same host, like a motorcycle sidecar.
:::

TODO: IMAGE DIAGRAM





## Technology

Kuma is built on GoLang, and it is a control plane that can be installed anywhere.

## Dependencies

Kuma is one single executable that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on **Kubernetes**: No dependencies required, since it leverages the underlying K8s API server to store its configuration.

* Running on **Linux**: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any managed PostgreSQL offering as well, like AWS RDS or Aurora. Out of sight, out of mind!

Out of the box, Kuma ships with a bundled Envoy data-plane ready to use for our services, so that you don't have to worry about putting all the pieces together.

[Install Kuma](/install) and follow the instructions to get up and running in a few steps.

## Technology



## Concepts



## Where to go from here?

You are a few minutes away from being able to run Kuma and build your first Service Mesh! This documentation can help you into understanding the basic concepts and getting up and running quickly.

You can explore the following areas as a next step:

* Dependencies, Concepts and Architecture
* Quickstart: Getting up and running

# Dependencies

Kuma is one single executable that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on Kubernetes: No dependencies required, since it leverages the underlying K8s API server to store its configuration.

* Running on Linux: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any Postgres-As-A-Service offering as well, like AWS RDS or Aurora.

Out of the box, Kuma ships with a bundled Envoy data-plane ready to use for our services, so that you don't have to worry about putting pieces together.

# Service Mesh for everybody

Until now service mesh has been considered to be the last step of architecture modernization after transitioning to containers and perhaps to Kubernetes. This approach is completely backwards, since it makes the adoption and the business value of service mesh available only after implementing other massive transformations that - in the meanwhile - can go wrong.

In reality, we want service mesh to be available *before* we implement other transitions so that we can keep the network both secure and observable in the process. With Kuma, service mesh is indeed the **first step** towards modernization.

Unlike other control planes, Kuma natively runs across any platform and it's not limited in scope (ie, Kubernetes only). Kuma works on both existing brownfield applications (those apps that deliver business value today), as well as new modern greenfield applications that will be the future of our journey.

Unlike other control planes, Kuma is easy to use. Anybody - from any team - can implement Kuma in three simple steps across both traditional monolithic applications and modern microservices.

Finally, by leveraging out of the box policies and Kuma's powerful tagging selectors, we can implement all sort of behaviors when it comes to both simple and complex topologies, like multi-cloud and multi-region architectures.










## Code block example

``` bash
$ curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=example-service'
  --data 'url=http://example.com'
$ curl -i -X POST \
  --url http://localhost:8001/services/example-service/routes/
  --data 'hosts=[]=example.com' \
```

## Include example 
Included markdown partials are relative to the `/docs/.partials/` directory.

!!!include(api-reference.md)!!!

!!!include(architectural-diagrams.md)!!!