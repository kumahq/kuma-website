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

The `Workload` resource represents a logical grouping of [data plane proxies](/docs/{{ page.release }}/production/dp-config/dpp/) that share the same workload identifier. {{site.mesh_product_name}} automatically creates and manages this resource when data plane proxies have a `kuma.io/workload` label. On Kubernetes, this label is set via a `kuma.io/workload` annotation on Pods. On Universal, the label is set directly on the Dataplane resource.

Use Workload resources to:

- Monitor connected and healthy data plane proxies per workload
- Group data plane proxies by workload identifier for observability
- Integrate with [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/) for workload-based identity assignment

{% warning %}
Workload resources are automatically managed by {{site.mesh_product_name}}. Manual creation is not supported. The resource is automatically created when data plane proxies with a `kuma.io/workload` label are deployed, and deleted when no data plane proxies reference it.
{% endwarning %}

{% tip %}
All data plane proxies referencing a Workload must belong to the same mesh. If data plane proxies in multiple meshes reference the same workload name, {{site.mesh_product_name}} will emit a warning event and skip Workload generation.
{% endtip %}

## Examples

### Workload created automatically

When you deploy a data plane proxy with the `kuma.io/workload` label, {{site.mesh_product_name}} automatically creates a Workload resource:

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

**Dataplane with workload label:**

```yaml
type: Dataplane
mesh: default
name: demo-app
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      tags:
        kuma.io/service: demo-service
        kuma.io/workload: demo-workload
```

**Automatically created Workload:**

```yaml
type: Workload
mesh: default
name: demo-workload
status:
  dataplaneProxies:
    connected: 3
    healthy: 3
    total: 3
```

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
  selector:
    dataplane:
      matchLabels:
        kuma.io/workload: demo-workload
  spiffeID:
    trustDomain: example.com
    path: "/workload/{{ .Workload }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
```

{% endraw %}

**Result:** Data plane proxies with `kuma.io/workload: demo-workload` receive SPIFFE ID: `spiffe://example.com/workload/demo-workload`

{% endtab %}
{% tab Universal %}

**MeshIdentity:**

{% raw %}

```yaml
type: MeshIdentity
mesh: default
name: workload-identity
spec:
  selector:
    dataplane:
      matchLabels:
        kuma.io/workload: demo-workload
  spiffeID:
    trustDomain: example.com
    path: "/workload/{{ .Workload }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      autogenerate:
        enabled: true
```

{% endraw %}

**Result:** Data plane proxies with `kuma.io/workload: demo-workload` receive SPIFFE ID: `spiffe://example.com/workload/demo-workload`

{% endtab %}
{% endtabs %}

### Checking workload status

Monitor workload health:

{% tabs %}
{% tab Kubernetes %}

```sh
kubectl get workloads -n default
```

```text
NAME            MESH      AGE
demo-workload   default   5m
```

Get detailed status:

```sh
kubectl get workload demo-workload -n default -o yaml
```

{% endtab %}
{% tab Universal %}

```sh
kumactl get workloads --mesh default
```

```text
NAME            MESH      AGE
demo-workload   default   5m
```

Get detailed status:

```sh
kumactl get workload demo-workload --mesh default -o yaml
```

{% endtab %}
{% endtabs %}

## Workload label management

The `kuma.io/workload` label determines which Workload resource a data plane proxy belongs to:

**On Kubernetes:**

- **Automatic assignment:** The workload label is automatically derived from pod labels (configurable via `runtime.kubernetes.workloadLabels` in the control plane configuration)
- **Manual assignment:** Set via the `kuma.io/workload` annotation on pods
- **Protection:** Cannot be manually set as a label on pods; {{site.mesh_product_name}} will reject pod creation/updates with this label

**On Universal:**

- Set the `kuma.io/workload` label directly in the Dataplane resource's inbound tags

{% warning %}
The `kuma.io/workload` label on data plane proxies must match exactly with the Workload resource name. All data plane proxies referencing a Workload must be in the same mesh.
{% endwarning %}

## Limitations

- **Single mesh:** All data plane proxies referencing a workload must belong to the same mesh.
- **Automatic lifecycle:** Cannot be manually created or modified. The resource is fully managed by the control plane.

## See also

- [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/)
- [Data plane proxy configuration](/docs/{{ page.release }}/production/dp-config/dpp/)
- [Data plane proxy authentication](/docs/{{ page.release }}/production/secure-deployment/dp-auth/)

## All options

{% schema_viewer kuma.io_workloads type=crd %}
