---
title: Policies
---

Policies in {{site.mesh_product_name}} let you **declare how traffic and workload should behave**,
instead of configuring each data plane proxy by hand.
They're the main way to enable features like mTLS, traffic permissions, retries, rate limits, access logging, and more.

Every policy follows the same pattern:

* **Target** – which workloads the policy applies to (`targetRef`)
* **Direction** – whether it controls outbounds (`to`) or inbounds (`rules`)
* **Behaviour** – the actual configuration (`default`) applied to the traffic

For example, policy that configures timeouts:

{% policy_yaml %}
```yaml
type: MeshTimeout
name: my-app-timeout
mesh: default
spec:
  targetRef: # Target. Policy applies only to workloads with label `app: my-app`
    kind: Dataplane
    labels:
      app: my-app
  to: # Direction. Policy applies to outbound listener for `database` MeshService
    - targetRef:
        kind: MeshService
        name: database
        namespace: database-ns
      default: # Behaviour. Policy sets connection and idle timeouts
        connectionTimeout: 10s
        idleTimeout: 30m
```
{% endpolicy_yaml %}

## Policy Roles

Depending on where a policy is created (in an application namespace, the system namespace, or on the global control plane)
and how its schema is structured, {{site.mesh_product_name}} assigns it a **policy role**.
A policy’s role determines how it is synchronized in multizone deployments and how it is prioritized when multiple policies overlap.

The table below introduces the policy roles and how to recognize them.
| Policy Role    | Controls                                                                                              | Type by Schema                                                                                                       | Multizone Sync                                                                                 |
|----------------|-------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Producer       | Outbound behaviour of callers to my service (my clients’ egress toward me).                           | Has `spec.to`. Every `to[].targetRef.namespace`, if set, must equal `metadata.namespace`.                            | Defined in the app’s namespace on a Zone CP. Synced to Global, then propagated to other zones. |
| Consumer       | Outbound behaviour of my service when calling others (my egress).                                     | Has `spec.to`. At least one `to[].targetRef.namespace` is different from `metadata.namespace`.                       | Defined in the app’s namespace on a Zone CP. Synced to Global.                                 |
| Workload Owner | Configuration of my own proxy — inbound traffic handling and sidecar features (e.g. metrics, traces). | Either has `spec.rules`, or has neither `spec.rules` nor `spec.to` (only `spec.targetRef` + proxy/sidecar settings). | Defined in the app’s namespace on a Zone CP. Synced to Global.                                 |
| System         | Mesh-wide behaviour — can govern both inbound and outbound across services (operator-managed).        | Resource is created in the system namespace (e.g. `kuma-system`).                                                    | Created in the system namespace, either on a Zone CP or on the Global CP.                      |

### Producer Policies

Producer policies **allow service owners to define recommended client-side behavior for calls to their service**,
by creating the policy in their service’s own namespace.
{{site.mesh_product_name}} then applies it automatically to the outbounds of client workloads.
This lets backend owners publish sensible defaults (timeouts, retries, limits) for consumers,
while individual clients can still refine those settings with their own [consumer](#consumer-policy) policies.

The following policy tells {{site.mesh_product_name}} to apply **3 retries** with a backoff of **15s–1m**
on **5xx errors** to any client calling backend:

```yaml
kind: MeshRetry
apiVersion: kuma.io/v1alpha1
metadata:
  namespace: backend-ns # created in the backend's namespace
  name: backend-producer-timeouts
spec:
  targetRef:
    kind: Mesh # any caller
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns # same namespaces as the policy (producer rule)
      default:
        numRetries: 3
        backOff:
          baseInterval: 15s
          maxInterval: 1m
        retryOn:
          - 5xx
```

### Consumer Policies

Consumer policies let **service owners adjust how their workloads call other services**.
They are created in the client’s namespace and applied to that client’s outbounds.
This way, the service owner can fine-tune retries, timeouts, or other settings for the calls their workloads make.

```yaml
kind: MeshRetry
apiVersion: kuma.io/v1alpha1
metadata:
  namespace: frontend-ns # created in the namespace of a client
  name: backend-consumer-timeouts
spec:
  targetRef:
    kind: Mesh # any caller but only in the 'frontend-ns' since consumer policies always scoped to the namespace of origin
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: backend-ns # different namespace from the policy (consumer rule)
      default:
        numRetries: 0 #
```


### Workload-Owner Policies

### System Policies

## How Policies Are Combined

## Referencing Services and Routes Inside Policies

## Metadata

