---
title: Configuring inbound traffic with rules API
---

Using `Rules API` combined with targetRef `Dataplane` kind in {{site.mesh_product_name}} you can easily apply configuration to workload
inbounds. This guide will show you how to configure MeshTimeout policy on data plane inbound and explain how to utilize this API.

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

## Basic setup

To make sure that traffic works in our examples let's configure MeshTrafficPermission to allow all traffic:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo
  name: mtp
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

To finish the setup we need to create additional namespace with sidecar injection for client we will be using to communicate
with our demo-app:

```shell
echo "apiVersion: v1
kind: Namespace
metadata:
  name: consumer
  labels:
    kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```

Now we can create deployment we will be using to communicate with our demo-app from a `consumer` namespace:

```shell
kubectl run consumer --image nicolaka/netshoot --labels="app=consumer" -n consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

You can make now make a couple of requests to our demo app to check if everything is working:

```shell
kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5000/increment
```

You should see something similar to:

```json
{"counter":"1","zone":"local","err":null}
```

## Inbound policy rules api 

Now that we have our setup we can start playing with new Rules API for inbound policies and Dataplane kind. 
Let's create a simple inbound [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/) policy in `kuma-demo` namespace:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: mtimeout
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  targetRef:
    kind: Dataplane
    labels: 
      app: demo-app
  rules:
    - default:
        http:
          requestTimeout: 1s" | kubectl apply -f -
```

We can check now if policy was properly applied by making requests to our demo app:

```shell
kubectl exec -n consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5000/increment -H "x-set-response-delay-ms: 2000"
```

Example output:

```
upstream request timeout
```

Now we can take a closer look at policy that we've just applied and see how it works.

### Selecting Dataplane resources

This policy selects only `Dataplane` that contains label `app=demo-app`. When selecting data planes you can do it in multiple ways.

You can select all data planes:

```yaml
targetRef:
  kind: Dataplane
```

You can select data plane by name and namespace:

```yaml
targetRef:
  kind: Dataplane
  name: demo-app
  namespace: kuma-demo
```

You can select data plane by labels:

```yaml
targetRef:
  kind: Dataplane
  labels:
    app: demo-app
```

When your application exposes multiple named inbounds. You can select single inbound from your data plane by utilizing `sectionName` field.

```yaml
targetRef:
  kind: Dataplane
  name: demo-app
  sectionName: http-port
```

### Configuring incoming traffic with Rules API

As we can see in policy that we've just applied, we use `rules` field to specify configuration for all incoming traffic to our data plane.

```yaml
rules:
  - default:
      http:
        requestTimeout: 1s
```

In this scenario we have applied a **request timeout of 1 second** for incoming requests. At this point in time rules api is really simple.
You cannot apply configuration to subset of incoming traffic. Because of this we don't support
rules api for MeshTrafficPermission and MeshFaultInjection yet.