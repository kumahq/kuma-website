---
title: Workload
description: Reference for the Workload resource, which represents a logical grouping of data plane proxies with status reporting for connected and healthy instances.
keywords:
  - Workload
  - data plane
  - status
content_type: reference
category: resource
---

The `Workload` resource represents a logical grouping of [data plane proxies](/docs/{{ page.release }}/production/dp-config/dpp/) that share the same workload identifier. {{site.mesh_product_name}} automatically creates and manages this resource on Kubernetes when data plane proxies reference a workload via the `kuma.io/workload` annotation.

Use Workload resources to:

- Monitor connected and healthy data plane proxies per workload
- Group data plane proxies by workload identifier for observability
- Integrate with [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/) for workload-based identity assignment

{% warning %}
Workload resources are automatically managed by {{site.mesh_product_name}}. Manual creation is not supported on Kubernetes. The resource is automatically created when data plane proxies with a `kuma.io/workload` annotation are deployed, and deleted when no data plane proxies reference it.
{% endwarning %}

## Status fields

The Workload status provides statistics about associated data plane proxies:

| Field | Description |
|-------|-------------|
| `status.dataplaneProxies.connected` | Number of connected data plane proxies for this workload. |
| `status.dataplaneProxies.healthy` | Number of healthy data plane proxies for this workload. |
| `status.dataplaneProxies.total` | Total number of data plane proxies for this workload. |

{% tip %}
All data plane proxies referencing a Workload must belong to the same mesh. If data plane proxies in multiple meshes reference the same workload name, {{site.mesh_product_name}} will emit a warning event and skip Workload generation.
{% endtip %}

## Examples

### Workload created automatically

When you deploy a pod with the `kuma.io/workload` annotation, {{site.mesh_product_name}} automatically creates a Workload resource:

{% tabs %}
{% tab Kubernetes %}

**Pod annotation:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-app
  annotations:
    kuma.io/workload: demo-workload
```

**Automatically created Workload:**

```yaml
apiVersion: kuma.io/v1alpha1
kind: Workload
metadata:
  name: demo-workload
  namespace: default
  labels:
    kuma.io/mesh: default
    kuma.io/managed-by: k8s-controller
spec: {}
status:
  dataplaneProxies:
    connected: 3
    healthy: 3
    total: 3
```

{% endtab %}
{% tab Universal %}

Workload resources are only available on Kubernetes.

{% endtab %}
{% endtabs %}

### Workload with MeshIdentity

Use Workload with MeshIdentity to assign identity based on the workload identifier:

{% tabs %}
{% tab Kubernetes %}

**MeshIdentity:**

{% raw %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: workload-identity
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  type: spiffe
  identityRef:
    type: workload
    tags:
      kuma.io/workload: demo-workload
  config:
    trustDomain: example.com
    path:
      template: /workload/{{ .Workload }}
```

{% endraw %}

**Result:** Data plane proxies with `kuma.io/workload: demo-workload` receive SPIFFE ID: `spiffe://example.com/workload/demo-workload`

{% endtab %}
{% tab Universal %}

Workload resources are only available on Kubernetes.

{% endtab %}
{% endtabs %}

### Checking Workload status

Monitor workload health using kubectl:

{% tabs %}
{% tab Kubernetes %}

```sh
kubectl get workloads -n default
```

```
NAME            MESH      AGE
demo-workload   default   5m
```

Get detailed status:

```sh
kubectl get workload demo-workload -n default -o yaml
```

{% endtab %}
{% tab Universal %}

Workload resources are only available on Kubernetes.

{% endtab %}
{% endtabs %}

## Workload label management

The `kuma.io/workload` label is automatically managed by {{site.mesh_product_name}}:

- **Automatic assignment:** The workload label is automatically derived from pod labels (configurable via `runtime.kubernetes.workloadLabels` in the control plane configuration)
- **Manual assignment:** Set via the `kuma.io/workload` annotation on pods
- **Protection:** Cannot be manually set as a label on pods; {{site.mesh_product_name}} will reject pod creation/updates with this label

{% warning %}
The `kuma.io/workload` annotation on data plane proxies must match exactly with the Workload resource name. All data plane proxies referencing a Workload must be in the same namespace and mesh.
{% endwarning %}

## Limitations

- **Kubernetes only:** Workload resources are only available on Kubernetes. Universal deployments do not support this resource.
- **Single mesh:** All data plane proxies referencing a workload must belong to the same mesh.
- **Automatic lifecycle:** Cannot be manually created or modified. The resource is fully managed by the k8s-controller.

## See also

- [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/)
- [Data plane proxy configuration](/docs/{{ page.release }}/production/dp-config/dpp/)
- [Data plane proxy authentication](/docs/{{ page.release }}/production/secure-deployment/dp-auth/)

## All options

{% schema_viewer kuma.io_workloads type=crd %}
