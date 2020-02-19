# Traffic Permissions

Traffic Permissions allow you to determine security rules for services that consume other services via their [Tags](../documentation/dps-and-data-model/#tags). It is a very useful policy to increase security in the Mesh and compliance in the organization.

You can determine what source services are **allowed** to consume specific destination services. The `service` field is mandatory in both `sources` and `destinations`.

::: warning
In Kuma 0.1.1 the `sources` field only allows for `service` and only `service` will be enforced. This limitation will disappear in the next version of Kuma.
:::

In the example below, the `destinations` includes not only the `service` property, but also an additional `version` tag. You can include any arbitrary tags to any [`Dataplane`](../documentation/dps-and-data-model/#dataplane-specification)

On Universal:

```yaml
type: TrafficPermission
name: permission-1
mesh: default
rules:
  - sources:
    - match:
        service: backend
    destinations:
    - match:
        service: redis
        version: "5.0"
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  namespace: default
  name: permission-1
spec:
  rules:
    - sources:
      - match:
          service: backend
      destinations:
      - match:
          service: redis
          version: "5.0"
```

::: tip
**Match-All**: You can match any value of a tag by using `*`, like `version: '*'`.
:::