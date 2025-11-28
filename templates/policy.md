---
title: {{ .Env.POLICY_NAME }}
description: TODO: Add description
# Use exactly 3 keywords for optimal Algolia search performance
keywords:
  - {{ .Env.POLICY_NAME }}
  - TODO
  - TODO
content_type: reference
category: policy
---

TODO: Add introduction explaining the policy purpose.

## Configuration

<!-- Document each configuration field with:

### fieldName

Description of field purpose and behavior.

**Type:** `type` | **Required:** Yes/No | **Default:** `value`

#### nestedField (if applicable)

-->

## Examples

### Outbound traffic configuration

{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: {{ .Env.POLICY_NAME }}
name: example-outbound
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
      default:
        # TODO: Add configuration
```
{% endpolicy_yaml %}

### Inbound traffic configuration

{% policy_yaml namespace=kuma-demo %}
```yaml
type: {{ .Env.POLICY_NAME }}
name: example-inbound
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  rules:
    - default:
        # TODO: Add configuration
```
{% endpolicy_yaml %}

## Defaults

<!-- Optional: Add table with default values if applicable

| Property | Default |
|----------|---------|
| `field`  | `value` |

-->

## See also

- [Related policy](/docs/{{ "{{" }} page.release {{ "}}" }}/policies/relatedpolicy)

## All policy options

{% schema_viewer {{ .Env.POLICY_NAME }}s %}
