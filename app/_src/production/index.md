---
title: About Kuma in Production 
content_type: explanation
subtitle: Deploying Kuma in a production environment. 
---

After you've completed your initial test and assessment of {{site.mesh_product_name}}, it's time to deploy {{site.mesh_product_name}} in your production environment. Before doing so, it's important to understand the overall steps in the deployment process as well as the different options you have when deploying {{site.mesh_product_name}}. This guide will walk you through the big picture steps and options so you can make the right decisions when it comes to deployment time.

## Overview of deployment steps

Deploying {{site.mesh_product_name}} to a production environment involves the following steps:

1. Decide which deployment topology you plan to use.
1. Install kumactl.
1. Deploy the control plane.
1. Configure the data plane.
1. Configure security features for {{site.mesh_product_name}}.

You can read more details about these steps in the following sections.

### Deployment topologies

There are two deployment models that can be adopted with {{site.mesh_product_name}} in order to address any Service Mesh use-case, from the simple one running in one zone to the more complex one where multiple Kubernetes or VM zones are involved, or even hybrid universal ones where {{site.mesh_product_name}} runs simultaneously on Kubernetes and VMs.

The following table describes some common use cases and the deployment modes you can use for them:

| Use case | Recommended deployment mode |
| -------- | --------------------------- |
| You want to migrate from on-premise or virtual machines to the cloud in a brownfield project. | Multi-zone |
| You only intend to deploy {{site.mesh_product_name}} in one zone, like one Kubernetes cluster or Amazon VPC. | Standalone |
| You want to run a mix of Kubernetes and Universal zones. | Multi-zone |
| You want to run workloads in different regions, clouds, and/or datacenters. | Multi-zone |

### kumactl

The first step after you pick your deployment mode is to install `kumactl`. `kumactl` is a CLI that can perform read-only operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. 

`kumactl` is one of the tools you can use to access the {{site.mesh_product_name}}.

### Control plane and data plane architecture

Once `kumactl` is installed, you can use it to configure the control plane and deploy the data plane. The control plane (CP) is never on the execution path of the requests that the services exchange with each other. It’s used as a source of truth to dynamically configure the underlying data plane proxies that are deployed alongside every instance of every service that is part of the service mesh.

You can either configure a [multi-zone](/docs/{{ page.version }}/production/cp-deployment/multi-zone/) or [standalone](/docs/{{ page.version }}/production/stand-alone/) control plane, depending on your organization's needs. You can deploy either a [Kubernetes](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/) or [Universal](/docs/{{ page.version }}/production/dp-config/dpp-on-universal/) data plane.

### {{site.mesh_product_name}} security

{{site.mesh_product_name}} offers many security features that you can use to ensure your service mesh is safe.

Here's a few of the main features:

* [Secure the access to your {{site.mesh_product_name}} deployment](/docs/{{ page.version }}/production/secure-deployment/certificates/)
* [Store sensitive data with secrets](/docs/{{ page.version }}/production/secure-deployment/secrets/)
* [Manage access control to administrative actions executed on the {{site.mesh_product_name}} API Server](/docs/{{ page.version }}/production/secure-deployment/api-access-control/)
* [Required data plane proxy authentication to obtain a configuration from the control plane](/docs/{{ page.version }}/production/secure-deployment/dp-auth/)
* [Required zone proxy authentication to obtain a configuration from the control plane](/docs/{{ page.version }}/production/cp-deployment/zoneproxy-auth/)
* [Configure data plane proxy membership constraints when joining a mesh](/docs/{{ page.version }}/production/secure-deployment/dp-membership/)