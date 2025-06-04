---
title: Producer and Consumer policies
---

{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

With namespace scoped policies in {{site.mesh_product_name}} you can have fine-grained control over policies and how they apply to 
your workloads. Moreover, this empowers app owners to take advantage of Kubernetes RBAC for policy configuration.

To fully utilize power of namespace scoped policies we need to get familiar with producer consumer model.
This guide will help you get comfortable with producer consumer model.

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application


{% tip %}
If you are already familiar with quickstart you can set up required environment by running:

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ site.mesh_namespace }} \{% if version == "preview" %}
  --version {{ page.version }} \{% endif %}
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
kubectl wait -n {{ kuma-system }} --for=condition=ready pod --selector=app={{ kuma-control-plane }} --timeout=90s
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% endtip %}

## Basic setup

In order to be able to fully utilize namespace scoped policies you need to use [MeshService](/docs/{{ page.release }}/networking/meshservice). 
To make sure that traffic works in our examples let's configure MeshTrafficPermission to allow all traffic:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo
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
kubectl run consumer --image nicolaka/netshoot -n first-consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

and from the second-consumer namespace:

```shell
kubectl run consumer --image nicolaka/netshoot -n second-consumer --command -- /bin/bash -c "ping -i 60 localhost"
```

You can make now make a couple of requests to our demo app to check if everything is working: 

```shell
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5050/api/counter
```

You should see something similar to:

```json
{"counter":"1","zone":"local"}
```

At this moment our setup looks like this:

{% mermaid %}
flowchart LR

subgraph first-consumer-ns
  first-consumer
end

subgraph second-consumer-ns
  second-consumer
end

subgraph kuma-demo-ns
  kuma-demo
  kv
end

kuma-demo --> kv
first-consumer --> kuma-demo
second-consumer --> kuma-demo
{% endmermaid %}

<!-- vale Vale.Terms = NO -->
## Namespace scoped policies
<!-- vale Vale.Terms = YES -->

Now that we have our setup we can start playing with policies. Let's create a simple [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/) policy in `kuma-demo` namespace:

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
This label indicates the policy role. Possible values of this label are:

- `system` - policies applied in system namespace
- `workload-owner` - policies that don't specify `spec.from` and `spec.to` sections or specify only `spec.from` section
- `consumer` - policies targeting `MeshServices` from different namespace in `spec.to` section or targeting `MeshService` by labels
- `producer` - policies defined in the same namespace as the MeshService they are targeting in their `spec.to[]`. 

### Producer consumer model

With namespace scoped policies we've introduced a producer/consumer model for policies. 

A **producer** is someone who authors and operates a service. A producer can create policies that will be applied by default to any communication with their services.
Producer policies will be created in the same namespace as `MeshService` they target. Producer policies will be synced to other zones. 

A **consumer** is the client of a service. Consumer policies will be applied in the consumer
namespace and may target MeshService from different namespaces. Consumer policies take effect only in the consumer namespace.
Consumer policies will override producer policies.

## Testing producer policy

To test MeshTimeout that we've applied in previous steps we need to simulate delays on our requests. To do this we need
add header `x-set-response-delay-ms` to our requests.

We can now make few requests to our demo-app, and we should see timeouts:

```shell
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

Example output:

```
upstream request timeout
```

We should see the same results when making requests from second-consumer namespace:

```shell
kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

Output:

```
upstream request timeout
```

Producer policy will be applied on all traffic to `kuma-demo` as we can see on this diagram: 

{% mermaid %}
flowchart LR

subgraph first-consumer-ns
first-consumer
end

subgraph second-consumer-ns
second-consumer
end

subgraph kuma-demo-ns
kuma-demo
kv
end

kuma-demo --> kv
first-consumer --producer-timeout--> kuma-demo
second-consumer --producer-timeout--> kuma-demo
{% endmermaid %}


## Utilizing consumer policy

Until now, we were relying on producer policy created previously. Let's assume that we don't mind waiting a little longer
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
        labels:
          k8s.kuma.io/service-name: demo-app
      default:
        http:
          requestTimeout: 3s" | kubectl apply -f -
```

When we now make requests from the first-consumer namespace all the requests should succeed, but they will take longer:

```shell
kubectl exec -n first-consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

We have just applied a consumer policy. The timeout will only be applied in the `first-consumer` namespace.
We can test this by making requests from our second-consumer namespace:

```shell
kubectl exec -n second-consumer consumer -- curl -s -XPOST demo-app.kuma-demo:5050/api/counter -H "x-set-response-delay-ms: 2000"
```

We should still see timeouts:

```
upstream request timeout
```

To better visualize this we can look again at our diagram and see that only traffic from `first-consumer` will be affected.

{% mermaid %}
flowchart LR

subgraph first-consumer-ns
first-consumer
end

subgraph second-consumer-ns
second-consumer
end

subgraph kuma-demo-ns
kuma-demo
kv
end

kuma-demo --> kv
first-consumer --consumer-timeout--> kuma-demo
second-consumer --producer-timeout--> kuma-demo
{% endmermaid %}

## What we've learnt?

- How to apply policy on a namespace
- What are policy roles and what types can you encounter 
- What are producer and consumer policies
- How producer and consumer policies interact with each other

## Next steps

- Read more about [producer/consumer policies](/docs/{{ page.release }}/policies/introduction/)
- Check out [Federate zone control plane](/docs/{{ page.release }}/guides/federate-kv/) guide
