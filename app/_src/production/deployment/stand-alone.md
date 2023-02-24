---
title: Standalone deployment
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

## Limitations

* All data plane proxies need to be able to communicate with every other dataplane proxy.
* A standalone deployment cannot mix Universal and Kubernetes workloads.
* A deployment can connect to only one Kubernetes cluster at once.

If these limitations are problematic you should look at [Multi-zone deployments](/docs/{{ page.version }}/deployments/multi-zone).

## More information

For more information about how to configure a standalone deployment, see [Deploy a standalone control plane](/docs/{{ page.version }}/production/stand-alone/).