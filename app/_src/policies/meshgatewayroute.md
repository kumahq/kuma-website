---
title: MeshGatewayRoute
description: Configure HTTP routing for builtin gateways using MeshGatewayRoute, including path matching, filters, and traffic routing rules.
keywords:
  - gateway routing
  - HTTP routing
  - traffic management
---
{% if_version gte:2.6.x %}
{% warning %}
New to Kuma? Don't use this, check the [`MeshHTTPRoute` policy](/docs/{{ page.release }}/policies/meshhttproute) or [`MeshTCPRoute` policy](/docs/{{ page.release }}/policies/meshtcproute) instead.
{% endwarning %}
{% endif_version %}

`MeshGatewayRoute` is a policy used to configure {% if_version gte:2.6.x %}[{{site.mesh_product_name}}'s builtin gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin){% endif_version %}{% if_version lte:2.5.x %}[{{site.mesh_product_name}}'s builtin gateway](/docs/{{ page.release }}/explore/gateway#builtin){% endif_version %}.
It is used in combination with {% if_version gte:2.6.x %}[`MeshGateway`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners){% endif_version %}{% if_version lte:2.5.x %}[`MeshGateway`](/docs/{{ page.release }}/policies/meshgateway){% endif_version %}.

`MeshGatewayRoute` is a {{site.mesh_product_name}} dataplane policy that replaces TrafficRoute for {{site.mesh_product_name}} Gateway.
It configures how a gateway should process network traffic.
At the moment, it targets HTTP routing use cases.
`MeshGatewayRoutes` are attached to gateways by matching their selector to the {% if_version gte:2.6.x %}[`MeshGateway`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners){% endif_version %}{% if_version lte:2.5.x %}[`MeshGateway`](/docs/{{ page.release }}/policies/meshgateway){% endif_version %} listener tags. This requires the `kuma.io/service` tag and, optionally, additional tags to match specific `MeshGateway` listeners.

The following `MeshGatewayRoute` routes traffic to the `backend` service and attaches to any listeners tagged with `vhost=foo.example.com` that attach to builtin gateways with `kuma.io/service: edge-gateway`.

{% tabs %}
{% tab Universal %}

```yaml
type: MeshGatewayRoute
mesh: default
name: foo.example.com-backend 
selectors:
- match:
    kuma.io/service: edge-gateway
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

{% endtab %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayRoute
mesh: default
metadata:
  name: foo.example.com-backend
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway
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

{% endtab %}
{% endtabs %}

## Listener tags

When {{site.mesh_product_name}} binds a `MeshGatewayRoute` to a `MeshGateway`, careful specification of tags lets you control whether the `MeshGatewayRoute` will bind to one or more of the listeners declared on the `MeshGateway`.

Each listener stanza on a `MeshGateway` has a set of tags; {{site.mesh_product_name}} creates the listener tags by combining these tags with the tags from the underlying builtin gateway `Dataplane`.
A selector that matches only on the `kuma.io/service` tag will bind to all listeners on the `MeshGateway`, but a selector that includes listener tags will only bind to matching listeners.
One application of this mechanism is to inject standard routes into all virtual hosts, without the need to modify `MeshGatewayRoutes` that configure specific applications.

## Matching

`MeshGatewayRoute` allows HTTP requests to be matched by various criteria (for example uri path, HTTP headers).
When {{site.mesh_product_name}} generates the final Envoy configuration for a builtin gateway `Dataplane`, it combines all the matching `MeshGatewayRoutes` into a single set of routing tables, partitioned by the virtual hostname, which is specified either in the `MeshGateway` listener or in the `MeshGatewayRoute`.

{{site.mesh_product_name}} sorts the rules in each table by specificity, so that routes with more specific match criteria are always ordered first.
For example, a rule that matches on a HTTP header and a path is more specific than one that matches only on path, and the longest match path will be considered more specific.
This ordering allows {{site.mesh_product_name}} to combine routing rules from multiple `MeshGatewayRoute` resources and still produce predictable results.

## Filters

Every rule can include filters that further modifies requests. For example, by
modifying headers and mirroring, redirecting, or rewriting requests.

For example, the following filters match `/prefix`, trim it from the path and set the `Host` header:

```yaml
...
        - matches:
          - path:
              match: PREFIX
              value: /prefix/
          backends:
          - destination:
              kuma.io/service: backend
          filters:
          - requestHeader:
              set:
              - name: Host
                value: test.com
          - rewrite:
              replacePrefixMatch: "/"
```

## Reference

{% schema_viewer MeshGatewayRoute type=proto %}
