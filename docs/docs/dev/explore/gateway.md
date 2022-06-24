# Gateway

Kuma Gateway is responsible for routing network traffic from outside a Kuma mesh to services inside the mesh. Sometimes communication with services outside of the infrastructure is necessary. The gateway ensures that outside traffic reaches the correct service within the Kuma mesh. Also, the gateway itself can handle security at an entrance to the mesh.

Kuma Gateway deploys as a Kuma [`Dataplane`](../explore/dpp.md), i.e. an instance of the `kuma-dp` process.
Like all Kuma `Dataplanes`, the Kuma Gateway `Dataplane` manages an Envoy proxy process that does the actual network traffic proxying.

We can distinguish two types of gateways:

- delegated: allows users to use any existing gateway like [Kong](https://github.com/Kong/kong).
- builtin: configures the data plane proxy to expose external listeners to drive traffic inside the mesh.

::: warning
Gateways exist within a mesh.
If you have multiple meshes, each mesh requires its own gateway. You can easily connect your meshes together using [cross-mesh gateways](#cross-mesh).
:::

Below visualization shows the difference between delegated and builtin gateways:

Builtin with Kong Gateway to handle the inbound traffic:
<center>
<img src="/images/diagrams/builtin-gateway.webp" alt=""/>
</center>

Delegated with Kong Gateway:
<center>
<img src="/images/diagrams/delegated-gateway.webp" alt="" />
</center>

The blue lines represent traffic not managed by Kuma, which needs to be configured in the Gateway.

## Delegated

The `Dataplane` entity can operate in `gateway` mode. This way you can integrate Kuma with existing API Gateways like [Kong](https://github.com/Kong/kong).

The `gateway` mode lets you skip exposing inbound listeners so it won't be intercepting ingress traffic. When you use a data plane proxy with a service, both inbound traffic to a service and outbound traffic from the service flows through the proxy. In the `gateway` mode, we want inbound traffic to go directly to the gateway, otherwise, clients require certificates that are generated dynamically for communication between services within the mesh. The gateway itself should handle security at an entrance to the mesh.

### Usage

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

Kuma supports most of the ingress controllers. However, the recommended gateway in Kubernetes is [Kong](https://docs.konghq.com/gateway). You can use [Kong ingress controller for Kubernetes](https://docs.konghq.com/kubernetes-ingress-controller/) to implement authentication, transformations, and other functionalities across Kubernetes clusters with zero downtime.
Most ingress controllers require an annotation [`ingress.kubernetes.io/service-upstream=true`](https://docs.konghq.com/kubernetes-ingress-controller/2.1.x/references/annotations/#ingresskubernetesioservice-upstream) on every Kubernetes `Service` to work with Kuma. Kuma automatically injects the annotation for every `Service` in a namespace in a mesh i.e. has `kuma.io/sidecar-injection: enabled` label.

To use the delegated gateway feature, mark your API Gateway's Pod with the `kuma.io/gateway: enabled` annotation. Control plane automatically generates `Dataplane` objects.

For example:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
      ...
```

API Gateway receives Services from:
* one specific zone
* multi-zone

Multi-zone requires exposing a dedicated Kubernetes `Service` object with type `ExternalName`. Control plane creates a DNS entry `externalName` with suffix `.mesh`, which Kuma resolves in internal [service discovery](../../networking/dns).

#### Example setting up Kong Ingress Controller

Follow instructions to setup an echo service reachable through Kong.
These instructions are mostly taken from the [Kong docs](https://docs.konghq.com/kubernetes-ingress-controller/2.1.x/guides/getting-started/).

1. [Install Kuma](../installation/kubernetes.md) on your cluster and have the `default` [namespace labelled with sidecar-injection](dpp-on-kubernetes.md).

2. Install [Kong using helm](https://docs.konghq.com/kubernetes-ingress-controller/2.1.x/deployment/k4k8s/#helm).

3. Start an echo-service:

```shell
kubectl apply -f https://bit.ly/echo-service
```

4. Add an ingress:

```shell
echo "
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /foo
        pathType: ImplementationSpecific
        backend:
          service:
            name: echo
            port:
              number: 80
" | kubectl apply -f -
```

You can access your ingress with `curl -i $PROXY_IP/foo` where `$PROXY_IP` you can retrieve from the service that exposes Kong outside your cluster.

You can check that the sidecar is running by checking the number of containers in each pod:

```shell
kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
echo-5fc5b5bc84-zr9kl                   2/2     Running   0          41m
kong-1645186528-kong-648b9596c7-f2xfv   3/3     Running   2          40m
```

#### Example Gateway in Multi-Zone

In the previous example, we setup an `echo` (that is running on port `80`) and deployed in the `default` namespace.

We will now make sure that this service works correctly with multi-zone. In order to do so, the following `Service` needs to be created manually:

```shell
echo "
apiVersion: v1
kind: Service
metadata:
  name: echo-multizone
  namespace: default
spec:
  type: ExternalName
  externalName: echo.default.svc.80.mesh
" | kubectl apply -f -
```

Finally, we need to create a corresponding Kubernetes `Ingress` that routes `/bar` to the multi-zone service:

```shell
echo "
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-multizone
  namespace: default
spec:
  ingressClassName: kong
  rules:
    - http:
        paths:
          - path: /bar
            pathType: ImplementationSpecific
            backend:
              service:
                name: echo-multizone
                port:
                  number: 80
" | kubectl apply -f -
```

Note that since we are addressing the service by its domain name `echo.default.svc.8080.mesh`, we should always refer to port `80` (this port is only a placeholder and will be automatically replaced with the actual port of the service).

If we want to expose a `Service` in one zone only (as opposed to multi-zone), we can just use the service name in the `Ingress` definition without having to create an `externalName` entry, this is what we did in our first example.

For an in-depth example on deploying Kuma with [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller), please follow this [demo application guide](https://github.com/kumahq/kuma-demo/tree/master/kubernetes).

:::
::: tab "Universal"

On Universal, you can define the `Dataplane` entity like this:

```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  address: 10.0.0.1
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong
  outbound:
    - port: 33033
      tags:
        kuma.io/service: backend
```

When configuring your API Gateway to pass traffic to _backend_ set the url to `http://localhost:33033`

:::
::::

## Builtin

:::warning
The builtin gateway is currently experimental.
:::

The builtin gateway is integrated into the core Kuma control plane.
You can configure gateway listeners and routes to service directly using Kuma policies.

The builtin gateway is configured on a `Dataplane`:

```yaml
type: Dataplane
mesh: default
name: gateway-instance-1
networking:
  address: 127.0.0.1
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

A builtin gateway `Dataplane` does not have either inbound or outbound configuration.

To configure your gateway Kuma has these resources:

- [MeshGateway](../policies/mesh-gateway.md) is used to configure listeners exposed by the gateway
- [MeshGatewayRoute](../policies/mesh-gateway-route.md) is used to configure route to route traffic from listeners to other services.

### Usage

We will set up a simple gateway that exposes a http listener and 2 routes to imaginary services: "frontend" and "api".

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
To ease starting gateways on Kubernetes Kuma comes with a builtin type "MeshGatewayInstance".
This type requests that the control plane create and manage a Kubernetes Deployment and Service suitable for providing service capacity for the Gateway with the matching service tags.

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
spec:
  replicas: 1
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
" | kubectl apply -f -
```

In the example above, the control plane will create a new Deployment in the `gateways` namespace.
This deployment will have the requested number of builtin gateway `Dataplane` pod replicas, which will be configured as part of the service named in the `MeshGatewayInstance` tags.
When a Kuma `MeshGateway` is matched to the `MeshGatewayInstance`, the control plane will also create a new Service to send network traffic to the builtin `Dataplane` pods.
The Service will be of the type requested in the `MeshGatewayInstance`, and its ports will automatically be adjusted to match the listeners on the corresponding `MeshGateway`.
:::
::: tab "Universal"

The first thing you'll need is to create a `Dataplane` object for your gateway:

```yaml
type: Dataplane
mesh: default
name: gateway-instance-1
networking:
  address: 127.0.0.1
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

Note that this gateway has a `kuma.io/service` tag. We will use this to bind policies to configure this gateway.

As we're in universal you now need to run kuma-dp:

```shell
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-gateway \ # this needs to be generated like for regular Dataplane
  --dataplane-file=my-gateway.yaml # the Dataplane resource described above
```

:::
::::

Now that the `Dataplane` is running we can describe the gateway listener:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
  - match:
      kuma.io/service: edge-gateway
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        hostname: foo.example.com
        tags:
          port: http/8080
" | kubectl apply -f -
```

:::
::: tab "Universal"

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
conf:
  listeners:
    - port: 8080
      protocol: HTTP
      hostname: foo.example.com
      tags:
        port: http/8080
```

:::
::::

This policy creates a listener on port 8080 and will receive any traffic which has the `Host` header set to `foo.example.com`.
Notice that listeners have tags like `Dataplanes`. This will be useful when binding routes to listeners.

:::tip
These are Kuma policies so if you are running on multi-zone they need to be created on the Global CP.
See the [dedicated section](../deployments/multi-zone.md) for detailed information.
:::

We will now define our routes which will take traffic and route it either to our `api` or our `frontend` depending on the path of the http request:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayRoute
mesh: default
metadata:
  name: edge-gateway-route
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway
        port: http/8080
  conf:
    http:
      rules:
        - matches:
            - path:
                match: PREFIX
                value: /api
          backends:
            - destination:
                kuma.io/service: api_default_svc_80
        - matches:
            - path:
                match: PREFIX
                value: /
          backends:
            - destination:
                kuma.io/service: frontend_default_svc_80
" | kubectl apply -f -
```

:::
::: tab "Universal"

```yaml
type: MeshGatewayRoute
mesh: default
name: edge-gateway-route
selectors:
  - match:
      kuma.io/service: edge-gateway
      port: http/8080
conf:
  http:
    rules:
      - matches:
          - path:
              match: PREFIX
              value: /api
        backends:
          - destination:
              kuma.io/service: api
      - matches:
          - path:
              match: PREFIX
              value: /
        backends:
          - destination:
              kuma.io/service: frontend
```

:::
::::

Because routes are applied in order of specificity the first route will take precedence over the second one.
So `/api/foo` will go to the `api` service whereas `/asset` will go to the `frontend` service.

### Multi-zone

The Kuma Gateway resource types, `MeshGateway` and `MeshGatewayRoute`, are synced across zones by the Kuma control plane.
If you have a multi-zone deployment, follow existing Kuma practice and create any Kuma Gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it is needed by deploying builtin gateway `Dataplanes` (in Universal zones) or `MeshGatewayInstances` (Kubernetes zones).

### Cross-mesh

Cross-mesh gateways are an experimental feature new in Kuma v1.7.
The `Mesh` abstraction allows users
to encapsulate and isolate services
inside a kind of submesh with its own CA.
With a cross-mesh `MeshGateway`,
you can expose the services of one `Mesh`
to other `Mesh`es by defining an API with `MeshGatewayRoute`s.
All traffic remains inside the Kuma data plane protected by mTLS.

All meshes involved in cross-mesh communication must have mTLS enabled.
To enable cross-mesh functionality for a `MeshGateway` listener,
set the `crossMesh` property.

```
  ...
  mesh: default
  selectors:
    - match:
        kuma.io/service: cross-mesh-gateway
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        crossMesh: true
        hostname: default.mesh
```

#### Hostname

If the listener includes a `hostname` value,
the cross-mesh listener will be reachable
from all `Mesh`es at this `hostname` and `port`.
In this case, the URL `http://default.mesh:8080`.

Otherwise it will be reachable at the host:
`internal.<gateway-name>.<mesh-of-gateway-name>.mesh`.

#### Without transparent proxy

If transparent proxy isn't set up, you'll have to add the listener explicitly as
an outbound to your `Dataplane` objects if you want to access it:

```
  ...
  outbound
  - port: 8080
    tags:
      kuma.io/service: cross-mesh-gateway
      kuma.io/mesh: default
```

#### Limitations

Cross-mesh functionality isn't supported across zones at the
moment but will be in a future release.

The only `protocol` supported is `HTTP`.
Like service to service traffic,
all traffic to the gateway is protected with mTLS
but appears to be HTTP traffic
to the applications inside the mesh.
In the future, this limitation may be relaxed.

There can be only one entry in `selectors`
for a `MeshGateway` with `crossMesh: true`.

### Policy support

Not all Kuma policies are applicable to Kuma Gateway (see table below).
Kuma connection policies are selected by matching the source and destination expressions against sets of Kuma tags.
In the case of Kuma Gateway the source selector is always matched against the Gateway listener tags, and the destination expression is matched against the backend destination tags configured on a Gateway Route.

When a Gateway Route forwards traffic, it may weight the traffic across multiple services.
In this case, matching the destination for a connection policy becomes ambiguous.
Although the traffic is proxied to more than one distinct service, Kuma can only configure the route with one connection policy.
In this case, Kuma employs some simple heuristics to choose the policy.
If all the backend destinations refer to the same service, Kuma will choose the oldest connection policy that has a matching destination service.
However, if the backend destinations refer to different services, Kuma will prefer a connection policy with a wildcard destination (i.e. where the destination service is `*`).

Kuma may select different connection policies of the same type depending on the context.
For example, when Kuma configures an Envoy route, there may be multiple candidate policies (due to the traffic splitting across destination services), but when Kuma configures an Envoy cluster there is usually only a single candidate (because clusters are defined to be a single service).
This can result in situations where different policies (of the same type) are used for different parts of the Envoy configuration.

| Policy                                                    | GatewaySupport |
| --------------------------------------------------------- | -------------- |
| [Circuit Breaker](../policies/circuit-breaker.md)         | Full           |
| [External Services](../policies/external-services.md)     | Full           |
| [Fault Injection](../policies/fault-injection.md)         | Full           |
| [Health Check](../policies/health-check.md)               | Full           |
| [Proxy Template](../policies/proxy-template.md)           | Full           |
| [Rate Limits](../policies/rate-limit.md)                  | Full           |
| [Retries](../policies/retry.md)                           | Full           |
| [Traffic Permissions](../policies/traffic-permissions.md) | Full           |
| [Traffic Routes](../policies/traffic-route.md)            | None           |
| [Traffic Log](../policies/traffic-log.md)                 | Partial        |
| [Timeouts](../policies/timeout.md)                        | Full           |
| [VirtualOutbounds](../policies/virtual-outbound.md)       | None           |

You can find in each policy's dedicated information with regard to builtin gateway support.
