[//]: # (This is change in behavior, let's assume that users will get used to it, so we won't have to show this warning after 2.9.x)
{% if_version gte:2.7.x lte:2.9.x %}

{% warning %}
**Heads up!**
In previous versions of {{site.mesh_product_name}}, setting the `kuma.io/service` tag directly within a `MeshGatewayInstance` resource was used to identify the service. However, this practice is deprecated and no longer recommended for security reasons since {{site.mesh_product_name}} version 2.7.0.

We've automatically switched to generating the service name for you based on your `MeshGatewayInstance` resource name and namespace (format: `{name}_{namespace}_svc`).
{% endwarning %}

{% endif_version %}
