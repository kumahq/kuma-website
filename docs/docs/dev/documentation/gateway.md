# Gateway

The `Dataplane` entity can operate in `gateway` mode. This way you can integrate Kuma with existing API Gateways like [Kong](https://github.com/Kong/kong).

When you use a data plane proxy with a service, both inbound traffic to a service and outbound traffic from the service flows through the proxy.
API Gateway should be deployed as any other service within the mesh. However, in this case we want inbound traffic to go directly to API Gateway,
otherwise clients would have to be provided with certificates that are generated dynamically for communication between services within the mesh.
Security for an entrance to the mesh should be handled by API Gateway itself.

Gateway mode lets you skip exposing inbound listeners so it won't be intercepting ingress traffic.

## Universal

On Universal, you can define the `Dataplane` entity like this:

```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  address: 10.0.0.1
  gateway:
    tags:
      kuma.io/service: kong
  outbound:
  - port: 33033
    tags:
      kuma.io/service: backend
```

When configuring your API Gateway to pass traffic to _backend_ set the url to `http://localhost:33033`

## Kubernetes

On Kubernetes, `Dataplane` entities are automatically generated. To inject gateway Dataplane, mark your API Gateway's Pod with `kuma.io/gateway: enabled` annotation. Here is example with Kong for Kubernetes:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ingress-kong
  name: ingress-kong
  namespace: kong
spec:
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
    spec:
      containers:
        image: kong:1.3
      ...
```

The optimal gateway in Kubernetes mode would be Kong. You can use [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller) to implement authentication, transformations, and other functionalities across Kubernetes clusters with zero downtime. Using [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller) with Kuma requires an annotation on every `Service` that you want to pass traffic to [`ingress.kubernetes.io/service-upstream=true`](https://docs.konghq.com/kubernetes-ingress-controller/2.1.x/references/annotations/#ingresskubernetesioservice-upstream). This is automatically injected by Kuma for every Kubernetes service that is in a namespace part of the mesh i.e. has `kuma.io/sidecar-injection: enabled` label.

Services can be exposed to an API Gateway in one specific zone, or in multi-zone. For the latter, we need to expose a dedicated Kubernetes `Service` object with type `ExternalName`, which sets the `externalName` to the `.mesh` DNS record for the particular service that we want to expose, that will be resolved by Kuma's internal [service discovery](../../networking/dns).

### Example Gateway in Multi-Zone

In this Kubernetes example, we will be exposing a service named `frontend-api` (that is running on port `8080`) and deployed in the `kuma-demo` namespace. In order to do so, the following `Service` needs to be created manually:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: kuma-demo
spec:
  type: ExternalName
  externalName: frontend-api.kuma-demo.svc.8080.mesh
```

Finally, we need to create the corresponding Kubernetes `Ingress` resource:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: frontend
  namespace: kuma-demo
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: frontend
          servicePort: 80
```

Note that since we are addressing the service by its domain name `frontend-api.kuma-demo.svc.8080.mesh`, we should always refer to port `80` (this port is only a placeholder and will be automatically replaced with the actual port of the service).

:::tip
If we want to expose a `Service` in one zone only (as opposed to multi-zone), we can just use the service name in the `Ingress` definition without having to create an `externalName` entry.
:::

For an in-depth example on deploying Kuma with [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller), please follow this [demo application guide](https://github.com/kumahq/kuma-demo/tree/master/kubernetes).
