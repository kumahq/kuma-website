---
title: Manage control plane permissions on Kubernetes
content_type: how-to
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-control-plane-workloads = kuma | append: "-control-plane-workloads" %}
{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}

By default, {{ Kuma }} deployed on Kubernetes reacts to events and observes all resources at the cluster scope. This approach benefits first-time users who want to explore its functionality and simplifies migration into the mesh. However, in production environments, restricting access to specific resources can enhance security and ensure that {{ Kuma }} does not impact running applications.

## Restrict permissions to selected namespaces

You can define a list of namespaces that {{ Kuma }}'s control plane can access. When this list is set, {{ Kuma }} will only have permissions in those selected namespaces and in its own system namespace. It won't be able to access or manage resources in any other namespace.

### Set allowed namespaces during installation

To restrict {{ Kuma }} to a specific set of namespaces, set the following option during installation:

{% cpinstall namespaceAllowList %}
namespaceAllowList={kuma-demo}
{% endcpinstall %}

Replace `kuma-demo` with a comma-separated list of namespaces you want {{ Kuma }} to manage.

This will create a `RoleBinding` in each listed namespace, binding the `{{ kuma-control-plane-workloads }}` `ClusterRole` to that namespace. It will also configure {{ Kuma }}'s mutating and validating webhooks to only work within the specified namespaces.

<!-- vale Google.Headings = NO -->
## Manually manage RBAC resources
<!-- vale Google.Headings = YES -->

If your environment restricts creating cluster-scoped resources (`ClusterRole` or `ClusterRoleBinding`), or if you prefer to manage permissions yourself, you can disable automatic creation during installation.

Before installing {{ Kuma }}, you must manually create the following resources:

* `ClusterRole` and `ClusterRoleBinding` used by the control plane
* `Role` and `RoleBinding` within the control plane namespace
* (Optional) `RoleBindings` in selected namespaces when using `namespaceAllowList`

You can find the complete set of required manifests here:

{% rbacresources %}

These manifests include the `{{ kuma-control-plane-workloads }}` binding, granting the control plane write access to resources across all namespaces.

{% warning %}
{{ Important }}All required resources must be created **before** installing {{ Kuma }}.
{% endwarning %}

To disable automatic resource creation, use the following settings during installation:

{% capture skipRBAC %}
{% cpinstall skipRBAC %}
skipRBAC=true
{% endcpinstall %}
{% endcapture %}

{% capture skipClusterRoleCreation %}
{% cpinstall skipClusterRoleCreation %}
controlPlane.skipClusterRoleCreation=true
{% endcpinstall %}
{% endcapture %}

* Skip creation of **all** resources:

  {{ skipRBAC | indent }}

* Skip only **cluster-scoped** resources:

  {{ skipClusterRoleCreation | indent }}

{% warning %}
{{ Important }}If you choose to manage {{ Kuma }}'s RBAC resources yourself, make sure to keep them in sync during upgrades. When a new version of {{ Kuma }} is released, roles and role bindings may change, and it's your responsibility to update them accordingly.
{% endwarning %}
