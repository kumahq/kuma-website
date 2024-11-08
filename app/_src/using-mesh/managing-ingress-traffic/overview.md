---
title: How ingress works
---

{{site.mesh_product_name}} provides two features to manage ingress traffic, also known as north/south traffic.
Both take advantage of a piece of infrastructure called a _gateway proxy_, that
sits between external clients and your services in the mesh.

- [Delegated gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/delegated): allows users to use any existing gateway proxy, like [Kong](https://github.com/Kong/kong).
- [Builtin gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin): configures instances of Envoy to act as a gateway.

{% warning %}
Gateways exist within a `Mesh`.
If you have multiple `Meshes`, each `Mesh` requires its own gateway. You can easily connect your `Meshes` together using [cross-mesh gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners#cross-mesh).
{% endwarning %}

The below visualization shows the difference between delegated and builtin gateways. The blue lines represent traffic not managed by {{site.mesh_product_name}}.

Builtin, with Kong Gateway at the edge:

<center>
<img src="/assets/images/diagrams/builtin-gateway.webp" alt=""/>
</center>

Delegated Kong Gateway:

<center>
<img src="/assets/images/diagrams/delegated-gateway.webp" alt="" />
</center>
