---
title: Standalone deployment
description: Deploy the service mesh in standalone mode where all data plane proxies connect directly to a single control plane.
keywords:
  - standalone
  - deployment topology
  - control plane
content_type: explanation
---

## About

This is the simplest deployment mode for {{site.mesh_product_name}}, and the default one.

* **Control plane**: There is one deployment of the control plane that can be scaled horizontally.
* **Data plane proxies**: The data plane proxies connect to the control plane regardless of where they are deployed.
* **Service Connectivity**: Every data plane proxy must be able to connect to every other data plane proxy regardless of where they are being deployed.

This mode implies that we can deploy {{site.mesh_product_name}} and its data plane proxies in a standalone networking topology mode so that the service connectivity from every data plane proxy can be established directly to every other data plane proxy.

<center>
<img src="/assets/images/docs/0.6.0/flat-diagram.png" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Standalone mode is usually a great choice within the context of one zone (ie: within one Kubernetes cluster or one AWS VPC).


To Install with this topology follow the [stand-alone deployment docs](/docs/{{ page.release }}/production/cp-deployment/stand-alone).


## Limitations

* All data plane proxies need to be able to communicate with every other dataplane proxy.
* A standalone deployment cannot mix Universal and Kubernetes workloads.
* A deployment can connect to only one Kubernetes cluster at once.

If these limitations are problematic you should look at [Multi-zone deployments](/docs/{{ page.release }}/production/deployment/multi-zone/).

## Components of a standalone deployment

A standalone deployment includes:

- The **control plane**:
  - Accept connections from data plane proxies.
  - Accept creation and changes to [policies](/policies) that will be applied to the data plane proxies.
  - Keep an inventory of all data plane proxies running.
  - Compute and send configurations using XDS to the data plane proxies.
- The **data plane proxies**:
  - Connect to the zone control plane.
  - Receive configurations using XDS from the control plane.
  - Connect to other data plane proxies.

## Failure modes

#### Control plane offline

* New data plane proxies won't be able to join the mesh. This includes new instances (Pod/VM) that are newly created by automatic deployment mechanisms (for example, a rolling update process), meaning a control plane connection failure could block updates of applications and events that create new instances.
* On mTLS enabled meshes, a data plane proxy may fail to refresh its client certificate prior to expiry (defaults to 24 hours), thus causing traffic from/to this data plane to fail.
* Data-plane proxy configuration will not be updated.
* Communication between data planes proxies will still work.

{% tip %}
You can think of this failure case as *"Freezing"* the zone mesh configuration.
Communication will still work but changes will not be reflected on existing data plane proxies.
{% endtip %}
