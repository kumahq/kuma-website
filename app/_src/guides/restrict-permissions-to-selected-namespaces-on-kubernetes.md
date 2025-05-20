---
title: Restrict permissions to selected namespaces on Kubernetes
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-demo = kuma | append: "-demo" %}
{% assign kuma-another-demo = kuma | append: "-another-demo" %}

By default, {{ Kuma }} deployed on Kubernetes has permission to observe and react to events from resources across the entire cluster. While this behavior simplifies initial setup and testing, it might be too permissive for production environments. Limiting {{ Kuma }}'s access to only necessary namespaces helps enhance security and prevents potential impact on unrelated applications.

Starting from version 2.11, you can restrict the permissions granted to the {{ Kuma }} control plane. This guide explains how to limit {{ Kuma }} to specific namespaces, giving you greater control over security and resource management.

## Prerequisites

Before you start, ensure you have:

* A clean, running, and accessible Kubernetes cluster
* The `kubectl` command-line tool installed and configured
* The `kumactl` command-line tool installed

## Restrict {{ Kuma }} to selected namespaces

This section shows you how to restrict {{ Kuma }}'s permissions to selected namespaces, verify that restrictions are correctly applied, and update permissions if needed.

Follow these steps:

{% capture namespaceAllowList %}
{% cpinstall namespaceAllowList %}
namespaceAllowList={% raw %}{{% endraw %}{{ kuma-demo }}{% raw %}}{% endraw %}
{% endcpinstall %}
{% endcapture %}

{% capture namespaceAllowListMore %}
{% cpinstall namespaceAllowListMore %}
namespaceAllowList={% raw %}{{% endraw %}{{ kuma-demo }},{{ kuma-another-demo }}{% raw %}}{% endraw %}
{% endcpinstall %}
{% endcapture %}

{% capture cleanup %}
{% tabs codeblock %}
{% tab kumactl %}
```bash
kumactl install control-plane \
  --set "{{ site.set_flag_values_prefix }}namespaceAllowList={% raw %}{{% endraw %}{{ kuma-demo }},{{ kuma-another-demo }}{% raw %}}{% endraw %}" \
  | kubectl delete -f -
```
{% endtab %}
{% tab Helm %}
```bash
helm uninstall {{ kuma }} -n {{ kuma }}-system
```
{% endtab %}
{% endtabs %}
{% endcapture %}

1. **Install {{ Kuma }} restricted initially to just the `{{ kuma-demo }}` namespace**

   {{ namespaceAllowList | indent }}

2. **Deploy a demo application into the allowed namespace**

   ```bash
   kumactl install demo -n {{ kuma-demo }} | kubectl apply -f -
   ```

3. **Verify the demo is working correctly in the allowed namespace**

   You should see `Dataplanes` created and pods with sidecar injection:

   ```bash
   kubectl get dataplanes -n {{ kuma-demo }}
   kubectl get pods -n {{ kuma-demo }}
   ```

   Pods should show two containers each (`2/2`).

4. **Deploy another demo application in a different namespace (`{{ kuma-another-demo }}`), which isn't yet allowed**

   ```bash
   kumactl install demo -n {{ kuma-another-demo }} | kubectl apply -f -
   ```

   Confirm sidecar injection is enabled:

   ```bash
   kubectl get namespace {{ kuma-another-demo }} -o yaml
   ```

   Returned namespace should have an annotation:

   ```yaml
   kuma.io/sidecar-injection: enabled
   ```

5. **Verify that the second namespace is not yet working**

   `Dataplanes` won't appear, pods will have only one container, and no `RoleBindings` will exist.

   ```bash
   kubectl get dataplanes -n {{ kuma-another-demo }}
   kubectl get pods -n {{ kuma-another-demo }}
   kubectl get rolebindings -n {{ kuma-another-demo }}
   ```

6. **Update the {{ Kuma }} installation to include the second namespace**

   {{ namespaceAllowListMore | indent }}

7. **Restart workloads in the second namespace to apply the changes**

   ```bash
   kubectl rollout restart deployment -n {{ kuma-another-demo }}
   ```

8. **Confirm the second namespace now works as expected**

   `Dataplanes` should appear, pods should have two containers, and `RoleBindings` should exist:

   ```bash
   kubectl get dataplanes -n {{ kuma-another-demo }}
   kubectl get pods -n {{ kuma-another-demo }}
   kubectl get rolebindings -n {{ kuma-another-demo }}
   ```

## Cleanup

When you're finished, clean up your environment with these steps:

1. **Remove demo applications and their namespaces**

   ```bash
   kumactl install demo -n {{ kuma-demo }} | kubectl delete -f -
   kumactl install demo -n {{ kuma-another-demo }} | kubectl delete -f -
   ```

2. **Uninstall {{ Kuma }}**

   {{ cleanup | indent }}

## What you've learned

In this guide, you've learned how to:

* Restrict {{ Kuma }}'s control plane permissions to specific Kubernetes namespaces.
* Verify namespace restrictions by checking `Dataplanes`, sidecar injection, and RBAC resources.
* Update your {{ Kuma }} configuration to manage additional namespaces.

## Next steps

To learn more about managing and restricting control plane permissions, see the [Manage control plane permissions on Kubernetes]({{ docs }}/production/secure-deployment/manage-control-plane-permissions-on-kubernetes/) documentation.
