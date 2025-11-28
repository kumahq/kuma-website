---
title: HostnameGenerator
description: Reference for HostnameGenerator resource that generates custom DNS hostnames for MeshServices, MeshMultiZoneServices, and MeshExternalServices.
keywords:
  - HostnameGenerator
  - DNS
  - hostname
content_type: reference
category: resource
---

`HostnameGenerator` generates DNS hostnames for service resources using customizable templates. It allows you to define consistent naming patterns for `MeshService`, `MeshMultiZoneService`, and `MeshExternalService` resources based on their properties and labels.

{{site.mesh_product_name}} automatically creates default `HostnameGenerator` resources based on control plane mode and environment to provide familiar DNS patterns. You can create custom generators for specific naming requirements.

{% tip %}
For concepts, default configurations, and usage patterns, see the [HostnameGenerator guide](/docs/{{ page.release }}/networking/hostnamegenerator/).
{% endtip %}

## Spec fields

| Field | Description |
|-------|-------------|
| `selector` | Defines which service resources this generator applies to. Use one of `meshService`, `meshExternalService`, or `meshMultiZoneService`. |
| `selector.meshService.matchLabels` | Match `MeshService` resources by labels. All specified labels must match. |
| `selector.meshExternalService.matchLabels` | Match `MeshExternalService` resources by labels. All specified labels must match. |
| `selector.meshMultiZoneService.matchLabels` | Match `MeshMultiZoneService` resources by labels. All specified labels must match. |
| `template` | [Go text template](https://pkg.go.dev/text/template) for generating hostnames. Required field. |
| `extension` | Plugin configuration for custom hostname generation logic. Optional. |
| `extension.type` | Type identifier for the extension plugin. |
| `extension.config` | Freeform configuration passed to the extension. |

### Template variables

The template has access to:

- `.DisplayName` - Resource name in original zone
- `.Namespace` - Resource namespace (Kubernetes only)
- `.Zone` - Zone where resource originated
- `.Mesh` - Mesh name
- `label "key"` - Function to retrieve resource labels

## Status fields

Status is managed by {{site.mesh_product_name}} on service resources that have generated hostnames:

| Field | Description |
|-------|-------------|
| `addresses[].hostname` | Generated hostname. |
| `addresses[].origin` | Set to `HostnameGenerator`. |
| `addresses[].hostnameGeneratorRef.coreName` | Name of the `HostnameGenerator` that created this hostname. |

## Examples

### Basic hostname generator for MeshService

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: local-mesh-service
  namespace: {{site.mesh_namespace}}
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.svc.mesh.local{% endraw %}"
```

{% endtab %}
{% tab Universal %}

```yaml
type: HostnameGenerator
name: local-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.svc.mesh.local{% endraw %}"
```

{% endtab %}
{% endtabs %}

### hostname generator with namespace and zone

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: synced-kube-mesh-service
  namespace: {{site.mesh_namespace}}
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        kuma.io/env: kubernetes
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```

{% endtab %}
{% tab Universal %}

```yaml
type: HostnameGenerator
name: synced-kube-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        kuma.io/env: kubernetes
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```

{% endtab %}
{% endtabs %}

This generates hostnames like `redis.kuma-demo.svc.east.mesh.local` for a `MeshService` named `redis` in namespace `kuma-demo` from zone `east`.

### hostname generator with label function

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: custom-headless
  namespace: {{site.mesh_namespace}}
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/is-headless-service: "true"
  template: "{% raw %}{{ label \"statefulset.kubernetes.io/pod-name\" }}.{{ label \"k8s.kuma.io/service-name\" }}.{{ .Namespace }}.svc.mesh.local{% endraw %}"
```

{% endtab %}
{% tab Universal %}

```yaml
type: HostnameGenerator
name: custom-with-labels
spec:
  selector:
    meshService:
      matchLabels:
        team: backend
  template: "{% raw %}{{ .DisplayName }}.{{ label \"environment\" }}.mesh.local{% endraw %}"
```

{% endtab %}
{% endtabs %}

### hostname generator for MeshExternalService

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: mesh-external-service
  namespace: {{site.mesh_namespace}}
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```

{% endtab %}
{% tab Universal %}

```yaml
type: HostnameGenerator
name: mesh-external-service
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```

{% endtab %}
{% endtabs %}

### hostname generator for MeshMultiZoneService

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: mesh-multi-zone-service
  namespace: {{site.mesh_namespace}}
spec:
  selector:
    meshMultiZoneService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.mzsvc.mesh.local{% endraw %}"
```

{% endtab %}
{% tab Universal %}

```yaml
type: HostnameGenerator
name: mesh-multi-zone-service
spec:
  selector:
    meshMultiZoneService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.mzsvc.mesh.local{% endraw %}"
```

{% endtab %}
{% endtabs %}

## See also

- [HostnameGenerator guide](/docs/{{ page.release }}/networking/hostnamegenerator/)
- [MeshService resource](/docs/{{ page.release }}/resources/meshservice/)
- [MeshExternalService resource](/docs/{{ page.release }}/resources/meshexternalservice/)
- [MeshMultiZoneService resource](/docs/{{ page.release }}/resources/meshmultizoneservice/)
- [DNS documentation](/docs/{{ page.release }}/networking/dns/)

## All options

{% schema_viewer kuma.io_hostnamegenerators type=crd %}
