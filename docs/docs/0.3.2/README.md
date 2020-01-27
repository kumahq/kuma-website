---
title: Overview
---

# Welcome to Kuma

::: tip
**Protip**: Use `#kumamesh` on Twitter to chat about Kuma, and join the official [Kuma Slack](/community)!
:::

Welcome to the official documentation for Kuma, a modern **Control Plane** with bundled Envoy integration. 

Here you will find all you need to know about the product. While Kuma is ideal for Service Mesh and Microservices, you will soon realize that it can be used to implement modern service connectivity across any architecture.

The core maintainer of Kuma is **Kong**, the maker of the popular open-source Kong Gateway 🦍.

The word "Kuma" means "bear" in Japanese (クマ).

## What is Kuma?

Kuma is a platform agnostic open-source control plane for Service Mesh and Microservices. It can run and be operated natively across both Kubernetes and VM environments, making it easy to adopt by every team in the organization.

Bundling [Envoy](https://envoyproxy.io/) as a data-plane, Kuma can instrument any L4/L7 traffic to secure, observe, route and enhance connectivity between any service or database. It can be used natively in Kubernetes via CRDs or via a RESTful API across other environments like VMs and Bare Metal.

While being simple to use for most use-cases, Kuma also provides policies to configure the underlying Envoy data-planes in a more fine-grained manner. By doing so, Kuma can be used by both first-time users of Service Mesh, as well as the most experienced ones.

<center>
<img src="/images/docs/0.2.0/diagram-01.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Kong built Kuma with feedback from 100+ enterprise organizations running Service Mesh in production. As such, Kuma implements a pragmatic approach that is very different from other control plane implementations:  

- **Universal**: Kuma runs on every platform, including Kubernetes and VMs.
- **Simple**: To deploy and to use, Kuma provides easy to use policies for various use-cases.
- **Envoy-based**: Kuma is built on top of Envoy, the most adopted proxy for Service Mesh.

::: tip
**Need help?** Don't forget to check the [Community](/community) section! 
:::

## What is Service Mesh?

Service Mesh is a technology pattern that implements a better way to implement modern networking and connectivity among the different services that make up an application. While it is commonly used in the context of microservices, it can be used to improve connectivity among every architecture and on every platform like VMs and containers.

::: tip
**Reliable service connectivity** is a pre-requisite for every modern digital application. Transitioning to microservices - and to the Cloud - can be disastrous if network connectivity is not taken care of, and this is exactly why Kuma was built.
:::

When a service wants to communicate to another service over the network - like a monolith talking to a database or a microservices talking to another microservice - by default the connectivity among them is unreliable: the network can be slow, it is unsecure by default, and by default of those network requests are not being logged anywhere in case we need to debug an error.

In order to implement some of these functionalities, we have two options:

* We extend our applications ourselves in order to address these concerns. Over time this creates technical debt, and yet more code to maintain in addition to the business logic that our application is delivering to the end-user. It also creates fragmentation and security issues as more teams try to address the same concerns on different technology stacks.
* We delegate the network management to something else that does it for us. Like - for instance - an out-of-process proxy that runs on the same underlying host. Sure, we have to deal with a slightly increased latency between our services and the local proxy, but the benefits are so high that it quickly becomes irrelevant. This proxy - as we will learn later - is called *sidecar proxy* and sits on the data plane of our requests.

In the latter scenario - when delegating network management to another process - we are going to be having a data plane proxy for each replica of every service. This is required so we can tolerate a failure to one of the proxies without affecting other replicas, and also because we can assign an identity to each proxy and therefore to each replica of our services. It is also important that the data plane proxy is very lightweight since we are going to be having many instances running.

While having data planes deployed alongside our services helps with the network concerns we have described earlier, it introduces a new problem: managing so many data planes becomes challenging, and when we want to update our network policies we certainly don't want to manually reconfigure each one of them. In short, we need a source of truth that can collect all of our configuration - segmented by service or other properties - and then push the configuration to the individual data planes whenever required. This component is called the control plane: it controls the data planes and - unlike the data planes - it doesn't sit on the execution path of the service traffic.

<center>
<img src="/images/docs/0.3.2/diagram-14.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

We are going to be having many data planes connected to the control plane in order to always propagate the latest configuration, while simultaneously processing the service-to-service traffic among our infrastructure. Kuma is a control plane (and it is being shipped in a `kuma-cp` binary) while Envoy is a data plane proxy (shipped as an `envoy` binary). When using Kuma we don't have to worry about learning to use Envoy, because Kuma abstracts away that complexity by bundling Envoy into another binary called `kuma-dp` (`kuma-dp` under the hood will invoke the `envoy` binary but that complexity is hidden from you, the end user of Kuma).

Service Mesh does not introduce new concerns or use-cases: it addresses a concern that we are already taking care of (usually by writing more code, if we are doing anything at all): dealing with the connectivity in our network. 

As we will learn, Kuma takes care of these concerns so that we don't have to worry about the network, and in turn making our applications more reliable.

## Why Kuma?

When building any modern digital application, we will inevitably introduce services that will communicate with each other by making requests on the network. 

For example, think of any application that communicates with a database to store or retrieve data, or think of a more complex microservice-oriented application that makes many requests across different services to execute its operations:

<center>
<img src="/images/docs/0.2.0/diagram-02.jpg" alt="" style="width: 550px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Every time our services communicate over the network, we put the end-user experience at risk. As we all know the network between different services can be slow and unpredictable. It can be insecure, hard to trace, and pose many other problems (e.g., routing, versioning, canary deployments). In one sentence, our applications are one step away from being unreliable.

Usually, at this point, developers take one of the following actions to remedy the situation:

* **Write more code**: Developers write code - sometimes in the form of a *smart* client - that every service will have to utilize when making requests to another service. Usually, this approach introduces a few problems: 
  - It creates more technical debt
  - It is typically language-specific; therefore, it prevents innovation 
  - Multiple implementations of the library exist, which creates fragmentation in the long run.

* **Sidecar proxy**: The services delegate all the connectivity and observability concerns to an out-of-process runtime, that will be on the execution path of every request. It will proxy all the outgoing connections and accept all the incoming ones. And of course it will execute traffic policies at runtime, like routing or logging. By using this approach, developers don't have to worry about connectivity and focus entirely on their services and applications.

::: tip
**Sidecar Proxy**: It's called *sidecar* proxy because the proxy it's another process running alongside our service process on the same underlying host. There is going to be one instance of a sidecar proxy for each running instance of our services, and because all the incoming and outgoing requests - and their data - always go through the sidecar proxy, it is also called a data-plane (DP) since it sits on the data path.
:::

Since we are going to be having many instances for our services, we are also going to be having an equal number of sidecar proxies: that's a lot of proxies! Therefore the sidecar proxy model **requires** a control plane that allows a team to configure the behavior of the proxies dynamically without having to manually configure them. The data planes will initiate a connection with the control plane in order to receive new configuration, while the control plane will - at runtime - provide them with the most updated configuration.

Teams that adopt the sidecar proxy model will either build a control plane from scratch or use existing general-purpose control planes available on the market, such as Kuma. [Compare Kuma with other CPs](#kuma-vs-xyz).

Unlike a data-plane proxy (DP), the control-plane (CP) is never on the execution path of the requests that the services exchange with each other, and it's being used as a source of truth to dynamically configure the underlying data-plane proxies that in the meanwhile ha.

<center>
<img src="/images/docs/0.2.0/diagram-03.jpg" alt="" style="width: 550px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**Service Mesh**: An architecture made of sidecar proxies deployed next to our services (the data-planes, or DPs), and a control plane (CP) controlling those DPs, is called Service Mesh. Usually, Service Mesh appears in the context of Kubernetes, but anybody can build Service Meshes on any platform (including VMs and Bare Metal).
:::

With Kuma, our main goal is to reduce the code that has to be written and maintained to build reliable architectures. Therefore, Kuma embraces the sidecar proxy model by leveraging Envoy as its sidecar data-plane technology.

By outsourcing all the connectivity, security, and routing concerns to a sidecar proxy, we benefit from our enhanced ability to: 
- build applications faster
- focus on the core functionality of our services to drive more business
- build a more secure and standardized architecture by reducing fragmentation

By reducing the code that our teams create and maintain, we can modernize our applications piece by piece without ever needing to bite more than we can chew.

<center>
<img src="/images/docs/0.2.0/diagram-04.jpg" alt="" style=" padding-top: 20px; padding-bottom: 10px;"/>
</center>

[Learn more](#enabling-modernization) about how Kuma enables modernization within our existing architectures.

## Kuma vs XYZ

When Service Mesh first became mainstream around 2017, a few control planes were released by small and large organizations in other to support the first implementations of this new architectural pattern.

These control planes captured a lot of enthusiasm in the early days, but they all lacked pragmatism into creating a viable journey to Service Mesh adoption within existing organizations. These 1st generation solutions are:

* **Greenfield-only**: Hyper-focused on new greenfield applications, without providing a journey to modernize existing workloads running on VM and Bare Metal platforms where the current business runs today, in addition to Kubernetes.
* **Complicated to use**: Service Mesh doesn't have to be complicated, but early implementations were hard to use; they had poor documentation and no clear upgrade path to mitigate breaking changes.
* **Hard to deploy**: Many moving parts, which need to be running optimally at the same time, makes it harder to run and scale a Service Mesh due to the side-effect of higher operational costs.
* **For hobbyists, not organizations**: Lack of understanding of the challenges enterprise organizations face today, with poor support and implementation models.

Kuma exists today to provide a pragmatic journey to implementing Service Mesh for the entire organization and for every team: for those running on modern Kubernetes environments and for those running on more traditional platforms like Virtual Machines and Bare Metal.

* **Universal and Kubernetes-Native**: Platform-agnostic, can run and operate anywhere.
* **Easy to use**: Via automation and a gradual learning curve to Service Mesh policies.
* **Simple to deploy**: In one step, across both Kubernetes and other platforms.
* **Enterprise-Ready**: Pragmatic platform for the Enterprise that delivers business value today.

::: tip
**Real-Time Support**: The Kuma community provides channels for real-time communication and support that you can explore in our [Community](/community) page. It also provides dedicated [Enterprise Support](/enterprise) delivered by [Kong](https://konghq.com).
:::

## VM and K8s support

The platform agnosticity of Kuma enables Service Mesh to the entire organization - and not just Kubernetes - making it a more viable solution for the entire organization.

Until now, Service Mesh has been considered to be the last step of architecture modernization after transitioning to containers and perhaps to Kubernetes. This approach is entirely backwards. It makes the adoption and the business value of Service Mesh available only after implementing other massive transformations that - in the meanwhile - can go wrong.

In reality, we want Service Mesh to be available *before* we implement other transitions so that we can keep the network both secure and observable in the process. With Kuma, Service Mesh is indeed the **first step** towards modernization.

<center>
<img src="/images/docs/0.2.0/diagram-05.jpg" alt="" style=" padding-top: 20px; padding-bottom: 10px;"/>
</center>

Unlike other control planes, Kuma natively runs across every platform - Kubernetes, VMs and Bare Metal - and it's not limited in scope (like many other control planes that only work on Kubernetes only). Kuma can run on both existing brownfield applications (that are most likely running on VMs), as well as new and modern greenfield applications that may be running on containers and Kubernetes.

Unlike other control planes, Kuma is easy to use. Anybody - from any team - can implement Kuma in [three simple steps](/install/0.3.2) across both traditional monolithic applications and modern microservices.

Finally, by leveraging out-of-the-box policies and Kuma's powerful tagging selectors, we can implement a variety of behaviors in a variety of topologies, similar to multi-cloud and multi-region architectures.

## Quickstart

The getting started for Kuma can be found in the [installation page](/install/0.3.2) where you can follow the instructions to get up and running with Kuma.

If you need help, you can chat with the [Community](/community) where you can ask questions, contribute back to Kuma and send feedback.