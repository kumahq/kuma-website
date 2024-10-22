---
title: About Kuma in Production
content_type: explanation
subtitle: Deploying Kuma in a production environment.
---

After you've completed your initial test and assessment of {{site.mesh_product_name}}, it's time to deploy {{site.mesh_product_name}} in your production environment.
Before doing so, it's important to understand the overall steps in the process as well as the different options you have.
This guide walks you through the big picture steps and options so you can make the right decisions when it comes to deployment time.

## Overview of deployment steps

Deploying {{site.mesh_product_name}} to a production environment involves the following steps:

1. [Decide which deployment topology you plan to use](#deployment-topologies).
1. [Install `kumactl`](#kumactl).
1. [Deploy the control plane](#control-plane-and-data-plane-architecture).
1. [Configure the data plane](#control-plane-and-data-plane-architecture).
1. [Configure security features for {{site.mesh_product_name}}](#security).

### Deployment topologies

There are two [deployment models](/docs/{{ page.version }}/production/deployment/) that can be adopted with {{site.mesh_product_name}}: {% if_version gte:2.6.x %}[single-zone](/docs/{{ page.version }}/production/deployment/single-zone/){% endif_version %}{% if_version lte:2.5.x %}standalone{% endif_version %} and [multi-zone](/docs/{{ page.version }}/production/deployment/multi-zone/). You can use these modes to address any service mesh use case, including:
* A simple model with the service mesh running in one zone
* A more complex model where multiple Kubernetes or VM zones are involved
* A hybrid universal model where {{site.mesh_product_name}} runs simultaneously on Kubernetes and VMs

The following table describes some common use cases and the deployment modes you can use for them:

| Use case | Recommended deployment mode                                                                                                  |
| -------- |------------------------------------------------------------------------------------------------------------------------------|
| You want to migrate from on-premise or virtual machines to the cloud in a brownfield project. | [Multi-zone](/docs/{{ page.version }}/production/deployment/multi-zone/) |
| You only intend to deploy {{site.mesh_product_name}} in one zone, like one Kubernetes cluster or Amazon VPC. | {% if_version gte:2.6.x inline:true %}[Single-zone](/docs/{{ page.version }}/production/deployment/multi-zone/){% endif_version %}{% if_version lte:2.5.x inline:true %}Standalone{% endif_version %} |
| You want to run a mix of Kubernetes and Universal zones. | [Multi-zone](/docs/{{ page.version }}/production/deployment/multi-zone/) |
| You want to run workloads in different regions, clouds, and/or data centers. | [Multi-zone](/docs/{{ page.version }}/production/deployment/multi-zone/) |

### kumactl

The first step after you pick your deployment mode is to [install `kumactl`](/docs/{{ page.version }}/production/install-kumactl/). `kumactl` is a CLI tool that you can use to access {{site.mesh_product_name}}. It can do the following:

* Perform read-only operations on {{site.mesh_product_name}} resources on Kubernetes.
* Read and create resources in {{site.mesh_product_name}} in Universal mode.

The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API.

### Control plane and data plane architecture

Once `kumactl` is installed, you can use it to configure the control plane and deploy the data plane. The control plane (CP) is never on the execution path of the requests that the services exchange with each other. It’s used as a source of truth to dynamically configure the underlying data plane proxies that are deployed alongside every instance of every service that is part of the service mesh.

You can either configure a [multi-zone](/docs/{{ page.version }}/production/cp-deployment/multi-zone/) or {% if_version gte:2.6.x %}[single-zone](/docs/{{ page.version }}/production/cp-deployment/single-zone/){% endif_version %}{% if_version lte:2.5.x %}[standalone](/docs/{{ page.version }}/production/cp-deployment/stand-alone/){% endif_version %} control plane, depending on your organization's needs. You can deploy either a [Kubernetes](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/) or [Universal](/docs/{{ page.version }}/production/dp-config/dpp-on-universal/) data plane.

### Security

{{site.mesh_product_name}} offers many security features that you can use to ensure your service mesh is safe.

Here are a few of the main features:

* [Secure the access to your {{site.mesh_product_name}} deployment](/docs/{{ page.version }}/production/secure-deployment/certificates/)
* [Store sensitive data with secrets](/docs/{{ page.version }}/production/secure-deployment/secrets/)
* [Manage access control to administrative actions executed on the {{site.mesh_product_name}} API Server](/docs/{{ page.version }}/production/secure-deployment/api-access-control/)
* [Require data plane proxy authentication to obtain a configuration from the control plane](/docs/{{ page.version }}/production/secure-deployment/dp-auth/)
* [Require zone proxy authentication to obtain a configuration from the control plane](/docs/{{ page.version }}/production/cp-deployment/zoneproxy-auth/)
* [Configure data plane proxy membership constraints when joining a mesh](/docs/{{ page.version }}/production/secure-deployment/dp-membership/)
