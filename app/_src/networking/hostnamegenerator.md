---
title: HostnameGenerator
---

{% warning %}
This resource is experimental!
{% endwarning %}

A `HostnameGenerator` provides

- a template to generate hostnames from properties of `MeshServices` and `MeshExternalServices`
- a selector that defines for which `MeshServices` and `MeshExternalServices` this generator runs

{% policy_yaml hg-all %}
```yaml
type: HostnameGenerator
name: all
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kuma-demo
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.mesh{% endraw %}"
```
{% endpolicy_yaml %}

## Template

A template is a [golang text template](https://pkg.go.dev/text/template).
It is run with the function `label` to retrieve labels of the `MeshService` or `MeshExternalService`
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
  template: "{% raw %}{{ .DisplayName }}.{{ .Namespace }}.{{ .Mesh }}.{{ label "team" }}.mesh{% endraw %}"
```

the generated hostname would be:

```
redis.kuma-demo.products.backend.mesh
```

Currently the generated hostname points to the first VIP known for the
`MeshService`.

## Status

Every generated hostname is recorded on the `MeshService` status in `addresses`:

```yaml
status:
  addresses:
    - hostname: redis.kuma-demo.mesh
      origin: HostnameGenerator
      hostnameGeneratorRef:
        coreName: all
```
