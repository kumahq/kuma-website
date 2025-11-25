---
title: Welcome to Kuma
description: Official documentation for Kuma, a modern service mesh control plane with Envoy Proxy integration, maintained by Kong.
keywords:
  - service mesh
  - Envoy
  - control plane
---

Welcome to the official documentation for Kuma, a modern distributed **Control Plane** with a bundled Envoy Proxy integration.

The word "Kuma" means "bear" in Japanese (クマ).

<center>
<img src="/assets/images/diagrams/main-diagram@2x.png" alt="" width="450" height="267"/>
</center>

The core maintainer of Kuma is **Kong**, the maker of the popular open-source Kong Gateway 🦍.

## Get started

[Read about service mesh](/docs/{{ page.release }}/introduction/about-service-meshes)

[Read about Kuma](/docs/{{ page.release }}/introduction/overview-of-kuma)

{% if_version lte:2.8.x %}
[Install Kuma](/install/latest/)
{% endif_version %}
{% if_version gte:2.9.x %}
[Install Kuma](/docs/{{ page.release }}/introduction/install)
{% endif_version %}

{% if_version gte:2.6.x %}[Jump to quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/){% endif_version %}{% if_version lte:2.5.x %}[Jump to quickstart](/docs/{{ page.release }}/quickstart/kubernetes/){% endif_version %}

[Explore the API](/docs/{{ page.release }}/reference/http-api)
