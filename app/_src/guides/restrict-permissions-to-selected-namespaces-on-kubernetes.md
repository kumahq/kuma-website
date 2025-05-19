---
title: Restrict permissions to selected namespaces on Kubernetes
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}

By default, {{ Kuma }} deployed on Kubernetes has permission to observe and react to events from resources across the entire cluster. While this behavior simplifies initial setup and testing, it might be too permissive for production environments. Limiting {{ Kuma }}'s access to only necessary namespaces helps enhance security and prevents potential impact on unrelated applications.

Starting from version 2.11, you can restrict the permissions granted to the {{ Kuma }} control plane. This guide explains how to limit {{ Kuma }} to specific namespaces, giving you greater control over security and resource management.

## Prerequisites

Before you start, make sure you have a clean, running, and accessible Kubernetes cluster.

## Step 1: Install {{ Kuma }}

Install {{ Kuma }} with default options by running:

{% tabs codeblock %}
{% tab kumactl %}
```bash
kumactl install control-plane | kubectl apply -f -
```
{:.no-line-numbers}
{% endtab %}
{% tab Helm %}
```bash
# Before installing {{ Kuma }} with Helm, configure your local Helm repository:
# {{ site.links.web }}{{ docs }}/production/cp-deployment/kubernetes/#helm
helm install \
  --create-namespace \
  -n {{ site.mesh_namespace }} \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```
{:.no-line-numbers}
{% endtab %}
{% endtabs %}

## Step 2: Deploy demo applications

Next, deploy demo applications in two separate namespaces, `kuma-demo` and `kuma-demo-other`:

```bash
kumactl install demo --without-gateway -n kuma-demo | kubectl apply -f -
kumactl install demo --without-gateway -n kuma-demo-other | kubectl apply -f -
```
{:.no-line-numbers}

## Step 3: Verify setup in the GUI

Port-forward the control plane GUI by running:

```bash
kubectl port-forward svc/{{ site.mesh_cp_name }} -n {{ site.mesh_namespace }} 5681:5681
```
{:.no-line-numbers}

Then, open your browser at [http://localhost:5681/gui](http://localhost:5681/gui):

* Click **Meshes** on the sidebar.
* Select the **default** mesh.
* Go to the **Services** tab.

You should see services from both `kuma-demo` and `kuma-demo-other` namespaces.

Verify both namespaces have sidecar injection enabled:

```bash
kubectl get namespace kuma-demo -o yaml
kubectl get namespace kuma-demo-other -o yaml
```
{:.no-line-numbers}

Both namespaces should have the label:

```yaml
kuma.io/sidecar-injection: enabled
```
{:.no-line-numbers}

## Step 4: Reinstall {{ Kuma }} with namespace restrictions

Now reinstall {{ Kuma }} to restrict permissions to only the `kuma-demo` namespace:

{% cpinstall namespaceAllowList %}
namespaceAllowList={kuma-demo}
{% endcpinstall %}

Restart pods in both demo namespaces:

```bash
kubectl rollout restart deployment -n kuma-demo
kubectl rollout restart deployment -n kuma-demo-other
```
{:.no-line-numbers}

## Step 5: Confirm restricted access

Open the GUI again at [http://localhost:5681/gui](http://localhost:5681/gui):

* Go to **Meshes** → **default** → **Services**.
* Now only services from the `kuma-demo` namespace should appear.

Check `RoleBindings` in both namespaces:

```bash
kubectl get rolebindings -n kuma-demo
kubectl get rolebindings -n kuma-demo-other
```
{:.no-line-numbers}

You should see the `kuma-control-plane-writer` binding present only in `kuma-demo` namespace, but not in `kuma-demo-other`.
