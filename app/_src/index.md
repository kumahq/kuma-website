---
title: Welcome to Kuma
---

Welcome to the official documentation for Kuma, a modern distributed **Control Plane** with a bundled Envoy Proxy integration.

The word "Kuma" means "bear" in Japanese (クマ).

<center>
<img src="/assets/images/diagrams/main-diagram@2x.png" alt="" width="450" height="267"/>
</center>

The core maintainer of Kuma is **Kong**, the maker of the popular open-source Kong Gateway 🦍.

## Get started

{% if_version lte:2.1.x %}
[Read about service mesh](/docs/{{ page.release }}/introduction/what-is-a-service-mesh)

[Read about Kuma](/docs/{{ page.release }}/introduction/what-is-kuma)

[Install Kuma](/install/latest/)

[Jump to quickstart](/docs/{{ page.release }}/quickstart/kubernetes/)

[Explore the API](/docs/{{ page.release }}/reference/http-api)
{% endif_version %}
{% if_version gte:2.2.x %}
[Read about service mesh](/docs/{{ page.release }}/introduction/about-service-meshes)

[Read about Kuma](/docs/{{ page.release }}/introduction/overview-of-kuma)

[Install Kuma](/install/latest/)

{% if_version gte:2.6.x %}[Jump to quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/){% endif_version %}{% if_version lte:2.5.x %}[Jump to quickstart](/docs/{{ page.release }}/quickstart/kubernetes/){% endif_version %}

[Explore the API](/docs/{{ page.release }}/reference/http-api)
{% endif_version %}
