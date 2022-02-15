# MeshGatewayRoute

`MeshGatewayRoute` is a policy used to configure [Kuma's builtin gateway](../documentation/gateway.md#builtin).
It is used in combination with [`MeshGateway`](./mesh-gateway.md).

`MeshGatewayRoute` is a new Kuma dataplane policy that replaces TrafficRoute for Kuma Gateway.
It configures how a Gateway should process network traffic.
At the moment, it targets HTTP routing use cases.
Gateway Routes are attached to Gateways by matching their selector to the [`MeshGateway`](./mesh-gateway.md) listener tags.

`MeshGatewayRoute` is unique in the Kuma policy ecosystem because rather than selecting the single best-matching `MeshGatewayRoute` to bind to a `MeshGateway` listener, Kuma will bind all the matching `MeshGatewayRoute` resources.

To define `MeshGatewayRoute` that attaches a route to a listener with a tag: `vhost=foo.example.com` and routes traffic to the backend service do:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Universal"
```yaml
type: MeshGatewayRoute
mesh: default
name: foo.example.com-backend 
selectors:
- match:
    vhost: foo.example.com
conf:
  http:
    rules:
      - matches:
          - path:
              match: PREFIX
              value: /
        backends:
          - destination:
              kuma.io/service: backend
```
:::
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayRoute
mesh: default
metadata:
  name: foo.example.com-backend
spec:
  selectors:
    - match:
        vhost: foo.example.com
  conf:
    http:
      rules:
        - matches:
            - path:
                match: PREFIX
                value: /
          backends:
            - destination:
                kuma.io/service: backend
```
:::
::::

When Kuma binds a `MeshGatewayRoute` to a `MeshGateway`, careful specification of tags lets you control whether the `MeshGatewayRoute` will bind to one or more of the listeners declared on the `MeshGateway`.
Each listener stanza on a `MeshGateway` has a set of tags; Kuma creates the listener tags by combining these tags with the tags from the underlying builtin gateway Dataplane.
A Gateway selector that matches only on the Gateway’s `kuma.io/service` tag will bind to all listeners on the `MeshGateway`, but a selector that includes listener tags will only bind to matching listeners.
One application of this mechanism is to inject standard routes into all virtual hosts, without the need to modify `MeshGatewayRoutes` that configure specific applications.

`MeshGatewayRoute` allows HTTP requests to be matched by various criteria (e.g. URI path, HTTP headers).
When Kuma generates the final Envoy configuration for a builtin gateway Dataplane, it combines all the matching `MeshGatewayRoutes` into a single set of routing tables, partitioned by the virtual hostname, which is specified either in the `MeshGateway` listener or in the `MeshGatewayRoute`.
Kuma sorts the rules in each table by specificity, so that routes with more specific match criteria are always ordered first.
For example, a rule that matches on a HTTP header and a path is more specific than one that matches only on path, and the longest match path will be considered more specific.
This ordering allows Kume to combine routing rules from multiple `MeshGatewayRoute` resources and still produce predictable results.

The reference doc contains all options on [`MeshGatewayRoute`](../generated/mesh-gateway-route.md).
