---
title: Namespace scoped policies
---

## Prerequisites

- Completed [quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

## Basic setup

In order to be able to fully utilize namespace scoped policies you need to use real [MeshService](/docs/{{ page.version }}/networking/meshservice). 
To enable MeshService resource generation on Mesh level we need to run:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    enabled: Everywhere
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

We also need HostnameGenerator for easy access to our services:

```shell
echo 'apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: all
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        k8s.kuma.io/namespace: kuma-demo
  template: "{{ .DisplayName }}.{{ .Namespace }}.mesh"' | kubectl apply -f -
```

With this HostnameGenerator we will be able to call demo-app using dns name `demo-app.kuma-demo.mesh`.
To make sure that traffic works in our examples let's configure MeshTrafficPermission to allow all traffic:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

To finish the setup we need to create two additional namespaces with sidecar injection for clients we will be using to communicate 
with our demo-app:

```shell
echo "apiVersion: v1
kind: Namespace
metadata:
  name: first-consumer
  labels:
    kuma.io/sidecar-injection: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: second-consumer
  labels:
    kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```

Now we can create deployment we will be using to communicate with our demo-app from a first-consumer namespace:

```shell
kubectl run consumer --image nicolaka/netshoot -n first-consumer --command -- /bin/bash -c "while true; do ping localhost; sleep 60;done"
```

and from the second-consumer namespace:

```shell
kubectl run consumer --image nicolaka/netshoot -n second-consumer --command -- /bin/bash -c "while true; do ping localhost; sleep 60;done"
```

You can make now make a couple of requests to our demo app to check if everything is working: 

```shell
kubectl exec -n first-consumer consumer -- curl --no-progress-meter demo-app.kuma-demo.mesh:5000/counter
```

You should see something similar to:

```json
{"counter":"0","zone":"local","err":null}
```

## Namespace scoped policies

Now that we have our setup we can start playing with policies. Let's create simple MeshTimeout policy in `kuma-demo` namespace:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: producer-timeout
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  to:
    - targetRef:
        kind: MeshService
        name: demo-app
      default:
        http:
          requestTimeout: 1s" | kubectl apply -f -
```

We can now inspect applied policy labels:

```shell
kubectl get meshtimeout -n kuma-demo producer-timeout -o jsonpath='{.metadata.labels}'
```

We should see output like:

```json
{
  "k8s.kuma.io/namespace": "kuma-demo",
  "kuma.io/env": "kubernetes",
  "kuma.io/mesh": "default",
  "kuma.io/origin": "zone",
  "kuma.io/policy-role": "producer",
  "kuma.io/zone": "default"
}
```

{{site.mesh_product_name}} is adding custom labels to our policy. The one that interests us most at the moment is `kuma.io/policy-role`.
This is new label that indicates policy role. Possible values of this label are:

- `system` - policies applied in system namespace
- `workload-owner` - policies that specify `spec.from` section
- `consumer` - policies targeting MeshServices from different namespace
- `producer` - policies targeting MeshServices from the same namespace

### Producer consumer model

With namespace scoped policies we've introduced producer/consumer model for policies. 

**Producer** is someone who authors and operates service. Producer can create default policies that will be used when communicating with service. 
Producer policies will be created in the same zone as MeshService they target. Producer policies will be synced to other zones. 

**Consumer** is someone that utilizes a service by communicating with it. Consumer policies will be applied in consumer 
namespace and will target MeshService from different namespace. Consumer policy will take effect only in consumer namespace.
Consumer policies will override producer policies.

## Testing producer policy

To test MeshTimeout that we've applied in previous steps we need to simulate delays on our requests. To do this we need
MeshFaultInjection policy

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: default
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: [Sidecar]
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - delay:
              percentage: '50'
              value: 2s" | kubectl apply -f -
```

We can now make few requests to our demo-app, and we should see timeouts:

```shell
kubectl exec -n first-consumer consumer -- curl --no-progress-meter demo-app.kuma-demo.mesh:5000/counter
```

Example output:

```
{"counter":"0","zone":"local","err":null}
upstream request timeout
```

We should see the same results when making requests from second-consumer namespace:

```shell
kubectl exec -n second-consumer consumer -- curl --no-progress-meter demo-app.kuma-demo.mesh:5000/counter
```

## Utilizing consumer policy

To this moment we were relying on producer policy created previously. Let's assume that we don't mind waiting a little longer
for the response from demo-app, and we would like to override the timeout just for our namespace. To do so we need to create new policy:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: consumer-timeout
  namespace: first-consumer
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  to:
    - targetRef:
        kind: MeshService
        name: demo-app
        namespace: kuma-demo
      default:
        http:
          requestTimeout: 3s" | kubectl apply -f -
```

When we now make requests from the first-consumer namespace all the requests should succeed, but they will take longer:

```shell
kubectl exec -n first-consumer consumer -- curl --no-progress-meter demo-app.kuma-demo.mesh:5000/counter
```

Policy that we have just applied is consumer policy. This means that traffic from other namespaces to demo-app should not be affected by it.
We can test this by making requests from our second-consumer namespace:

```shell
kubectl exec -n second-consumer consumer -- curl --no-progress-meter demo-app.kuma-demo.mesh:5000/counter
```

We should still see timeouts:

```
upstream request timeout
```

## Next steps

- Read more about [producer/consumer policies](TODO)