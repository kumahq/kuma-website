---
title: Service Discovery
---

This page explains how communication between the components of {{site.mesh_product_name}} handles service traffic. Communication is handled between the data plane proxy (`kuma-dp`) and the control plane (`kuma-cp`), and between multiple instances of the data plane proxy.

When a data plane proxy connects to the control-plane, it initiates a gRPC streaming connection to the control plane. It retrieves the latest policy configuration from the control plane and sends diagnostic information to the control plane.

{% if_version lte:2.5.x %}
In {% if_version lte:2.1.x %}[standalone mode](/docs/{{ page.release }}/deployments/stand-alone){% endif_version %}{% if_version gte:2.2.x %}[standalone mode](/docs/{{ page.release }}/production/deployment/stand-alone/){% endif_version %} the `kuma-dp` process connects directly to the `kuma-cp` instances.
{% endif_version %}
{% if_version gte:2.6.x %}
In [single-zone mode](/docs/{{ page.release }}/production/deployment/single-zone/) the `kuma-dp` process connects directly to the `kuma-cp` instances.
{% endif_version %}

In a {% if_version lte:2.1.x %}[multi-zone deployment](/docs/{{ page.release }}/deployments/multi-zone){% endif_version %}{% if_version gte:2.2.x %}[multi-zone deployment](/docs/{{ page.release }}/production/deployment/multi-zone/){% endif_version %} the `kuma-dp` processes will connect to the zone control plane, while the zone control planes will connect to the global control plane over an extension of the xDS API that we have built called "KDS" ({{site.mesh_product_name}} Discovery Service). In multi-zone mode, the data plane proxies never connect to the global control plane but only to the zone ones.

{% tip %}
The connection between the data-planes and the control-plane is not on the execution path of the service requests, which means that if the data-plane temporarily loses connection to the control-plane the service traffic won't be affected.
{% endtip %}

While doing so, the data-planes also advertise the IP address of each service. The IP address is retrieved:

* On Kubernetes by looking at the address of the `Pod`.
* On Universal by looking at the inbound listeners that have been configured in the {%if_version lte:2.1.x %}[`inbound` property](/docs/{{ page.release }}/explore/dpp-on-universal/){%endif_version%}{%if_version gte:2.2.x %}[`inbound` property](/docs/{{ page.release }}/production/dp-config/dpp-on-universal#dataplane-configuration){%endif_version%} of the data-plane specification.

The IP address that's being advertised by every data-plane to the control-plane is also being used to route service traffic from one `kuma-dp` to another `kuma-dp`. This means that {{site.mesh_product_name}} knows at any given time what are all the IP addresses associated to every replica of every service. Another use-case where the IP address of the data-planes is being used is for metrics scraping by Prometheus.

{{site.mesh_product_name}} already ships with its own [DNS](/docs/{{ page.release }}/networking/dns). 

Connectivity among the `kuma-dp` instances can happen in two ways:

{% if_version lte:2.5.x %}
* In {% if_version lte:2.1.x %}[standalone mode](/docs/{{ page.release }}/deployments/stand-alone){% endif_version %}{% if_version gte:2.2.x %}[standalone mode](/docs/{{ page.release }}/production/deployment/stand-alone/){% endif_version %} `kuma-dp` processes communicate with each other in a flat networking topology. This means that every data-plane must be able to consume another data-plane by directly sending requests to its IP address. In this mode, every `kuma-dp` must be able to send requests to every other `kuma-dp` on the specific ports that govern service traffic, as described in the `kuma-dp` {% if_version lte:2.1.x %}[ports section](/docs/{{ page.release }}/networking/networking#kuma-dp-ports){% endif_version %}{% if_version gte:2.2.x %}[ports section](/docs/{{ page.release }}/production/dp-config/dpp#data-plane-proxy-ports){% endif_version %}.
{% endif_version %}
  {% if_version gte:2.6.x %}
* In [single-zone mode](/docs/{{ page.release }}/production/deployment/single-zone/) `kuma-dp` processes communicate with each other in a flat networking topology. This means that every data-plane must be able to consume another data-plane by directly sending requests to its IP address. In this mode, every `kuma-dp` must be able to send requests to every other `kuma-dp` on the specific ports that govern service traffic, as described in the `kuma-dp` [ports section](/docs/{{ page.release }}/production/dp-config/dpp#data-plane-proxy-ports).
  {% endif_version %}
* In {% if_version lte:2.1.x %}[multi-zone mode](/docs/{{ page.release }}/deployments/multi-zone){% endif_version %}{% if_version gte:2.2.x %}[multi-zone mode](/docs/{{ page.release }}/production/deployment/multi-zone/){% endif_version %}connectivity is being automatically resolved by {{site.mesh_product_name}} to either a data plane running in the same zone, or through the address of a {% if_version lte:2.1.x %}[zone egress proxy](/docs/{{ page.release }}/explore/zoneegress){% endif_version %}{% if_version gte:2.2.x %}[zone egress proxy](/docs/{{ page.release }}/production/cp-deployment/zoneegress/){% endif_version %} (if present) and {% if_version lte:2.1.x %}[zone ingress proxy](/docs/{{ page.release }}/explore/zone-ingress){% endif_version %}{% if_version gte:2.2.x %}[zone ingress proxy](/docs/{{ page.release }}/production/cp-deployment/zone-ingress/){% endif_version %} in another zone for cross-zone connectivity. This means that multi-zone connectivity can be used to connect services running in different clusters, platforms or clouds in an automated way. {{site.mesh_product_name}} also creates a `.mesh` zone via its [native DNS resolver](/docs/{{ page.release }}/networking/dns/). The automatically created `kuma.io/zone` tag can be used with {{site.mesh_product_name}} policies in order to determine how traffic flows across a multi-zone setup.

{% tip %}
By default cross-zone connectivity requires [mTLS](/docs/{{ page.release }}/policies/mutual-tls) to be enabled on the {% if_version lte:2.1.x %}[Mesh](/docs/{{ page.release }}/policies/mesh){% endif_version %}{% if_version gte:2.2.x %}[Mesh](/docs/{{ page.release }}/production/mesh/){% endif_version %} with the appropriate {% if_version lte:2.5.x %}[Traffic Permission](/docs/{{ page.release }}/policies/traffic-permissions){% endif_version %}{% if_version gte:2.6.x %}[MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission){% endif_version %} to enable the flow of traffic. Otherwise, unsecured traffic won't be permitted outside each zone.
{% endtip %}
