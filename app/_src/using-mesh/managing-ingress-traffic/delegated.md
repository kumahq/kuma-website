---
title: Delegated gateways
---

Delegated gateways allow you to integrate existing API gateway solutions into your mesh.

In delegated gateway mode, {{ site.mesh_product_name}} configures an Envoy sidecar for your API gateway.
Handling incoming traffic is left to the API gateway while Envoy and
{{ site.mesh_product_name }} take care of traffic leaving the gateway for the mesh.
The non-{{ site.mesh_product_name }} gateway is in charge of policy like security or timeouts
when it comes to incoming traffic and {{ site.mesh_product_name }} takes over
after traffic leaves the gateway destinated for the mesh.

At a technical level the delegated gateway sidecar is similar to any other sidecar
in the mesh except that incoming traffic bypasses the sidecar and directly reaches the
gateway.

<center>
<img src="/assets/images/docs/diagram-delegated-gateway-detailed@3x.jpg" alt="Delegated gateway" style="width: 387px;"/>
</center>


{% tip %}
**New to Kuma?**
Checkout our [guide](/docs/{{ page.release }}/guides/gateway-delegated/) to get quickly started with delegated gateways!
{% endtip %}


### Usage

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}

{{site.mesh_product_name}} supports most ingress controllers. However, the recommended gateway in Kubernetes is [Kong](https://docs.konghq.com/gateway). You can use [Kong Ingress Controller for Kubernetes](https://docs.konghq.com/kubernetes-ingress-controller/) to implement authentication, transformations, and other functionality across Kubernetes clusters with zero downtime.

#### Service upstream

Remember that {{ site.mesh_product_name }} takes over from `kube-proxy` when it comes to managing endpoints for `Service` traffic.
Ingress controllers generally do the same thing for upstream traffic.
In order for these two functionalities not to conflict with each other, `Services` are required to
have the [`ingress.kubernetes.io/service-upstream=true`](https://docs.konghq.com/kubernetes-ingress-controller/3.0.x/reference/annotations/#ingresskubernetesioservice-upstream) annotation.
With this annotation the ingress controller sends traffic to the `Service` IP instead of directly to the endpoints selected by the `Service`.
{{site.mesh_product_name}} then routes this `Service` traffic to endpoints as configured by the mesh.
{{site.mesh_product_name}} automatically injects this annotation for every
`Service` that is in a namespace with the label `kuma.io/sidecar-injection=enabled`.

For workloads (Deployment/StatefulSet, etc.) enabled kuma sidecar injection by labeling the workload pod template rather than labeling on the namespace, `Service` objects are not annotated automatically in these namespaces. So users need to add these annotations manually to the `Service` objects:

* `ingress.kubernetes.io/service-upstream`
* `nginx.ingress.kubernetes.io/service-upstream`

#### Delegated gateway `Dataplanes`

To use the delegated gateway feature, mark your API Gateway's `Pod` with the `kuma.io/gateway: enabled` annotation.
The control plane automatically generates `Dataplane` objects.

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

Now the gateway can send traffic to any services in the mesh including other
zones.

Note that in order to send multi-zone traffic you can either use the
[`.mesh` address](/docs/{{ page.release }}/networking{% if_version gte:2.9.x %}/transparent-proxy{% endif_version %}/dns/) or create a `Service` of type `ExternalName` that points to that url.

{% endtab %}
{% tab usage Universal %}

On Universal, you should define the `Dataplane` entity like this:

```yaml
type: Dataplane
mesh: default
name: kong-01
networking:
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong
  ...
```

Traffic that should go through the gateway should be sent directly to the
gateway process. When configuring your API Gateway to forward traffic into the
mesh, you configure the `Dataplane` object as if it were any other `Dataplane`
on Universal.

{% endtab %}
{% endtabs %}
