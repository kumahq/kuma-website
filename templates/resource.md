---
title: {{ .Env.RESOURCE_NAME }}
description: TODO: Add description
# Use exactly 3 keywords for optimal Algolia search performance
keywords:
  - {{ .Env.RESOURCE_NAME }}
  - resource
  - reference
content_type: reference
category: resource
---

TODO: Add introduction

## Examples

### Basic {{ .Env.RESOURCE_NAME }}

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: {{ .Env.RESOURCE_NAME }}
metadata:
  name: example
```

{% endtab %}
{% tab Universal %}

```yaml
type: {{ .Env.RESOURCE_NAME }}
name: example
```

{% endtab %}
{% endtabs %}

## See also

- [Related doc](/docs/{{ "{{" }} page.release {{ "}}" }}/path)

## All options

{% schema_viewer kuma.io_{{ .Env.RESOURCE_NAME | strings.ToLower }}s type=crd %}
