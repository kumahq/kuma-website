# Traffic Route

::: warning
This is a proposed policy not in GA yet. You can setup routing manually by leveraging the [`ProxyTemplate`](../proxy-template) policy and the low-level Envoy configuration. Join us on [Slack](/community) to share your routing requirements.
:::

The proposed policy will enable a new `TrafficRoute` policy that can be used to configure both simple and more sophisticated routing rules on the traffic, like blue/green deployments and canary releases.

On Universal:

```yaml
type: TrafficRoute
name: route-1
mesh: default
rules:
  - sources:
      - match:
          service: backend
    destinations:
      - match:
          service: redis
    conf:
      - weight: 90
        destination:
          service: backend
          version: '1.0'
      - weight: 10
        destination:
          service: backend
          version: '2.0'
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficRoute
mesh: default
metadata:
  namespace: default
  name: route-1
spec:
  rules:
    - sources:
      - match:
          service: backend
    destinations:
      - match:
          service: redis
    conf:
      - weight: 90
        destination:
          service: backend
          version: '1.0'
      - weight: 10
        destination:
          service: backend
          version: '2.0'
```