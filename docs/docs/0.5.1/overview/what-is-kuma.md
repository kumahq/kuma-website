---
title: What is Kuma?
---

# What is Kuma?

::: tip
**Need help?** Don't forget to check the [Community](/community) section! 
:::

Kuma is a platform agnostic open-source control plane for Service Mesh and Microservices. It can run and be operated natively across both Kubernetes and VM environments, making it easy to adopt by every team in the organization.

<center>
<img src="/images/diagrams/main-diagram@2x.png" alt="" style="width: 550px; padding-top: 10px"/>
</center>

Bundling [Envoy](https://envoyproxy.io/) as a data-plane, Kuma can instrument any L4/L7 traffic to secure, observe, route and enhance connectivity between any service or database. It can be used natively in Kubernetes via CRDs or via a RESTful API across other environments like VMs and Bare Metal.

While being simple to use for most use-cases, Kuma also provides policies to configure the underlying Envoy data-planes in a more fine-grained manner. By doing so, Kuma can be used by both first-time users of Service Mesh, as well as the most experienced ones.

Kong built Kuma with feedback from 100+ enterprise organizations running Service Mesh in production. As such, Kuma implements a pragmatic approach that is very different from other control plane implementations:  

- **Universal**: Kuma runs on every platform, including Kubernetes and VMs and a hybrid of both.
- **Simple**: To deploy and to use, Kuma provides easy to use policies for various use-cases.
- **Scalable**: Kuma supports multi-tenancy, attribute based policies and scalable multi-cluster support.
- **Envoy-based**: Kuma is built on top of Envoy, the most adopted proxy for Service Mesh.

## Flat and Distributed deployments

Kuma supports different deployment models:

* [Flat Deployment](#) with one control plane being in charge of multiple data plane proxies.
* [Distributed Deployment](#) with a global control plane and remote control planes for each underlying cluster.

Below an example of a distributed deployment, which also enables Kuma to setup a Service Mesh that runs simoultaneously on multiple Kubernetes clusters, or on a hybrid Kubernetes/VM cluster:

<center>
<img src="/images/docs/0.6.0/distributed-deployment.jpg" alt="" style="width: 700px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

In both deployment modes service-to-service connectivity is abstracted away via Kuma Ingress resources and DNS Service Discovery that makes service-to-service connectivity completely automated. Supporting complex deployments while still making the Service Mesh easy to use has been a main driver in the adoption of Kuma.
