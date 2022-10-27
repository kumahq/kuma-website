---
title: Configure a built-in gateway
---


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

- [MeshGateway](/docs/{{ page.version }}/policies/mesh-gateway) is used to configure listeners exposed by the gateway
- [MeshGatewayRoute](/docs/{{ page.version }}/policies/mesh-gateway-route) is used to configure route to route traffic from listeners to other services.

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
See the [dedicated section](/docs/{{ page.version }}/deployments/multi-zone) for detailed information.
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