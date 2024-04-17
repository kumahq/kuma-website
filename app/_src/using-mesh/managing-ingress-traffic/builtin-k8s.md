---
title: Running built-in gateway pods on Kubernetes
---

`MeshGatewayInstance` is a Kubernetes-only resource for deploying [{{site.mesh_product_name}}'s builtin gateway](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin).

[`MeshGateway`](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-listeners) and [`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute)/[`MeshTCPRoute`](/docs/{{ page.version }}/policies/meshtcproute) allow specifying builtin gateway
listener and route configuration but don't handle deploying `kuma-dp`
instances that listen and serve traffic.

Kuma offers `MeshGatewayInstance` to manage a Kubernetes `Deployment` and `Service`
that together provide service capacity for the `MeshGateway`{% if_version lte:2.6.x inline:true %} with the matching `kuma.io/service` tag{% endif_version %}.

{% include snippets/warning_meshgatewayinstance_service_tag.md %}

{% tip %}
If you're not using the `default` `Mesh`, you'll need to _label_ the
`MeshGatewayInstance` using `kuma.io/mesh`.
{% endtip %}

Consider the following example:

{% if_version lte:2.6.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
  labels:
    kuma.io/mesh: default # only necessary if not using default Mesh
spec:
  replicas: 2
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
```
{% endif_version %}
{% if_version gte:2.7.x %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
  labels:
    kuma.io/mesh: default # only necessary if not using default Mesh
spec:
  replicas: 2
  serviceType: LoadBalancer
```
{% endif_version %}

{% if_version lte:2.6.x %}
Once a `MeshGateway` exists with `kuma.io/service: edge-gateway`, the control plane creates a new `Deployment` in the `default` namespace.
This `Deployment` deploys 2 replicas of `kuma-dp` and corresponding builtin gateway `Dataplane` running with `kuma.io/service: edge-gateway`.
{% endif_version %}
{% if_version gte:2.7.x %}
Once a `MeshGateway` exists with `kuma.io/service: edge-gateway_default_svc`, the control plane creates a new `Deployment` in the `default` namespace.
This `Deployment` deploys 2 replicas of `kuma-dp` and corresponding builtin gateway `Dataplane` running with `kuma.io/service: edge-gateway_default_svc`.
{% endif_version %}

The control plane also creates a new `Service` to send network traffic to the builtin `Dataplane` pods.
The `Service` is of type `LoadBalancer`, and its ports are automatically adjusted to match the listeners on the corresponding `MeshGateway`.

## Customization

Additional customization of the generated `Service` or `Pods` is possible via `spec.serviceTemplate` and `spec.podTemplate`.
For example, you can add annotations and/or labels to the generated objects:

{% if_version lte:2.6.x %}
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
    spec:
      loadBalancerIP: ...
  podTemplate:
    metadata:
      labels:
        app-name: my-app
        ...
```
{% endif_version %}
{% if_version gte:2.7.x %}
```yaml
spec:
  replicas: 1
  serviceType: LoadBalancer
  resources:
    limits: ...
    requests: ...
  serviceTemplate:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
    spec:
      loadBalancerIP: ...
  podTemplate:
    metadata:
      labels:
        app-name: my-app
        ...
```
{% endif_version %}

You can also modify several security-related parameters for the generated `Pods` or specify a `loadBalancerIP` for the `Service`:

{% if_version lte:2.6.x %}
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
      labels:
        svc-id: "19-001"
    spec:
      loadBalancerIP: ...
  podTemplate:
    metadata:
      annotations:
        app-monitor: "false"
    spec:
      serviceAccountName: my-sa
      securityContext:
        fsGroup: ...
      container:
        securityContext:
          readOnlyRootFilesystem: true
```
{% endif_version %}
{% if_version gte:2.7.x %}
```yaml
spec:
  replicas: 1
  serviceType: LoadBalancer
  resources:
    limits: ...
    requests: ...
  serviceTemplate:
    metadata:
      labels:
        svc-id: "19-001"
    spec:
      loadBalancerIP: ...
  podTemplate:
    metadata:
      annotations:
        app-monitor: "false"
    spec:
      serviceAccountName: my-sa
      securityContext:
        fsGroup: ...
      container:
        securityContext:
          readOnlyRootFilesystem: true
```
{% endif_version %}

## Schema

{% json_schema kuma.io_meshgatewayinstances type=crd %}
