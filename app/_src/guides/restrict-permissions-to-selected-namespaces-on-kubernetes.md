---
title: Restrict permissions to selected namespaces on Kubernetes
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-control-plane-workload = kuma | append: "-control-plane-workload" %}

By default, {{ Kuma }} deployed on Kubernetes has permissions to observe and react to events from resources across the entire cluster. While this behavior simplifies initial setup and testing, it might be too permissive for production environments. Limiting {{ Kuma }}'s access to only necessary namespaces helps enhance security and prevents potential impact on unrelated applications.

Starting from version 2.11, you can restrict the permissions granted to the {{ Kuma }} control plane. This guide explains how to limit {{ Kuma }} to specific namespaces, giving you greater control over security and resource management.

## Prerequisites

Before you start, ensure you have:

* A clean, running, and accessible Kubernetes cluster
* The `kubectl` command-line tool installed and configured

## Restrict {{ Kuma }} to selected namespaces

This section shows you how to restrict {{ Kuma }}'s permissions to selected namespaces, verify that restrictions are correctly applied, and update permissions if needed.

### Step 1: Create and label the initial namespace

```bash
kubectl create namespace first-namespace
kubectl label namespace first-namespace kuma.io/sidecar-injection=enabled
```

### Step 2: Install {{ Kuma }} restricted to the first namespace

{% cpinstall namespaceAllowList %}
namespaceAllowList={first-namespace}
{% endcpinstall %}

### Step 3: Deploy a test workload in the allowed namespace

```bash
kubectl run nginx --image=nginx --port=80 --namespace first-namespace
```

### Step 4: Verify the first namespace is working

Check that the control plane is managing the workload in `first-namespace`:

```bash
kubectl get dataplanes --namespace first-namespace
kubectl get pods --namespace first-namespace
kubectl get rolebindings --namespace first-namespace
```

You should see:

* A `Dataplane` resource listed
* The pod showing two containers (`2/2`), one for `nginx` and one for the sidecar
* A `RoleBinding` named `{{ kuma-control-plane-workload }}` that grants the control plane elevated access to manage resources within the namespace

### Step 5: Create and label a second namespace

```bash
kubectl create namespace second-namespace
kubectl label namespace second-namespace kuma.io/sidecar-injection=enabled
```

### Step 6: Deploy the same workload in the second namespace

```bash
kubectl run nginx --image=nginx --port=80 --namespace second-namespace
```

### Step 7: Verify the second namespace is not working

```bash
kubectl get dataplanes --namespace second-namespace
kubectl get pods --namespace second-namespace
```

No `Dataplanes` should be present, and pods should show only one container (`1/1`).

### Step 8: Update {{ Kuma }} to include the second namespace

{% cpinstall namespaceAllowListMore %}
namespaceAllowList={first-namespace,second-namespace}
{% endcpinstall %}

### Step 9: Restart workloads in the second namespace

Since the workload was created as a single pod (not part of a `Deployment`), delete the existing pod and run it again:

```bash
kubectl delete pod --namespace second-namespace --all
kubectl run nginx --image=nginx --port=80 --namespace second-namespace
```

### Step 10: Verify the second namespace is now working

```bash
kubectl get dataplanes --namespace second-namespace
kubectl get pods --namespace second-namespace
kubectl get rolebindings --namespace second-namespace
```

Just like with the first namespace, you should see:

* A `Dataplane` resource
* The pod showing two containers (`2/2`)
* A `RoleBinding` named `{{ kuma-control-plane-workload }}`

## Cleanup

When you're finished, clean up your environment with these steps:

### Step 11: Delete test namespaces and workloads

```bash
kubectl delete namespace first-namespace second-namespace
```

### Step 12:  Uninstall {{ Kuma }}

{% tabs codeblock %}
{% tab kumactl %}
```bash
kumactl install control-plane \
  --set "{{ site.set_flag_values_prefix }}namespaceAllowList={first-namespace,second-namespace}" \
  | kubectl delete -f -
```
{% endtab %}
{% tab Helm %}
```bash
helm uninstall {{ kuma }} --namespace {{ kuma }}-system
```
{% endtab %}
{% endtabs %}

## What you've learned

In this guide, you've learned how to:

* Restrict {{ Kuma }}'s control plane permissions to specific Kubernetes namespaces
* Deploy test workloads and verify if the control plane manages them
* Expand access to additional namespaces and verify updated behavior

## Next steps

To learn more about managing and restricting control plane permissions, see the [Manage control plane permissions on Kubernetes]({{ docs }}/production/secure-deployment/manage-control-plane-permissions-on-kubernetes/) documentation.
