---
title: Restrict permissions to selected namespaces on Kubernetes
content_type: tutorial
description: Limit control plane access to specific Kubernetes namespaces for enhanced security.
keywords:
  - namespace restrictions
  - Kubernetes security
  - RBAC
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane-workloads = kuma | append: "-control-plane-workloads" %}

By default, {{ Kuma }} deployed on Kubernetes has permissions to observe and react to events from resources across the entire cluster. While this behavior simplifies initial setup and testing, it might be too permissive for production environments. Limiting {{ Kuma }}'s access to only necessary namespaces helps enhance security and prevents potential impact on unrelated applications.

This guide explains how to limit {{ Kuma }} to specific namespaces, giving you greater control over security and resource management.

## Prerequisites

Before you begin, make sure you have the following tools installed:

* [Helm](https://helm.sh/) – used to install and manage Kubernetes applications
* [minikube](https://minikube.sigs.k8s.io/docs/) – used to run a local Kubernetes cluster for testing

### Start a Kubernetes cluster

Start a local Kubernetes cluster using minikube. The `-p` flag creates a new profile named `mesh-zone`:

```bash
minikube start -p mesh-zone
```

{% tip %}
If you already have a running Kubernetes cluster, either locally or in the cloud (for example, EKS, GKE, or AKS), you can skip this step.
{% endtip %}

## Restrict {{ Kuma }} to selected namespaces

This section walks through configuring {{ Kuma }} to limit its access to specific namespaces. You’ll deploy test workloads, verify control plane behavior, and then expand access to additional namespaces.

### Install {{ Kuma }} which manages a single namespace

#### Create and label the namespace

```bash
kubectl create namespace first-namespace
kubectl label namespace first-namespace kuma.io/sidecar-injection=enabled
```

#### Install {{ Kuma }} restricted to the first namespace

```bash
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ kuma-system }} \
  --set "{{ site.set_flag_values_prefix }}namespaceAllowList={first-namespace}" \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

#### Deploy a test workload

```bash
kubectl run nginx --image=nginx --port=80 --namespace first-namespace
```

#### Verify the first namespace is working

Check that the control plane is managing the workload:

```bash
kubectl get dataplanes --namespace first-namespace
```

Expected:

```
NAME    KUMA.IO/SERVICE             KUMA.IO/SERVICE
nginx   nginx_first-namespace_svc
```
{:.no-line-numbers}

Then check that the pod has the sidecar injected:

```bash
kubectl get pods --namespace first-namespace
```

Expected:

```
NAME    READY   STATUS    RESTARTS   AGE
nginx   2/2     Running   0          2m5s
```
{:.no-line-numbers}

Then verify the required RoleBinding:

```bash
kubectl get rolebindings --namespace first-namespace
```

Expected:

{% capture rbacHeader -%}
{%- if page.edition and page.edition != "kuma" %}
NAME                                ROLE                                            AGE
{%- else %}
NAME                           ROLE                                       AGE
{%- endif %}
{% endcapture %}

```
{{- rbacHeader -}}
{{ kuma-control-plane-workloads }}   ClusterRole/{{ kuma-control-plane-workloads }}   3m46s
```
{:.no-line-numbers}

This confirms that:

* A `Dataplane` was created
* The pod includes the `kuma-sidecar`
* A `RoleBinding` named `{{ kuma-control-plane-workloads }}` grants elevated access to the control plane

### Create a second namespace and check {{ Kuma }} doesn't run in it

#### Create and label the second namespace

```bash
kubectl create namespace second-namespace
kubectl label namespace second-namespace kuma.io/sidecar-injection=enabled
```

#### Deploy the same workload in the second namespace

```bash
kubectl run nginx --image=nginx --port=80 --namespace second-namespace
```

#### Verify the second namespace is *not* working

Check that the control plane is **not** managing resources in `second-namespace`.

Run the following commands:

```bash
kubectl get dataplanes --namespace second-namespace
```

Expected output:

```
No resources found in second-namespace namespace.
```
{:.no-line-numbers}

This means no `Dataplane` was created.

```bash
kubectl get pods --namespace second-namespace
```

Expected output:

```
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          42s
```
{:.no-line-numbers}

This indicates the pod is running **without** the `kuma-sidecar`.

```bash
kubectl get rolebindings --namespace second-namespace
```

Expected output:

```
No resources found in second-namespace namespace.
```
{:.no-line-numbers}

This confirms that:

* The control plane does not have permission to manage this namespace
* The pod was started without sidecar injection
* No `RoleBinding` was created to grant control plane access

### Update {{ Kuma }} to also manage the second namespace

#### Update {{ Kuma }} to include `second-namespace`

```bash
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ kuma-system }} \
  --set "{{ site.set_flag_values_prefix }}namespaceAllowList={first-namespace,second-namespace}" \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

#### Restart workloads in the second namespace

Delete the old pod and recreate it to trigger sidecar injection:

```bash
kubectl delete pod --namespace second-namespace --all
kubectl run nginx --image=nginx --port=80 --namespace second-namespace
```

#### Verify the second namespace is now working

Check that the control plane is now managing the workload in `second-namespace`:

```bash
kubectl get dataplanes --namespace second-namespace
```

You should see a `Dataplane` resource for the new pod, confirming it is part of the mesh.

Next, verify that the pod now includes a sidecar:

```bash
kubectl get pods --namespace second-namespace
```

Expected output:

```
NAME    READY   STATUS    RESTARTS   AGE
nginx   2/2     Running   0          30s
```
{:.no-line-numbers}

Finally, check that the required `RoleBinding` has been created:

```bash
kubectl get rolebindings --namespace second-namespace
```

Expected output:

```
{{- rbacHeader -}}
{{ kuma-control-plane-workloads }}   ClusterRole/{{ kuma-control-plane-workloads }}   30s
```
{:.no-line-numbers}

This confirms that:

* The control plane has the correct permissions in `second-namespace`
* The pod was injected with the `kuma-sidecar`
* The namespace is now fully integrated with the mesh


## Cleanup

When you're finished, clean up your environment:

```bash
minikube delete -p mesh-zone
```

## What you've learned

In this guide, you've learned how to:

* Restrict {{ Kuma }}'s control plane permissions to specific Kubernetes namespaces
* Deploy test workloads and verify if the control plane manages them
* Expand access to additional namespaces and verify updated behavior

## Next steps

To learn more about managing and restricting control plane permissions, see the [Manage control plane permissions on Kubernetes]({{ docs }}/production/secure-deployment/manage-control-plane-permissions-on-kubernetes/) documentation.
