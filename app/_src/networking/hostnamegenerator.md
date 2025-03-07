---
title: HostnameGenerator
---

{% if_version lte:2.8.x %}
{% warning %}
This resource is experimental!
{% endwarning %}
{% endif_version %}

A `HostnameGenerator` provides

- a template to generate hostnames from properties of `MeshServices`, `MeshMultiZoneService`, and `MeshExternalServices`
- a selector that defines for which `MeshServices`, `MeshMultiZoneService`, and `MeshExternalServices` this generator runs

## Defaults

{{site.mesh_product_name}} ships with default HostnameGenerators depending on the control plane mode and storage type.

### Local MeshService in Universal zone

The following policy is automatically created on a zone control plane running in the Universal mode.
It creates a hostname for each `MeshService` created in a zone.
For example, `MeshService` of name `redis` would obtain `redis.svc.mesh.local` hostname.

```yaml
type: HostnameGenerator
name: local-universal-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.svc.mesh.local{% endraw %}"
```


### Local MeshExternalService

The following policy is automatically created on a zone control plane.
It creates a hostname for each `MeshExternalService` created in a zone.
For example, `MeshExternalService` of name `aurora` would obtain `aurora.extsvc.mesh.local` hostname.

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: local-mesh-external-service
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshService from Kubernetes zone

The following policies are automatically created on a global control plane and synced to all zones.

The first creates a hostname for each `MeshService` synced from another Kubernetes zone.
For example, `MeshService` of name `redis` and namespace `redis-system` from zone `east` would obtain `redis.redis-system.svc.east.mesh.local`

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-kube-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        k8s.kuma.io/is-headless-service: false
        kuma.io/env: kubernetes
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

The second creates a hostname for each `MeshService` synced from another Kubernetes zone that were created from a headless `Service`.
For example, instance `redis-0` of `MeshService` of name `redis` and namespace `redis-system` from zone `east` would obtain `redis-0.redis.redis-system.svc.east.mesh.local`

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-headless-kube-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        k8s.kuma.io/is-headless-service: true
        kuma.io/env: kubernetes
  template: "{% raw %}{{ label 'statefulset.kubernetes.io/pod-name' }}.{{ label 'k8s.kuma.io/service-name' }}.{{ .Namespace }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshService from Universal zone

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshService` synced from another Universal zone.
For example, `MeshService` of name `redis` from zone `west` would obtain `redis.svc.west.mesh.local`

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-universal-mesh-service
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/origin: global
        kuma.io/env: universal
  template: "{% raw %}{{ .DisplayName }}.svc.{{ .Zone }}.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

### Synced MeshMultiZoneService from a global control plane

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshMultiZoneService` synced from a global control plane.
For example, `MeshMultiZoneService` of name `redis` would obtain `redis.mzsvc.mesh.local`

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-mesh-multi-zone-service
spec:
  selector:
    meshMultiZoneService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.mzsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}


### Synced MeshExternalService from a global control plane

The following policy is automatically created on a global control plane and synced to all zones.
It creates a hostname for each `MeshExternalService` synced from a global control plane.
For example, `MeshExternalService` of name `aurora` would obtain `aurora.extsvc.mesh.local`

{% policy_yaml %}
```yaml
type: HostnameGenerator
name: synced-mesh-external-service
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: global
  template: "{% raw %}{{ .DisplayName }}.extsvc.mesh.local{% endraw %}"
```
{% endpolicy_yaml %}

## Template

A template is a [golang text template](https://pkg.go.dev/text/template).
It is run with the function `label` to retrieve labels of the `MeshService`, `MeshMultiZoneService` or `MeshExternalService`
as well as the following attributes:

* `.DisplayName`: the name of the resource in its original zone
* `.Namespace`: the namespace of the resource in its original zone, if kubernetes
* `.Zone`: the zone of the resource
* `.Mesh`: the mesh of the resource

For example, given:

```yaml
kind: MeshService
metadata:
  name: redis
  namespace: kuma-demo
  labels:
    kuma.io/mesh: products
    team: backend
    k8s.kuma.io/service-name: redis
    k8s.kuma.io/namespace: kuma-demo
```

and

```
template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.{{ .Mesh }}.{{ label "team" }}.mesh.local{% endraw %}"
```

the generated hostname would be:

```
redis.kuma-demo.products.backend.mesh.local
```

The generated hostname points to the first VIP known for the `MeshService`.

## Status

Every generated hostname is recorded on the `MeshService` status in `addresses`:

```yaml
status:
  addresses:
    - hostname: redis.kuma-demo.svc.east.mesh.local
      origin: HostnameGenerator
      hostnameGeneratorRef:
        coreName: synced-kube-mesh-service
```
