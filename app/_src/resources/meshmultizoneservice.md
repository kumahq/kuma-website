---
title: MeshMultiZoneService
description: Reference for MeshMultiZoneService resource that groups MeshServices across zones for cross-zone load balancing and high availability.
keywords:
  - MeshMultiZoneService
  - cross-zone
  - multizone
content_type: reference
category: resource
---

`MeshMultiZoneService` groups multiple [MeshService](/docs/{{ page.release }}/resources/meshservice/) resources across zones into a single addressable destination. While `MeshService` represents a service in a specific zone, `MeshMultiZoneService` aggregates services from multiple zones and provides zone-agnostic hostnames for cross-zone load balancing.

{{site.mesh_product_name}} automatically assigns virtual IPs and generates hostnames for each `MeshMultiZoneService`. Traffic sent to these addresses is load balanced across all matching MeshServices, with preference for the local zone when available.

{% tip %}
For usage patterns and migration guidance, see the [MeshMultiZoneService guide](/docs/{{ page.release }}/networking/meshmultizoneservice/).
{% endtip %}

## Spec fields

| Field | Description |
|-------|-------------|
| `selector` | Defines which MeshServices to group together. Required. |
| `selector.meshService` | Label selector matching MeshServices across zones. Required. |
| `selector.meshService.matchLabels` | Map of label key-value pairs. All labels must match. Common labels: `kuma.io/display-name`, `k8s.kuma.io/namespace`, `kuma.io/zone`. |
| `ports` | List of ports exposed by this multi-zone service (minimum 1 required). |
| `ports[].port` | Port number exposed by the service (required). |
| `ports[].name` | Optional port name for referencing in policies. |
| `ports[].appProtocol` | Protocol hint: `tcp` (default), `http`, `http2`, `grpc`. |

## Examples

### Basic MeshMultiZoneService

Group all MeshServices named `redis` across zones:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: redis
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: redis
  ports:
    - port: 6379
      appProtocol: tcp
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshMultiZoneService
name: redis
mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: redis
  ports:
    - port: 6379
      appProtocol: tcp
```

{% endtab %}
{% endtabs %}

### MeshMultiZoneService with namespace selector

Select services from a specific namespace across all zones:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: backend
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: backend
        k8s.kuma.io/namespace: prod
  ports:
    - port: 8080
      appProtocol: http
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshMultiZoneService
name: backend
mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: backend
        k8s.kuma.io/namespace: prod
  ports:
    - port: 8080
      appProtocol: http
```

{% endtab %}
{% endtabs %}

### MeshMultiZoneService with multiple ports

Expose multiple ports from the same service:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: webapp
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: webapp
  ports:
    - name: http
      port: 8080
      appProtocol: http
    - name: metrics
      port: 9090
      appProtocol: http
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshMultiZoneService
name: webapp
mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: webapp
  ports:
    - name: http
      port: 8080
      appProtocol: http
    - name: metrics
      port: 9090
      appProtocol: http
```

{% endtab %}
{% endtabs %}

### MeshMultiZoneService with zone selector

Select services only from specific zones:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshMultiZoneService
metadata:
  name: regional-service
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: api
        kuma.io/zone: us-east
  ports:
    - port: 443
      appProtocol: http2
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshMultiZoneService
name: regional-service
mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: api
        kuma.io/zone: us-east
  ports:
    - port: 443
      appProtocol: http2
```

{% endtab %}
{% endtabs %}

## See also

- [MeshMultiZoneService guide](/docs/{{ page.release }}/networking/meshmultizoneservice/)
- [MeshService resource](/docs/{{ page.release }}/resources/meshservice/)
- [HostnameGenerator](/docs/{{ page.release }}/networking/hostnamegenerator/)
- [MeshLoadBalancingStrategy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy/)

## All options

{% schema_viewer kuma.io_meshmultizoneservices type=crd %}
