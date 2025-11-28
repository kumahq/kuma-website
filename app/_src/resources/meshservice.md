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

## Status fields

The status is managed by {{site.mesh_product_name}} and provides runtime information:

| Field | Description |
|-------|-------------|
| `addresses` | Generated hostnames from [HostnameGenerators](/docs/{{ page.release }}/networking/hostnamegenerator/). |
| `vips` | Virtual IP addresses assigned to the service (Kubernetes ClusterIP or Kuma VIP). |
| `tls.status` | mTLS readiness: `Ready` or `NotReady`. |
| `dataplaneProxies.total` | Total proxies matching this service. |
| `dataplaneProxies.connected` | Proxies connected to control plane. |
| `dataplaneProxies.healthy` | Proxies with all inbound ports healthy. |
| `hostnameGenerators` | Status of hostname generation from each generator. |

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

{% schema_viewer MeshService type=proto %}
