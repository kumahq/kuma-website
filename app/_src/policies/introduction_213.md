---
title: Policies
description: Learn how to write and configure targetRef policies, including metadata, spec structure, merging, and MeshService targeting.
keywords:
  - targetRef policies
  - policy configuration
  - policy merging
---

Policies in {{site.mesh_product_name}} let you **declare how traffic and workload should behave**,
instead of configuring each data plane proxy by hand.
They're the main way to enable features like mTLS, traffic permissions, retries, rate limits, access logging, and more.

Every policy follows the same pattern:

* **Target**–which workloads the policy applies to (`targetRef`)
* **Direction**–whether it controls outbounds (`to`) or inbounds (`rules`)
* **Behaviour**–the actual configuration (`default`) applied to the traffic

For example, policy that configures timeouts:

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
        sectionName: "443"
        _port: 443
      default: # Behaviour. Policy sets connection and idle timeouts
        connectionTimeout: 10s
        idleTimeout: 30m
```

## Policy roles

Depending on where a policy is created (in an application namespace, the system namespace, or on the global control plane)
and how its schema is structured, {{site.mesh_product_name}} assigns it a **policy role**.
A policy’s role determines how it is synchronized in multizone deployments and how it is prioritized when multiple policies overlap.

The table below introduces the policy roles and how to recognize them.

| Policy Role    | Controls                                                                                              | Type by Schema                                                                                                       | Multizone Sync                                                                                 |
|----------------|-------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Producer       | Outbound behaviour of callers to my service (my clients' egress toward me).                           | Has `spec.to`. Every `to[].targetRef.namespace`, if set, must equal `metadata.namespace`.                            | Defined in the app's namespace on a Zone CP. Synced to Global, then propagated to other zones. |
| Consumer       | Outbound behaviour of my service when calling others (my egress).                                     | Has `spec.to`. At least one `to[].targetRef.namespace` is different from `metadata.namespace`.                       | Defined in the app's namespace on a Zone CP. Synced to Global.                                 |
| Workload Owner | Configuration of my own proxy—inbound traffic handling and sidecar features (for example metrics, traces). | Either has `spec.rules`, or has neither `spec.rules` nor `spec.to` (only `spec.targetRef` + proxy/sidecar settings). | Defined in the app's namespace on a Zone CP. Synced to Global.                                 |
| System         | Mesh-wide behaviour—can govern both inbound and outbound across services (operator-managed).        | Resource is created in the system namespace (e.g. `kuma-system`).                                                    | Created in the system namespace, either on a Zone CP or on the Global CP.                      |

In summary: **Producer** policies let you configure how clients call you. **Consumer** policies let you configure how you call others. **Workload-owner** policies let you configure your own proxy's inbound and sidecar features. **System** policies let operators set mesh-wide defaults.

### Producer policies

Producer policies **allow service owners to define recommended client-side behavior for calls to their service**,
by creating the policy in their service's own namespace.
{{site.mesh_product_name}} then applies it automatically to the outbounds of client workloads.
This lets backend owners publish sensible defaults (timeouts, retries, limits) for consumers,
while individual clients can still refine those settings with their own [consumer](#consumer-policies) policies.

The following policy tells {{site.mesh_product_name}} to apply **3 retries** with a back off of `15s` to `1m`
on **5xx errors** to any client calling `backend`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
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

### Consumer policies

Consumer policies let **service owners adjust how their workloads call other services**.
They are created in the client’s namespace and applied to that client’s outbounds.
This way, the service owner can fine-tune retries, timeouts, or other settings for the calls their workloads make.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
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
        numRetries: 0
```

### Workload-owner policies

Workload-owner policies let **service owners configure their own workload's proxies**.
They are created in the workload’s namespace and control how proxies handle inbound traffic,
while also enabling various proxy-level features such as `MeshMetric`, `MeshProxyPatch`, and others.

Workload-owner policies either have `spec.rules` for inbound traffic configuration:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: backend-ns # created in the namespace of a server
  name: backend-permissions
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  rules:
    - default:
        deny:
          - spiffeID:
              type: Exact
              value: spiffe://trust-domain.mesh/ns/default/sa/legacy
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://trust-domain.mesh/
```

Or only `spec.default` for proxy-level features like metrics and tracing:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: otel-metrics-delegated
  namespace: backend-ns
spec:
  default:
    sidecar:
      profiles:
        appendProfiles:
          - name: All
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: opentelemetry-collector.mesh-observability.svc:4317
          refreshInterval: 30s
```

### System policies

System policies provide **mesh-wide defaults managed by platform operators**.
Any policy can be a system policy as long as it's created in the system namespace ({{site.mesh_namespace}} by default) on either a Zone Control Plane or the Global Control Plane.

## Referencing Dataplanes, Services and Routes inside policies

{{site.mesh_product_name}} provides an API for cross-referencing policies and other resources called `targetRef`:

```yaml
targetRef:
  kind: Dataplane
  labels:
    app: my-app
```

`targetRef` appears in all policy definitions wherever configuration needs to be associated with resources such as `MeshService`, `MeshExternalService`, `Dataplane`, and others.

The `targetRef` API follows the same principles regardless of policy type:

1. `targetRef.kind` must always refer to a resource that exists in the cluster
2. A resource can be referenced either by `name` and `namespace` or by `labels`
3. Using `name` and `namespace` creates an unambiguous reference to a single resource, while using `labels` can match multiple resources
4. `targetRef.namespace` is optional and defaults to the namespace of the policy
5. System policies must always use `targetRef.labels`
6. When supported by the target resource, `sectionName` may reference a specific section rather than the entire resource (for example, `MeshService`, `MeshMultiZoneService`, `Dataplane`)
7. `sectionName` is resolved by first matching a section name, and if no match is found, by interpreting it as a numeric port value (provided the port name is unset)

The set of valid `targetRef.kind` values is the same across all policies and is summarized in the table below:

<!-- markdownlint-disable MD037 -->
| Field               | Available Kinds                                                                                                                  |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------|
| `spec.targetRef`      | * `Mesh`<br>* `Dataplane`                                                                                                            |
| `spec.to[].targetRef` | * `MeshService`<br>* `MeshMultiZoneService`<br>* `MeshExternalService`<br>* `MeshHTTPRoute` (if policy supports per-route configuration) |
<!-- markdownlint-enable MD037 -->

## How policies are combined

When multiple policies target the same proxy, {{site.mesh_product_name}} merges them using a priority-based strategy.

Policy priority is determined by a total ordering of attributes. The table below defines the sorting order, applied sequentially with ties broken by the next attribute in the list.

<!-- markdownlint-disable MD037 -->
|   | Attribute                                       | Order                                                                                                                                                                                                                            |
|---|-------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `spec.targetRef`                                | * `Mesh` (less priority)<br>* `MeshGateway`<br>* `Dataplane`<br>* `Dataplane` with `labels`<br>* `Dataplane` with `labels/sectionName`<br>* `Dataplane` with `name/namespace`<br>* `Dataplane` with `name/namespace/sectionName` |
| 2 | Origin<br>Label `kuma.io/origin`                | * `global` (less priority)<br>* `zone`                                                                                                                                                                                           |
| 3 | Policy Role<br>Label `kuma.io/policy-role`      | * `system` (less priority)<br>* `producer`<br>* `consumer`<br>* `workload-owner`                                                                                                                                                 |
| 4 | Display Name<br>Label `kuma.io/display-name`    | Inverted lexicographical order, i.e;<br>* `zzzzz` (less priority)<br>* `aaaaa1`<br>* `aaaaa`<br>* `aaa`                                                                                                                          |
<!-- markdownlint-enable MD037 -->

For policies with `to` or `rules`, matching policy arrays are concatenated.
For `to` policies, the concatenated arrays are sorted again based on the `spec.to[].targetRef` field:

<!-- markdownlint-disable MD037 -->
|   | Attribute             | Order                                                                                                                                   |
|---|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `spec.to[].targetRef` | * `Mesh` (less priority)<br>* `MeshService`<br>* `MeshService` with `sectionName`<br>* `MeshExternalService`<br>* `MeshMultiZoneService` |
<!-- markdownlint-enable MD037 -->

Configuration is then built by merging each level using [JSON patch merge](https://www.rfc-editor.org/rfc/rfc7386).

For example, if you have 2 `default` configurations ordered this way:

```yaml
default:
  conf: 1
  sub:
    array: [ 1, 2, 3 ]
    other: 50
    other-array: [ 3, 4, 5 ]
---
default:
  sub:
    array: [ ]
    other-array: [ 5, 6 ]
    extra: 2
```

The merge result is:

```yaml
default:
  conf: 1
  sub:
    array: [ ]
    other: 50
    other-array: [ 5, 6 ]
    extra: 2
```

## Metadata

Metadata identifies a policy by its `name`, `type`, and the `mesh` it belongs to:

{% tabs %}
{% tab Kubernetes %}

In Kubernetes all our policies are implemented as [custom resource definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) in the group `kuma.io/v1alpha1`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
spec: ... # spec data specific to the policy kind
```

By default the policy is created in the `default` [mesh](/docs/{{ page.release }}/introduction/concepts#mesh).
You can specify the [mesh](/docs/{{ page.release }}/introduction/concepts#mesh) by using the `kuma.io/mesh` label.

For example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ExamplePolicy
metadata:
  name: my-policy-name
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: "my-mesh"
spec: ... # spec data specific to the policy kind
```

{% endtab %}
{% tab Universal %}

```yaml
type: ExamplePolicy
name: my-policy-name
mesh: default
spec: ... # spec data specific to the policy kind
```

{% endtab %}
{% endtabs %}
