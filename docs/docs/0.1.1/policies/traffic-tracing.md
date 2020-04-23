# Traffic Tracing

::: warning
This is a proposed policy not in GA yet. You can setup tracing manually by leveraging the [`ProxyTemplate`](../proxy-template) policy and the low-level Envoy configuration. Join us on [Slack](/community) to share your tracing requirements.
:::

The proposed policy will enable `tracing` on the [`Mesh`](../mesh) level by adding a `tracing` field.

On Universal:

```yaml
type: Mesh
name: default
tracing:
  enabled: true
  type: zipkin
  address: zipkin.srv:9000
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  tracing:
    enabled: true
    type: zipkin
    address: zipkin.srv:9000
```