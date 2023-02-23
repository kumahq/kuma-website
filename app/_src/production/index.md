---
title: About Kuma in Production 
content_type: explanation
subtitle: Deploying Kuma in a production environment. 
---

After you've completed your initial test and assessment of {{site.mesh_product_name}}, it's time to deploy {{site.mesh_product_name}} in your production environment. Before doing so, it's important to understand the overall steps in the deployment process as well as the different options you have when deploying {{site.mesh_product_name}}. This guide will walk you through the big picture steps and options so you can make the right decisions when it comes to deployment time.

## Overview of deployment steps

General overview of the different steps to take when deploying Kuma. Each of these should have a link to supporting docs.

1. Decide on which deployment topology you plan to use.
1. Install kumactl (why, what is this)
1. Deploy the control plane
1. Configure the data plane
1. Configure security measures for {{site.mesh_product_name}}
1. 

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

This is required to perform any _____? 

### CP and DP structure?

Info about how the CP and DP interact? Or is this basically a rehash of existing content?

### {{site.mesh_product_name}} security