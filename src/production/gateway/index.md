---
title: Overview
---

When services need to receive traffic from the outside, commonly called North/South, the Kuma Gateway enables routing network traffic from outside a Kuma mesh to services inside the mesh. The gateway is also responsible for security at the entrance of the Mesh.

Kuma Gateway deploys as a Kuma [`Dataplane`](/docs/{{ page.version }}/production/dp), that's an instance of the `kuma-dp` process.
Like all Kuma `Dataplanes`, the Kuma Gateway `Dataplane` manages an Envoy proxy process that does the actual network traffic proxying.

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

The blue lines represent traffic not managed by Kuma, which needs configuring in the Gateway.

## Builtin

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

- [MeshGateway](/docs/{{ page.version }}/production/gateway/built-in) is used to configure listeners exposed by the gateway
- [MeshGatewayRoute](/docs/{{ page.version }}/production/gateway/builtin-routes) is used to configure route to route traffic from listeners to other services.

{% tip %}
Kuma gateways are configured with the [Envoy best practices for edge proxies](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge).
{% endtip %}

### Usage

Steps required to setup a simple gateway that exposes a http listener and 2 routes to imaginary services: "frontend" and "api".

{% tabs setup useUrlFragment=false %}
{% tab setup Kubernetes %}
To ease starting gateways on Kubernetes, Kuma comes with a builtin type `MeshGatewayInstance`.
This type requests that the control plane create and manage a Kubernetes `Deployment` and `Service`
suitable for providing service capacity for the `MeshGateway` with the matching `kuma.io/service` tag.

```shell
echo "
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
" | kubectl apply -f -
```

For a given `MeshGatewayInstance`, the control plane waits for a `MeshGateway` matching the `kuma.io/service` tag to exist.
Once one does, the control plane creates a new `Deployment` in the `default` namespace.
This `Deployment` has the requested number of builtin gateway `Dataplane` pod replicas running as the service named in the `MeshGatewayInstance` tags.
The control plane also creates a new `Service` to send network traffic to the builtin `Dataplane` pods.
The `Service` is of the type requested in the `MeshGatewayInstance`, and its ports are automatically adjusted to match the listeners on the corresponding `MeshGateway`.

#### Customization

Additional customization of the generated `Service` or `Deployment` is possible via `MeshGatewayInstance.spec`. For example, you can add annotations to the generated `Service`:

```yaml
spec:
  replicas: 1
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
  resources:
    limits: ...
    requests: ...
  serviceTemplate:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
        ...
    spec:
      loadBalancerIP: ...
" | kubectl apply -f -
```

{% endtab %}
{% tab setup Universal %}

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

Now that the `Dataplane` is running you can describe the gateway listener:

{% tabs listener useUrlFragment=false %}
{% tab listener Kubernetes %}

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

{% endtab %}
{% tab listener Universal %}

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

{% endtab %}
{% endtabs %}

This policy creates a listener on port 8080 and will receive any traffic which has the `Host` header set to `foo.example.com`.
Notice that listeners have tags like `Dataplanes`. This will be useful when binding routes to listeners.

{% tip %}
These are Kuma policies so if you are running on multi-zone they need to be created on the Global CP.
See the [dedicated section](/docs/{{ page.version }}/production/deployment-topologies/multi-zone) for detailed information.
{% endtip %}

Now define your routes which take the traffic and route it either to your `api` or your `frontend` depending on the path of the http request:

{% tabs routes useUrlFragment=false %}
{% tab routes Kubernetes %}

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
                value: /
          backends:
            - destination:
                kuma.io/service: demo-app_kuma-demo_svc_5000
" | kubectl apply -f -
```

{% endtab %}
{% tab routes Universal %}

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
              value: /
        backends:
          - destination:
              kuma.io/service: demo-app_kuma-demo_svc_5000
```

{% endtab %}
{% endtabs %}

Because routes are applied in order of specificity the first route will take precedence over the second one.
So `/api/foo` will go to the `api` service whereas `/asset` will go to the `frontend` service.

### Multi-zone

The Kuma Gateway resource types, `MeshGateway` and `MeshGatewayRoute`, are synced across zones by the Kuma control plane.
If you have a multi-zone deployment, follow existing Kuma practice and create any Kuma Gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it is needed by deploying builtin gateway `Dataplanes` (in Universal zones) or `MeshGatewayInstances` (Kubernetes zones).

### Cross-mesh

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
| [Circuit Breaker](/docs/{{ page.version }}/features/performance/circuit-breaker)         | Full           |
| [External Services](/docs/{{ page.version }}/production/networking/external-services)     | Full           |
| [Fault Injection](/docs/{{ page.version }}/features/performance/fault-injection)         | Full           |
| [Health Check](/docs/{{ page.version }}/features/health-check/health-check-policy)               | Full           |
| [Proxy Template](/docs/{{ page.version }}/reference/proxy-template)           | Full           |
| [Rate Limits](/docs/{{ page.version }}/features/performance/rate-limit)                  | Full           |
| [Retries](/docs/{{ page.version }}/features/health-check/retry)                           | Full           |
| [Traffic Permissions](/docs/{{ page.version }}/features/traffic/permissions) | Full           |
| [Traffic Routes](/docs/{{ page.version }}/features/traffic/route)            | None           |
| [Traffic Log](/docs/{{ page.version }}/features/traffic/log)                 | Partial        |
| [Timeouts](/docs/{{ page.version }}/features/performance/timeout)                        | Full           |
| [VirtualOutbounds](/docs/{{ page.version }}/production/networking/outbound-communication)       | None           |

You can find in each policy's dedicated information with regard to builtin gateway support.
