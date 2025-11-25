---
title: Kuma user interface (GUI)
description: Use the web-based GUI to visualize meshes, data plane proxies, services, and traffic policies.
keywords:
  - GUI
  - dashboard
  - visualization
content_type: explanation
---

{{site.mesh_product_name}} now ships with a basic web-based GUI that will serve as a visual overview of your dataplanes, meshes, and various traffic policies.

{% tip %}
The GUI pairs with the HTTP API — Read more about the HTTP API [here](/docs/{{ page.release }}/reference/http-api)
{% endtip %}

When launching {{site.mesh_product_name}}, the GUI will start by default on the API port, and defaults to `:5681/gui`. You can access it in your web browser by going to `http://localhost:5681/gui`.

## Overview
This is a general overview of all of the meshes and zones found. You can then view each entity and see how many dataplanes and traffic permissions, routes, and logs are associated with that mesh.

<center>
<img src="/assets/images/gui/overview.png" alt="A screenshot of the Mesh Overview of the Kuma GUI" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Mesh Details
If you want to view information regarding a specific mesh, you can select the desired mesh. 
In this page you'll get general information about the mesh like the number of services, dataplanes and policies.

<center>
<img src="/assets/images/gui/mesh-overview.png" alt="A screenshot of the overview of the Mesh Kuma"/>
</center>

You can use the tabs to see the services, gateways, data planes proxies or policies that exist within this mesh. 

## Data-plane proxy details

When clicking through a data-plane you can see the inbounds and outbounds.
Including the stats attached to them, these stats are ever increasing since the start of the data-plane.

<center>
<img src="/assets/images/gui/dataplane-overview.png" alt="A screenshot the dataplane overview"/>
</center>

If you click on an inbound or outbound you can get extra information including detailed envoy stats and configuration.
This can be useful to understand what policies are modifying configuration or when troubleshooting an issue.

<center>
<img src="/assets/images/gui/dataplane-outbound-overview.png" alt="A screenshot the dataplane outbound overview with Envoy stats"/>
</center>
