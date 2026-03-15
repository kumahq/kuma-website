---
title: HTTP API
description: Reference documentation for the RESTful HTTP API to retrieve and manage mesh configuration, policies, data planes, and resources.
keywords:
  - HTTP API
  - REST API
---

{{site.mesh_product_name}} ships with a RESTful HTTP interface that you can use to retrieve the state of your configuration and policies on every environment, and when running on Universal mode it will also allow to make changes to the state. On Kubernetes, you will use native CRDs to change the state in order to be consistent with Kubernetes best practices.

{% tip %}
**CI/CD**: The HTTP API can be used for infrastructure automation to either retrieve data, or to make changes when running in Universal mode. The [`kumactl`](/docs/{{ page.release }}/explore/cli) CLI is built on top of the HTTP API, which you can also access with any other HTTP client like `curl`.
{% endtip %}


Get the full openAPI spec [in the Kuma repo](https://github.com/kumahq/kuma/blob/master/docs/generated/openapi.yaml)
