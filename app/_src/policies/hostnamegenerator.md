---
title: HostnameGenerator
---

{% warning %}
This resource is experimental!
{% endwarning %}

A `HostnameGenerator` provides

- a template to generate hostnames from properties of `MeshServices`
- a selector that defines for which `MeshServices` this generator runs

```yaml
type: HostnameGenerator
name: all
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kuma-demo
  template: "{{ .Name }}.{{ .Namespace }}.mesh"
```

## Template

A template is a [golang text template](https://pkg.go.dev/text/template).
It is run with the name, namespace and mesh as input and function `label` to retrieve labels of the `MeshService`.

For exampe, given:

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
  template: "{{ .Name }}.{{ .Namespace }}.{{ .Mesh }}.{{ label "team" }}.mesh"
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
        name: all
```
