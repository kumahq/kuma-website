---
title: Progressively rolling out unified resource naming
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}

By default, Envoy resources and stats in {{ Kuma }} use mixed, legacy formats. Names often do not line up with the {{ Kuma }} resources that produced them, which makes dashboards noisy and troubleshooting slower. For example, a query like:

```text
sum:envoy.cluster.upstream_rq.count{service:my-example-service, !envoy_cluster:kuma_*, !envoy_cluster:meshtrace_*, !envoy_cluster:access_log_sink} by {envoy_cluster}.as_count()
```

is not intuitive and does not point cleanly back to the right {{ Kuma }} resource. Different resources and their related stats often look unrelated, even when they describe the same traffic path.

Starting with 2.12, you can adopt a unified resource naming scheme that makes names predictable, consistent, and directly tied to {{ Kuma }} resources. This improves observability, simplifies queries, and makes it much easier to understand what is happening in the mesh.

## Prerequisites

You have completed the [Kubernetes Quickstart]({{ docs }}/quickstart/kubernetes-demo/) and have the demo environment running. This guide assumes you already have the `demo-app` service running from the quickstart.

<!-- vale Google.Headings = NO -->
## Step 1: Create a ContainerPatch
<!-- vale Google.Headings = YES -->

Create and apply a `ContainerPatch` resource that enables unified naming on the sidecar:

```yaml
# containerpatch-unified-naming.yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: enable-feature-unified-resource-naming
  namespace: {{ kuma-system }}
spec:
  sidecarPatch:
  - op: add
    path: /env/-
    value: '{
      "name": "KUMA_DATAPLANE_RUNTIME_UNIFIED_RESOURCE_NAMING_ENABLED",
      "value": "true"
    }'
```

```sh
kubectl apply -f containerpatch-unified-naming.yaml
```

This patch configures every sidecar that references it to set an environment variable that turns on the unified naming feature.

<!-- vale Google.Headings = NO -->
## Step 2: Enable for a single workload
<!-- vale Google.Headings = YES -->

Apply the patch to a workload by annotating its deployment. This lets you enable the feature progressively, service by service.

```sh
kubectl annotate deploy/demo-app kuma.io/container-patches=enable-feature-unified-resource-naming --overwrite
```

To disable later for that workload:

```sh
# set to an empty list
kubectl annotate deploy/demo-app kuma.io/container-patches='' --overwrite

# or remove the annotation entirely
kubectl annotate deploy/demo-app kuma.io/container-patches-
```

<!-- vale Google.Headings = NO -->
## Step 3: Verify the new naming
<!-- vale Google.Headings = YES -->

Inspect the sidecar stats to confirm that unified naming is applied:

```sh
kubectl exec -it deploy/demo-app -- curl -s localhost:9901/stats | grep -i kri
```

You should see entries that map directly to {{ Kuma }} resources, for example:

```text
cluster.kri_msvc_default_us-east-2_kuma-demo_demo-app_http
```

These names show the `MeshService` resource (`demo-app`) and section (`http`) clearly, making them much easier to connect back to the original {{ Kuma }} resource.

You can also look at cluster names for confirmation:

```sh
kubectl exec -it deploy/demo-app -- curl -s localhost:9901/clusters | head -n 50
```

<!-- vale Google.Headings = NO -->
## Step 4: Progressively roll out
<!-- vale Google.Headings = YES -->

1. Start with one service such as `demo-app`.
2. Validate dashboards and alerts and compare metrics before and after.
3. Expand to more services or entire namespaces by annotating additional workloads:

```sh
kubectl annotate deploy/another-app kuma.io/container-patches=enable-feature-unified-resource-naming --overwrite
```

To enable the feature across all workloads in a namespace:

```sh
kubectl annotate deploy --all kuma.io/container-patches=enable-feature-unified-resource-naming --overwrite
```

This staged roll-out allows you to evaluate the new names in your monitoring and alerting systems before switching everything over.

<!-- vale off -->
## Step 5: Choose cluster-wide enablement mode
<!-- vale on -->

<!-- vale Google.Headings = NO -->
### Option A: Default ContainerPatch (keeps per-workload control)
<!-- vale Google.Headings = YES -->

Set a default list of patches the injector applies when a workload does not specify its own list. This approach makes the feature opt-out: it will be applied everywhere unless you explicitly disable it.

<!-- vale off -->
{% cpinstall envVar %}
controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_CONTAINER_PATCHES=enable-feature-unified-resource-naming
{% endcpinstall %}
<!-- vale on -->

Per-workload overrides:

```sh
# disable for a workload
kubectl annotate deploy/demo-app kuma.io/container-patches='' --overwrite

# provide a custom list for a workload
kubectl annotate deploy/demo-app kuma.io/container-patches=my-custom-patch-1,my-custom-patch-2 --overwrite
```

<!-- vale Google.Headings = NO -->
### Option B: Global feature flag (no per-workload override)
<!-- vale Google.Headings = YES -->

Enable unified naming for every injected workload. This makes the feature mandatory and removes the ability to disable it on a per-workload basis.

<!-- vale off -->
{% cpinstall dpFeatures %}
dataPlane.features.unifiedResourceNaming: true
{% endcpinstall %}
<!-- vale on -->

## Benefits of unified naming

| Before                              | After                                                      |
|-------------------------------------|------------------------------------------------------------|
| Mixed legacy and Envoy-native names | Consistent scheme aligned with {{ Kuma }} resources        |
| Hard to correlate stats with owners | Direct mapping back to `MeshService` and related resources |
| Complex, exclusion-heavy queries    | Simple, predictable queries and labels                     |

Unified naming improves traceability and reduces the time required to understand what a stat refers to. With a progressive roll-out, you can safely validate the new scheme in your environment, then move to a cluster-wide roll-out when you are ready.
