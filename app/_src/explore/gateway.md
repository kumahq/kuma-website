---
title: Gateway
---

When services need to receive traffic from the outside, commonly called North/South, the {{site.mesh_product_name}} Gateway enables routing network traffic from outside a {{site.mesh_product_name}} mesh to services inside the mesh. The gateway is also responsible for security at the entrance of the Mesh.

{{site.mesh_product_name}} Gateway deploys as a {{site.mesh_product_name}} [`Dataplane`](/docs/{{ page.release }}/production/dp-config/dpp/), that's an instance of the `kuma-dp` process.
Like all {{site.mesh_product_name}} `Dataplanes`, the {{site.mesh_product_name}} Gateway `Dataplane` manages an Envoy proxy process that does the actual network traffic proxying.

You can distinguish two types of gateways:

- delegated: Allows users to use any existing gateway like [Kong](https://github.com/Kong/kong).
- builtin: Configures the data plane proxy to expose external listeners to drive traffic inside the mesh.

{% warning %}
Gateways exist within a mesh.
If you have multiple meshes, each mesh requires its own gateway. You can easily connect your meshes together using [cross-mesh gateways](#cross-mesh).
{% endwarning %}

Below visualization shows the difference between delegated and builtin gateways:

Builtin with Kong Gateway to handle the inbound traffic:
<center>
<img src="/assets/images/diagrams/builtin-gateway.webp" alt=""/>
</center>

Delegated with Kong Gateway:
<center>
<img src="/assets/images/diagrams/delegated-gateway.webp" alt="" />
</center>

The blue lines represent traffic not managed by {{site.mesh_product_name}}, which needs configuring in the Gateway.

## Delegated

The `Dataplane` entity can operate in `gateway` mode. This way you can integrate {{site.mesh_product_name}} with existing API Gateways like [Kong](https://github.com/Kong/kong).

The `gateway` mode lets you skip exposing inbound listeners so it won't be intercepting ingress traffic. When you use a data plane proxy with a service, both inbound traffic to a service and outbound traffic from the service flows through the proxy. In the `gateway` mode, you want inbound traffic to go directly to the gateway, otherwise, clients require dynamically generated certificates for communication between services within the mesh. The gateway itself should handle security at an entrance to the mesh.

### Usage

{% tabs %}
{% tab Kubernetes %}

{{site.mesh_product_name}} supports most of the ingress controllers. However, the recommended gateway in Kubernetes is [Kong](https://docs.konghq.com/gateway). You can use [Kong ingress controller for Kubernetes](https://docs.konghq.com/kubernetes-ingress-controller/) to implement authentication, transformations, and other functionalities across Kubernetes clusters with zero downtime.
Most ingress controllers require an annotation [`ingress.kubernetes.io/service-upstream=true`](https://docs.konghq.com/kubernetes-ingress-controller/3.1.x/reference/annotations/#ingresskubernetesioservice-upstream) on every Kubernetes `Service` to work with {{site.mesh_product_name}}. {{site.mesh_product_name}} automatically injects the annotation for every `Service` in a namespace in a mesh that has `kuma.io/sidecar-injection: enabled` label.

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

Multi-zone requires exposing a dedicated Kubernetes `Service` object with type `ExternalName`. Control plane creates a DNS entry `externalName` with suffix `.mesh`, which {{site.mesh_product_name}} resolves in internal [service discovery](/docs/{{ page.release }}/networking/dns).

#### Example setting up Kong Ingress Controller

Follow instructions to setup an echo service reachable through Kong.
These instructions are mostly taken from the [Kong docs](https://docs.konghq.com/kubernetes-ingress-controller/3.1.x/get-started/).

1. [Install {{site.mesh_product_name}}](/docs/{{ page.release }}/production/use-mesh/) on your cluster and have the `default`[namespace labelled with sidecar-injection](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/).

2. Install [Kong using Helm](https://docs.konghq.com/kubernetes-ingress-controller/3.1.x/install/helm/).

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

In the previous example, you setup an `echo`, that's running on port `80`, and deployed in the `default` namespace.

Now make sure that this service works correctly with multi-zone. In order to do so, create `Service` manually:

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

Finally, you need to create a corresponding Kubernetes `Ingress` that routes `/bar` to the multi-zone service:

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

Note that since you are addressing the service by its domain name `echo.default.svc.8080.mesh`, you should always refer to port `80`. This port is only a placeholder and is automatically replaced with the actual port of the service.

If you want to expose a `Service` in one zone only, as opposed to multi-zone, you can just use the service name in the `Ingress` definition without having to create an `externalName` entry, this is what you did in your first example.

For an in-depth example on deploying {{site.mesh_product_name}} with [Kong for Kubernetes](https://github.com/Kong/kubernetes-ingress-controller), please follow this [demo application guide](https://github.com/kumahq/kuma-demo/tree/master/kubernetes).

{% endtab %}
{% tab Universal %}

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

{% endtab %}
{% endtabs %}

## Builtin

The builtin gateway is integrated into the core {{site.mesh_product_name}} control plane.
You can configure gateway listeners and routes to service directly using {{site.mesh_product_name}} policies.

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

To configure your gateway {{site.mesh_product_name}} has these resources:

- [MeshGateway](/docs/{{ page.release }}/policies/meshgateway) is used to configure listeners exposed by the gateway
- [MeshGatewayRoute](/docs/{{ page.release }}/policies/meshgatewayroute) is used to configure route to route traffic from listeners to other services.

{% tip %}
{{site.mesh_product_name}} gateways are configured with the [Envoy best practices for edge proxies](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge).
{% endtip %}

### Usage

You can create and configure a gateway that listens for traffic from outside of your mesh
and forwards it to the {% if_version gte:2.6.x %}[demo app frontend](/docs/{{ page.release }}/quickstart/kubernetes-demo/){% endif_version %}{% if_version lte:2.5.x %}[demo app frontend](/docs/{{ page.release }}/quickstart/kubernetes/){% endif_version %}.

{% tabs %}
{% tab Kubernetes %}

To ease starting gateways on Kubernetes, {{site.mesh_product_name}} comes with a builtin type `MeshGatewayInstance`.

{% tip %}
This resource launches `kuma-dp` in your cluster.
If you are running a multi-zone Kuma, `MeshGatewayInstance` needs to be created in a specific zone, not the global cluster.
See the [dedicated section](#multi-zone) for using builtin gateways on
multi-zone.
{% endtip %}

This type requests that the control plane create and manage a Kubernetes `Deployment` and `Service`
suitable for providing service capacity for the `MeshGateway` with the matching `kuma.io/service` tag.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
```

See [the `MeshGatewayInstance` docs](/docs/{{ page.release }}/policies/meshgatewayinstance) for more.
{% endtab %}
{% tab Universal %}

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

Note that this gateway has a `kuma.io/service` tag. Use this to bind policies to configure this gateway.

As you're in universal you now need to run `kuma-dp`:

```shell
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-gateway \ # this needs to be generated like for regular Dataplane
  --dataplane-file=my-gateway.yaml # the Dataplane resource described above
```

{% endtab %}
{% endtabs %}

Now let's create a `MeshGateway` to configure the listeners:

{% tabs %}
{% tab Kubernetes %}

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
          port: http-8080
" | kubectl apply -f -
```

{% endtab %}
{% tab Universal %}

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
        port: http-8080
```

{% endtab %}
{% endtabs %}

The `MeshGateway` creates a listener on port 8080 and will accept any traffic which has the `Host` header set to `foo.example.com`.
Notice that listeners have tags like `Dataplanes`. This will be useful when binding routes to listeners.

{% tip %}
These are {{site.mesh_product_name}} policies so if you are running on multi-zone they need to be created on the Global CP.
See the [dedicated section](#multi-zone) for using builtin gateways on
multi-zone.
{% endtip %}

Now, you can define a `MeshGatewayRoute` to forward your traffic based on the
matched URL path.

{% tabs %}
{% tab Kubernetes %}

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
        port: http-8080
  conf:
    http:
      rules:
        - matches:
            - path:
                match: PREFIX
                value: /
          backends:
            - destination:
                kuma.io/service: demo-app_kuma-demo_svc_5000
" | kubectl apply -f -
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshGatewayRoute
mesh: default
name: edge-gateway-route
selectors:
  - match:
      kuma.io/service: edge-gateway
      port: http-8080
conf:
  http:
    rules:
      - matches:
          - path:
              match: PREFIX
              value: /
        backends:
          - destination:
              kuma.io/service: demo-app_kuma-demo_svc_5000
```

{% endtab %}
{% endtabs %}

### TCP

The builtin gateway also supports TCP `MeshGatewayRoutes`:

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
      protocol: TCP
      tags:
        port: tcp/8080
---
type: MeshGatewayRoute
mesh: default
name: edge-gateway-route
selectors:
  - match:
      kuma.io/service: edge-gateway
      port: tcp/8080
conf:
  tcp:
    rules:
      - backends:
          - destination:
              kuma.io/service: redis_kuma-demo_svc_6379
```

The TCP configuration _only_ supports the `backends` key (no `matches` or `filters`). There are no TCP-generic ways to filter or match traffic so it can only load balance.

### Multi-zone

The {{site.mesh_product_name}} Gateway resource types, `MeshGateway` and `MeshGatewayRoute`, are synced across zones by the {{site.mesh_product_name}} control plane.
If you have a multi-zone deployment, follow existing {{site.mesh_product_name}} practice and create any {{site.mesh_product_name}} Gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it is needed by deploying builtin gateway `Dataplanes` (in Universal zones) or `MeshGatewayInstances` (Kubernetes zones).

See the [multi-zone docs](/docs/{{ page.release }}/production/deployment/multi-zone/) for a
refresher.

### Cross-mesh

The `Mesh` abstraction allows users
to encapsulate and isolate services
inside a kind of submesh with its own CA.
With a cross-mesh `MeshGateway`,
you can expose the services of one `Mesh`
to other `Mesh`es by defining an API with `MeshGatewayRoute`s.
All traffic remains inside the {{site.mesh_product_name}} data plane protected by mTLS.

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

{% if_version lte:1.8.x %}
Cross-mesh functionality isn't supported across zones at the
moment but will be in a future release.

{% endif_version %}
The only `protocol` supported is `HTTP`.
Like service to service traffic,
all traffic to the gateway is protected with mTLS
but appears to be HTTP traffic
to the applications inside the mesh.
In the future, this limitation may be relaxed.

There can be only one entry in `selectors`
for a `MeshGateway` with `crossMesh: true`.

### Policy support

Not all {{site.mesh_product_name}} policies are applicable to {{site.mesh_product_name}} Gateway (see table below).
{{site.mesh_product_name}} connection policies are selected by matching the source and destination expressions against sets of {{site.mesh_product_name}} tags.
In the case of {{site.mesh_product_name}} Gateway the source selector is always matched against the Gateway listener tags, and the destination expression is matched against the backend destination tags configured on a Gateway Route.

When a Gateway Route forwards traffic, it may weight the traffic across multiple services.
In this case, matching the destination for a connection policy becomes ambiguous.
Although the traffic is proxied to more than one distinct service, {{site.mesh_product_name}} can only configure the route with one connection policy.
In this case, {{site.mesh_product_name}} employs some simple heuristics to choose the policy.
If all the backend destinations refer to the same service, {{site.mesh_product_name}} will choose the oldest connection policy that has a matching destination service.
However, if the backend destinations refer to different services, {{site.mesh_product_name}} will prefer a connection policy with a wildcard destination (i.e. where the destination service is `*`).

{{site.mesh_product_name}} may select different connection policies of the same type depending on the context.
For example, when {{site.mesh_product_name}} configures an Envoy route, there may be multiple candidate policies (due to the traffic splitting across destination services), but when {{site.mesh_product_name}} configures an Envoy cluster there is usually only a single candidate (because clusters are defined to be a single service).
This can result in situations where different policies (of the same type) are used for different parts of the Envoy configuration.

| Policy                                                    | GatewaySupport |
| --------------------------------------------------------- | -------------- |
| [Circuit Breaker](/docs/{{ page.release }}/policies/circuit-breaker)         | Full           |
| [External Services](/docs/{{ page.release }}/policies/external-services)     | Full           |
| [Fault Injection](/docs/{{ page.release }}/policies/fault-injection)         | Full           |
| [Health Check](/docs/{{ page.release }}/policies/health-check)               | Full           |
| [Proxy Template](/docs/{{ page.release }}/policies/proxy-template)           | Full           |
| [Rate Limits](/docs/{{ page.release }}/policies/rate-limit)                  | Full           |
| [Retries](/docs/{{ page.release }}/policies/retry)                           | Full           |
| [Traffic Permissions](/docs/{{ page.release }}/policies/traffic-permissions) | Full           |
| [Traffic Routes](/docs/{{ page.release }}/policies/traffic-route)            | None           |
| [Traffic Log](/docs/{{ page.release }}/policies/traffic-log)                 | Partial        |
| [Timeouts](/docs/{{ page.release }}/policies/timeout)                        | Full           |
| [VirtualOutbounds](/docs/{{ page.release }}/policies/virtual-outbound)       | None           |

You can find in each policy's dedicated information with regard to builtin gateway support.
