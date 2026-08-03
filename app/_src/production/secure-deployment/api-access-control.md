---
title: Kuma API access control
description: Configure access control for administrative actions on the API server, including managing secrets, generating tokens, and viewing Envoy configuration.
keywords:
  - API access control
  - token generation
  - admin resources
content_type: reference
---

{{site.mesh_product_name}} provide a simple access control to administrative actions executed on {{site.mesh_product_name}} API Server (port 5681 by default).

{% warning %}
{{site.mesh_product_name}} does **not** provide role-based access control (RBAC).
The settings on this page are coarse allow-lists for a few administrative operations - they are not a general authorization layer.
Most resources, including `Mesh`, are writable by any caller that can reach the API server.

By default the API server listens on `0.0.0.0:5681` with no authentication, so any client that can reach that port can create, update, or delete resources.
A `Mesh` resource includes the mesh mTLS CA (`mtls.backends[].conf`), so a caller that can `PUT` a `Mesh` can replace the CA and take over the mesh.
Enabling [token authentication](/docs/{{ page.release }}/production/secure-deployment/api-server-auth/) does not prevent this on its own, because a `Mesh` write is not an admin-only operation - any valid token can perform it.

You are responsible for restricting access to the API server yourself.
See [Protecting the API server](/docs/{{ page.release }}/production/secure-deployment/api-server-auth/#protecting-the-api-server).
{% endwarning %}

## Manage admin resources

Admin resources are `Secret` and `GlobalSecret`.

* `KUMA_ACCESS_STATIC_ADMIN_RESOURCES_USERS` allows users to manage admin resources. Default is `mesh-system:admin`.
* `KUMA_ACCESS_STATIC_ADMIN_RESOURCES_GROUPS` allows groups to manage admin resources. Default is `mesh-system:admin`.

## Generate dataplane token

* `KUMA_ACCESS_STATIC_GENERATE_DP_TOKEN_USERS` allows users to generate dataplane token. Default `mesh-system:admin`.
* `KUMA_ACCESS_STATIC_GENERATE_DP_TOKEN_GROUPS` allows groups to generate dataplane token. Default `mesh-system:admin`.

## Generate user token

* `KUMA_ACCESS_STATIC_GENERATE_USER_TOKEN_USERS` allows users to generate user token. Default `mesh-system:admin`.
* `KUMA_ACCESS_STATIC_GENERATE_USER_TOKEN_GROUPS` allows groups to generate user token. Default `mesh-system:admin`.

## Generate zone token

* `KUMA_ACCESS_STATIC_GENERATE_ZONE_TOKEN_USERS` allows users to generate zone token. Default `mesh-system:admin`.
* `KUMA_ACCESS_STATIC_GENERATE_ZONE_TOKEN_GROUPS` allows groups to generate zone token. Default `mesh-system:admin`.

## View Envoy config dump

* `KUMA_ACCESS_STATIC_GET_CONFIG_DUMP_USERS` allows users to view Envoy config dump. Default is an empty list.
* `KUMA_ACCESS_STATIC_GET_CONFIG_DUMP_GROUPS` allows groups to view Envoy config dump. Default: `mesh-system:unauthenticated`, `mesh-system:authenticated`.

## View Envoy stats

* `KUMA_ACCESS_STATIC_VIEW_STATS_USERS` allows users to view Envoy stats. Default is an empty list.
* `KUMA_ACCESS_STATIC_VIEW_STATS_GROUPS` allows groups to view Envoy stats. Default: `mesh-system:unauthenticated`, `mesh-system:authenticated`.

## View Envoy clusters

* `KUMA_ACCESS_STATIC_VIEW_CLUSTERS_USERS` allows users to view Envoy clusters. Default is an empty list.
* `KUMA_ACCESS_STATIC_VIEW_CLUSTERS_GROUPS` allows groups to view Envoy clusters. Default: `mesh-system:unauthenticated`, `mesh-system:authenticated`.
