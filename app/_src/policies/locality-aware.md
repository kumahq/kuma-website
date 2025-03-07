---
title: Locality-aware Load Balancing
---

{% if_version gte:2.5.x %}
{% warning %}
New to Kuma? You don't need this, Check the [`MeshLoadBalancingStrategy` policy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy) instead.
{% endwarning %}
{% endif_version %}


In a [multi-zone deployment](/docs/{{ page.release }}/production/deployment/), locality-aware load balancing
instructs data plane proxies to try to keep requests within one zone. The amount
of traffic that remains in one zone depends on the health of the service endpoints in that
zone.

By way of example, consider a request from a service in {{site.mesh_product_name}} zone `east` to another
service `backend`. If all of the endpoints for `backend` in zone `east` are healthy,
the request will be sent to one of those endpoints rather than to another zone.

As more `backend` endpoints in zone `east` become unhealthy, some traffic begins to flow
to `backend` instances in other zones.
Locality-aware load balancing is currently implemented using Envoy priorites, see
[the Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/priority)
for more details.

## Enabling locality-aware load balancing

Locality-aware load balancing is configured at the `Mesh` level.
It can be enabled as follows:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    localityAwareLoadBalancing: true
```

The configuration can be applied with `kubectl apply -f [..]`.
{% endtab %}

{% tab Universal %}

```yaml
type: Mesh
name: default
routing:
  localityAwareLoadBalancing: true
```

The configuration can be applied with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.release }}/reference/http-api).
{% endtab %}
{% endtabs %}
