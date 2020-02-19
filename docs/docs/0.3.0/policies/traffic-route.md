# Traffic Route

`TrafficRoute` policy allows you to configure routing rules for L4 traffic, i.e. blue/green deployments and canary releases. 

To route traffic, Kuma matches via tags that we can designate to `Dataplane` resources. In the example below, the redis destination services have been assigned the `version` tag to help with canary deployment. Another common use-case is to add a `env` tag as you separate testing, staging, and production environments' services. For the redis service, this `TrafficRoute` policy assigns a positive weight of 90 to the v1 redis service and a positive weight of 10 to the v2 redis service. Kuma utilizes positive weights in the traffic routing policy, and not percentages. Therefore, Kuma does not check if it adds up to 100. If you want to stop sending traffic to a destination service, change the weight for that service to 0.

On Universal:

```yaml
type: TrafficRoute
name: route-1
mesh: default
sources:
  - match:
      service: backend
destinations:
  - match:
      service: redis
conf:
  - weight: 90
    destination:
      service: redis
      version: '1.0'
  - weight: 10
    destination:
      service: redis
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
  sources:
  - match:
      service: backend
  destinations:
  - match:
      service: redis
  conf:
    - weight: 90
      destination:
        service: redis
        version: '1.0'
    - weight: 10
      destination:
        service: redis
        version: '2.0'
```

The expected outcome is that 1 out of roughly 10 request will be routed to the new version 2.