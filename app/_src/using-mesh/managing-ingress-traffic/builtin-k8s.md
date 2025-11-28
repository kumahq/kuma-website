---
title: Running built-in gateway pods on Kubernetes
description: Deploy and configure built-in gateway instances on Kubernetes using MeshGatewayInstance resources.
keywords:
  - MeshGatewayInstance
  - Kubernetes gateway
  - gateway deployment
---

`MeshGatewayInstance` is a Kubernetes-only resource for deploying [{{site.mesh_product_name}}'s builtin gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin).

[`MeshGateway`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners) and [`MeshHTTPRoute`](/docs/{{ page.release }}/policies/meshhttproute)/[`MeshTCPRoute`](/docs/{{ page.release }}/policies/meshtcproute) allow specifying builtin gateway
listener and route configuration but don't handle deploying `kuma-dp`
instances that listen and serve traffic.

Kuma offers `MeshGatewayInstance` to manage a Kubernetes `Deployment` and `Service`
that together provide service capacity for the `MeshGateway`{% if_version lte:2.6.x inline:true %} with the matching `kuma.io/service` tag{% endif_version %}.

[//]: # (This is change in behavior, let's assume that users will get used to it, so we won't have to show this warning after 2.9.x)
{% if_version gte:2.7.x lte:2.9.x %}

{% warning %}
**Heads up!**
In previous versions of {{site.mesh_product_name}}, setting the `kuma.io/service` tag directly within a `MeshGatewayInstance` resource was used to identify the service. However, this practice is deprecated and no longer recommended for security reasons since {{site.mesh_product_name}} version 2.7.0.

We've automatically switched to generating the service name for you based on your `MeshGatewayInstance` resource name and namespace (format: `{name}_{namespace}_svc`).
{% endwarning %}

{% endif_version %}

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
  serviceTemplate:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
  podTemplate:
    metadata:
      labels:
        app-name: my-app
```
{% endif_version %}
{% if_version gte:2.7.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  serviceTemplate:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-internal: "true"
  podTemplate:
    metadata:
      labels:
        app-name: my-app
```
{% endif_version %}

You can also modify several resource limits or security-related parameters for the generated `Pods` or specify a `loadBalancerIP` for the `Service`:

{% if_version lte:2.6.x %}
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
  resources:
    requests:
      memory: 64Mi
      cpu: 250m
    limits:
      memory: 128Mi
      cpu: 500m
  serviceTemplate:
    metadata:
      labels:
        svc-id: "19-001"
    spec:
      loadBalancerIP: 172.17.0.1
  podTemplate:
    metadata:
      annotations:
        app-monitor: "false"
    spec:
      serviceAccountName: my-sa
      securityContext:
        fsGroup: 2000
      container:
        securityContext:
          readOnlyRootFilesystem: true
```
{% endif_version %}
{% if_version gte:2.7.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  resources:
    requests:
      memory: 64Mi
      cpu: 250m
    limits:
      memory: 128Mi
      cpu: 500m
  serviceTemplate:
    metadata:
      labels:
        svc-id: "19-001"
    spec:
      loadBalancerIP: 172.17.0.1
  podTemplate:
    metadata:
      annotations:
        app-monitor: "false"
    spec:
      serviceAccountName: my-sa
      securityContext:
        fsGroup: 2000
      container:
        securityContext:
          readOnlyRootFilesystem: true
```
{% endif_version %}

## Schema

{% schema_viewer kuma.io_meshgatewayinstances type=crd %}
