---
title: Configure a built-in gateway
---

The built-in gateway is configured using a combination of [`MeshGateway`](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-listeners), [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) and [`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute),
and served by Envoy instances represented by `Dataplanes` configured as built-in
gateways. {{ site.mesh_product_name }} policies are then used to configure
built-in gateways.

{% tip %}
**New to Kuma?**
Checkout our [guide](/docs/{{ page.version }}/guides/gateway-builtin/) to get quickly started with builtin gateways!
{% endtip %}

### Deploying gateways

The process for deploying built-in gateways is different depending on whether 
you're running in Kubernetes or Universal mode.

{% tabs setup useUrlFragment=false %}
{% tab setup Kubernetes %}

For managing gateway instances on Kubernetes, {{site.mesh_product_name}} provides a
[`MeshGatewayInstance`](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-k8s) CRD.

{% tip %}
This resource launches `kuma-dp` in your cluster.
If you are running a multi-zone {{ site.mesh_product_name }}, `MeshGatewayInstance` needs to be created in a specific zone, not the global cluster.
See the [dedicated section](#multi-zone) for using built-in gateways on
multi-zone.
{% endtip %}

This resource manages a Kubernetes `Deployment` and `Service`
suitable for providing service capacity for the `MeshGateway` with the matching `kuma.io/service` tag.

The `kuma.io/service` value you select will be used in `MeshGateway` to [configure listeners](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-listeners).

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

See [the `MeshGatewayInstance` docs](/docs/{{ page.version }}//using-mesh/managing-ingress-traffic/builtin-k8s) for more options.
{% endtab %}
{% tab setup Universal %}

You'll need to create a `Dataplane` object for your gateway:

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

Note that this gateway has an identifying `kuma.io/service` tag.

Now you need to explicitly run `kuma-dp`:

```shell
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-gateway \ # this needs to be generated like for regular Dataplane
  --dataplane-file=my-gateway.yaml # the Dataplane resource described above
```

{% endtab %}
{% endtabs %}

{% tip %}
{{site.mesh_product_name}} gateways are configured with the [Envoy best practices for edge proxies](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge).
{% endtip %}

### Multi-zone

The {{site.mesh_product_name}} Gateway resource types, `MeshGateway`, [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute) and [`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute), are synced across zones by the {{site.mesh_product_name}} control plane.
If you have a multi-zone deployment, follow existing {{site.mesh_product_name}} practice and create any {{site.mesh_product_name}} Gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it is needed by deploying built-in gateway `Dataplanes` (in Universal zones) or `MeshGatewayInstances` (Kubernetes zones).

See the {% if_version lte:2.1.x %}[multi-zone docs](/docs/{{ page.version }}/deployments/multi-zone){% endif_version %}{% if_version gte:2.2.x %}[multi-zone docs](/docs/{{ page.version }}/production/deployment/multi-zone/){% endif_version %} for a
refresher.
