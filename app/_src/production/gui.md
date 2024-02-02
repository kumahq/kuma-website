---
title: Kuma user interface
content_type: explanation
---

{{site.mesh_product_name}} now ships with a basic web-based GUI that will serve as a visual overview of your dataplanes, meshes, and various traffic policies.

{% tip %}
The GUI pairs with the HTTP API — Read more about the HTTP API [here](/docs/{{ page.version }}/reference/http-api)
{% endtip %}

When launching {{site.mesh_product_name}}, the GUI will start by default on the API port, and defaults to `:5681/gui`. You can access it in your web browser by going to `http://localhost:5681/gui`.

## Getting Started
When you run the GUI for the first time, you’ll be presented with the Wizard:

<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/onboarding.png" alt="A screenshot of the first step of the Kuma GUI Wizard" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-welcome-wizard.png" alt="A screenshot of the first step of the Kuma GUI Wizard" />
{% endif_version %}
</center>

### This tool will:
1. Confirm that {{site.mesh_product_name}} is running
2. Determine if your environment is either Universal or Kubernetes
3. Provide instructions on how to add dataplanes (if none have yet been added). The instructions provided will be based on your {{site.mesh_product_name}} environment -- Universal or Kubernetes
4. Provide a short list of dataplanes found and their status (online or offline), in order to confirm that things are working accordingly and the app can display information

## Mesh Overview
Once you’ve completed the setup process, you’ll be sent to the Mesh Overview. This is a general overview of all of the meshes found. You can then view each entity and see how many dataplanes and traffic permissions, routes, and logs are associated with that mesh.


<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/mesh-overview.png" alt="A screenshot of the Mesh Overview of the Kuma GUI" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-mesh-overview.png" alt="A screenshot of the Mesh Overview of the Kuma GUI" />
{% endif_version %}
</center>

## Mesh Details
If you want to view information regarding a specific mesh, you can select the desired mesh from the pulldown at the top of the sidebar. You can then click on any of the overviews in the sidebar to view the entities and policies associated with that mesh.

{% tip %}
If you haven't yet created any meshes, this will default to the `default` mesh.
{% endtip %}

Each of these views will provide you with a table that displays helpful at-a-glance information. The Dataplanes table will display helpful information, including whether a dataplane is online, when it was last connected, how many connections it has, etc. This view also provides a control for refreshing your data on the fly without having to do a full page reload each time you've made changes:

<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/dataplane-list.png" alt="A screenshot of the Dataplanes information table with the new tag styles for Kuma" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-dataplanes-table.png" alt="A screenshot of the Dataplanes information table with the new tag styles for Kuma" />
{% endif_version %}
</center>

We also provide an easy way to view your entity in YAML format, as well as a control to copy it to your clipboard:

<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/dataplane-config.png" alt="A screenshot of the YAML to clipboard feature in the Kuma GUI" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-yaml-to-clipboard.png" alt="A screenshot of the YAML to clipboard feature in the Kuma GUI" />
{% endif_version %}
</center>

The dataplane view will enable you to see all policies that affect a specific dataplane:

<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/dataplane-policies.png" alt="A screenshot of policies that affect a dataplane in the Kuma GUI" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-dataplane-policy-list.png" alt="A screenshot of policies that affect a dataplane in the Kuma GUI" />
{% endif_version %}
</center>

It also gives you access to the full Envoy configuration of each dataplane which is useful when troubleshooting:

<center style="padding-top: 20px; padding-bottom: 10px;">
{% if_version gte:2.6.x %}
<img src="/assets/images/docs/{{ page.version }}/gui/xds-config.png" alt="A screenshot of the Envoy XDS dump of a dataplane in the Kuma GUI" />
{% endif_version %}
{% if_version lte:2.5.x %}
<img src="/assets/images/docs/gui-dataplane-xds-dump.png" alt="A screenshot of the Envoy XDS dump of a dataplane in the Kuma GUI" />
{% endif_version %}
</center>

## What’s to come
The GUI will eventually serve as a hub to view various metrics, such as latency and number of requests (total and per entity). We will also have charts and other visual tools for measuring and monitoring performance.
