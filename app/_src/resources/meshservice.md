---
title: MeshService
description: Reference for MeshService resource that defines service destinations for traffic routing, policy targeting, and cross-zone communication.
keywords:
  - MeshService
  - service discovery
  - resource
content_type: reference
category: resource
---

`MeshService` represents a destination for traffic within the mesh. It defines which data plane proxies serve traffic for a service, exposes ports, and tracks health status. Think of it as the {{site.mesh_product_name}} equivalent of a Kubernetes `Service`.

{{site.mesh_product_name}} automatically generates `MeshService` resources:

- **Kubernetes**: From `Service` resources, reusing ClusterIPs and DNS names
- **Universal**: From `Dataplane` inbounds with `kuma.io/service` tags

{% tip %}
For concepts, migration guidance, and usage patterns, see the [MeshService guide](/docs/{{ page.release }}/networking/meshservice/).
{% endtip %}

## Spec fields

| Field | Description |
|-------|-------------|
| `selector` | Defines which data plane proxies belong to this service. Use either `dataplaneTags` or `dataplaneRef`. |
| `selector.dataplaneTags` | Match proxies by tags on their inbounds. All specified tags must match. |
| `selector.dataplaneRef.name` | Match a specific proxy by name. Used for headless services. |
| `ports` | List of ports exposed by this service. |
| `ports[].port` | Service port number (required). |
| `ports[].targetPort` | Port on the data plane proxy. Can be a number or inbound name. Defaults to `port` value. |
| `ports[].name` | Optional port name for referencing in policies via `sectionName`. |
| `ports[].appProtocol` | Protocol hint: `tcp` (default), `http`, `http2`, `grpc`. |
| `identities` | Service identities (auto-populated). Contains `ServiceTag` or `SpiffeID` entries. |
| `state` | Service availability: `Available` (healthy endpoints exist) or `Unavailable`. |

## Examples

### Basic MeshService

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: redis
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplaneTags:
      app: redis
      k8s.kuma.io/namespace: kuma-demo
  ports:
    - port: 6379
      targetPort: 6379
      appProtocol: tcp
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshService
name: redis
mesh: default
spec:
  selector:
    dataplaneTags:
      kuma.io/service: redis
  ports:
    - port: 6379
      targetPort: 6379
      appProtocol: tcp
```

{% endtab %}
{% endtabs %}

### MeshService with multiple ports

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: backend
  namespace: app
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplaneTags:
      app: backend
      k8s.kuma.io/namespace: app
  ports:
    - name: http
      port: 80
      targetPort: 8080
      appProtocol: http
    - name: grpc
      port: 9000
      targetPort: 9000
      appProtocol: grpc
    - name: metrics
      port: 9090
      targetPort: 9090
      appProtocol: http
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshService
name: backend
mesh: default
spec:
  selector:
    dataplaneTags:
      kuma.io/service: backend
  ports:
    - name: http
      port: 80
      targetPort: 8080
      appProtocol: http
    - name: grpc
      port: 9000
      targetPort: 9000
      appProtocol: grpc
    - name: metrics
      port: 9090
      targetPort: 9090
      appProtocol: http
```

{% endtab %}
{% endtabs %}

### MeshService with named `targetPort`

Reference inbound ports by name instead of number:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: api
  namespace: app
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplaneTags:
      app: api
      k8s.kuma.io/namespace: app
  ports:
    - name: main
      port: 80
      targetPort: http-port  # references inbound name
      appProtocol: http
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshService
name: api
mesh: default
spec:
  selector:
    dataplaneTags:
      kuma.io/service: api
  ports:
    - name: main
      port: 80
      targetPort: http-port  # references inbound name
      appProtocol: http
```

{% endtab %}
{% endtabs %}

### MeshService for headless service (single pod)

Use `dataplaneRef` to target a specific proxy instance:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: postgres-0
  namespace: database
  labels:
    kuma.io/mesh: default
    k8s.kuma.io/is-headless-service: "true"
spec:
  selector:
    dataplaneRef:
      name: postgres-0  # specific pod name
  ports:
    - port: 5432
      targetPort: 5432
      appProtocol: tcp
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshService
name: postgres-0
mesh: default
spec:
  selector:
    dataplaneRef:
      name: postgres-0  # specific dataplane name
  ports:
    - port: 5432
      targetPort: 5432
      appProtocol: tcp
```

{% endtab %}
{% endtabs %}

### MeshService with custom labels

Add labels for policy targeting and organization:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshService
metadata:
  name: payment-service
  namespace: payments
  labels:
    kuma.io/mesh: default
    team: payments
    tier: backend
    pci-compliant: "true"
spec:
  selector:
    dataplaneTags:
      app: payment-service
      k8s.kuma.io/namespace: payments
  ports:
    - port: 443
      targetPort: 8443
      appProtocol: http2
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshService
name: payment-service
mesh: default
labels:
  team: payments
  tier: backend
  pci-compliant: "true"
spec:
  selector:
    dataplaneTags:
      kuma.io/service: payment-service
  ports:
    - port: 443
      targetPort: 8443
      appProtocol: http2
```

{% endtab %}
{% endtabs %}

{% if_version gte:2.14.x %}

## Label propagation

In Universal zones, non-reserved `Dataplane` inbound tags and `Dataplane` resource labels are propagated into the generated `MeshService`'s `metadata.labels`. This lets you select generated `MeshServices` (for example with [`MeshMultiZoneService`](/docs/{{ page.release }}/networking/meshmultizoneservice/)) by custom labels such as `team` or `version` without patching each `MeshService` manually. It does not apply to Kubernetes zones, where `MeshServices` are generated from `Services`.

For example, a `Dataplane` carrying a custom `team` label:

```yaml
type: Dataplane
mesh: default
name: backend-1
labels:
  team: payments
networking:
  address: 10.0.0.1
  inbound:
  - port: 80
    tags:
      kuma.io/service: backend
```

produces a generated `MeshService` that carries the same label:

```yaml
type: MeshService
name: backend
mesh: default
labels:
  team: payments
spec:
  selector:
    dataplaneTags:
      kuma.io/service: backend
```

This is opt-in. Enable it via the control plane configuration:

```yaml
experimental:
  meshServiceLabelPropagation:
    enabled: true
    allowedLabelKeys: []  # empty = propagate all non-reserved keys
```

Rules:

- `kuma.io/*` and `k8s.kuma.io/*` keys are never propagated. The generator writes system labels (`kuma.io/mesh`, `kuma.io/zone`, `kuma.io/origin`, `kuma.io/managed-by`, `kuma.io/display-name`, `kuma.io/env`) itself, and `Dataplane` tags or labels cannot override them.
- `allowedLabelKeys` restricts propagation to an explicit set of keys. When empty, all non-reserved keys are propagated.
- Keys and values must be valid [Kubernetes label keys and values](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set) (63-character limit, restricted character set). Invalid entries are skipped and logged. They do not fail `Dataplane` validation.
- Label removal propagates: removing a tag or label from the backing `Dataplanes` removes it from the generated `MeshService`. Removal only takes effect once the last `Dataplane` carrying the value is gone.

### Conflict resolution

When the `Dataplanes` backing one `MeshService` disagree on the value of a non-reserved key:

- **Within a single `Dataplane`** (its inbounds disagree on a tag): the generator drops the key, logs a warning, and increments `component_meshservice_generator_dropped_labels_total`. Disagreement between inbounds on the same `Dataplane` is a configuration error.
- **Across different `Dataplanes`**: per-key majority wins.
- **Ties**: the newest `Dataplane` wins by creation time. On identical timestamps, the lexicographically smallest value wins.

{% warning %}
With only two backing `Dataplanes`, every key conflict is a tie, so the propagated value tracks whichever `Dataplane` was created most recently and can flip when a `Dataplane` is replaced. During a rolling deploy the value switches at the ~50% crossover point. If you use these labels as `MeshMultiZoneService` selectors, update the selectors in lockstep, or give workloads that must be routed separately distinct `kuma.io/service` values so they generate separate `MeshServices`.
{% endwarning %}
{% endif_version %}

## Targeting MeshService in policies

### In policy targetRef

Target a specific port using `sectionName`:

```yaml
spec:
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: app      # Kubernetes only
        sectionName: http   # port name
```

### In route `backendRefs`

Direct traffic to a MeshService:

```yaml
spec:
  to:
    - targetRef:
        kind: MeshService
        name: frontend
        namespace: app
      rules:
        - default:
            backendRefs:
              - kind: MeshService
                name: backend
                namespace: app
                port: 80
```

### Using labels for cross-zone targeting

Select MeshServices across zones:

```yaml
spec:
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: backend
          kuma.io/zone: east
```

## Naming constraints

MeshService names must:

- Be 63 characters or fewer
- Conform to DNS-1035 (lowercase alphanumeric, hyphens allowed, cannot start/end with hyphen)

## See also

- [MeshService guide](/docs/{{ page.release }}/networking/meshservice/) - concepts and migration
- [MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice/) - aggregate services across zones
- [HostnameGenerator](/docs/{{ page.release }}/networking/hostnamegenerator/) - DNS hostname generation
- [Service discovery](/docs/{{ page.release }}/networking/service-discovery/) - how proxies discover services
- [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/) - HTTP traffic routing
- [MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/) - TCP traffic routing

## All options

{% schema_viewer kuma.io_meshservices type=crd %}
