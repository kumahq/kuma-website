---
title: Dataplane
description: Resource reference for Dataplane, which defines configuration for data plane proxies (sidecars) that run alongside workloads to handle service mesh traffic.
keywords:
  - data plane proxy
  - sidecar
  - Envoy
content_type: reference
category: resource
---

The `Dataplane` resource defines the configuration of a [data plane proxy](/docs/{{ page.release }}/introduction/concepts#data-plane-proxy) (also called a sidecar). A data plane proxy runs next to each workload and handles all inbound and outbound traffic for that workload.

On Kubernetes, {{site.mesh_product_name}} automatically generates `Dataplane` resources when pods are injected with the sidecar. On Universal, you must manually create `Dataplane` resources to register workloads with the mesh.

Each `Dataplane` belongs to exactly one [mesh](/docs/{{ page.release }}/resources/mesh/).

## Spec fields

| Field | Description |
|-------|-------------|
| `networking.address` | IP/hostname where proxy is accessible to control plane and other proxies. |
| `networking.advertisedAddress` | routable address for proxies in private networks. Envoy binds to `address`, not this. |
| `networking.inbound` | List of inbound interfaces. Each has `port`, `tags` (must include `kuma.io/service`), optional `servicePort`, `serviceAddress`, `health`, `serviceProbe`, `state`, `name`. See [Configure the data plane](/docs/{{ page.release }}/production/dp-config/dpp/). |
| `networking.outbound` | List of consumed services with `port` and `tags` or `backendRef`. Only needed without [transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/). |
| `networking.gateway` | Gateway configuration with `tags` and `type` (`DELEGATED` or `BUILTIN`). See [Built-in gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin/). |
| `networking.transparentProxying` | Automatic traffic interception config: `redirectPortInbound`, `redirectPortOutbound`, `directAccessServices`, `reachableServices`, `ipFamilyMode`, `reachableBackends`. See [Transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/). |
| `networking.admin` | Envoy [admin interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) configuration. |
| `metrics` | Metrics collection config. Overrides [Mesh](/docs/{{ page.release }}/resources/mesh/)-level defaults. |
| `probes` | Expose endpoints without mTLS for health checks. Deprecated on Kubernetes. |

## Examples

### Basic Dataplane with single inbound (Universal)

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
        version: v1
```

{% endtab %}
{% endtabs %}

### Dataplane with multiple inbounds (Universal)

When a workload exposes multiple ports:

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: backend-01
networking:
  address: 192.168.0.2
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: backend-http
        kuma.io/protocol: http
    - port: 9090
      servicePort: 9090
      tags:
        kuma.io/service: backend-grpc
        kuma.io/protocol: grpc
```

{% endtab %}
{% endtabs %}

### Dataplane with outbounds (Universal, without transparent proxying)

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
  outbound:
    - port: 10001
      tags:
        kuma.io/service: backend
    - port: 10002
      tags:
        kuma.io/service: database
```

{% endtab %}
{% endtabs %}

### Dataplane with transparent proxying (Universal)

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableServices:
      - backend
      - database
```

{% endtab %}
{% endtabs %}

### Dataplane with service probes (Universal)

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 192.168.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
      serviceProbe:
        interval: 10s
        timeout: 2s
        unhealthyThreshold: 3
        healthyThreshold: 1
        tcp: {}
```

{% endtab %}
{% endtabs %}

### Dataplane with advertised address (Universal)

For proxies in private networks (like Docker):

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: web-01
networking:
  address: 172.17.0.2
  advertisedAddress: 10.0.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: web
        kuma.io/protocol: http
```

{% endtab %}
{% endtabs %}

### Delegated gateway Dataplane

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: kong-gateway
networking:
  address: 192.168.0.10
  gateway:
    type: DELEGATED
    tags:
      kuma.io/service: kong-gateway
```

{% endtab %}
{% endtabs %}

### Builtin gateway Dataplane

{% tabs %}
{% tab Universal %}

```yaml
type: Dataplane
mesh: default
name: edge-gateway
networking:
  address: 192.168.0.10
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

{% endtab %}
{% endtabs %}

## See also

- [Data plane proxy](/docs/{{ page.release }}/production/dp-config/dpp/) - Conceptual overview
- [Configure the data plane on Kubernetes](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/) - Kubernetes-specific configuration
- [Configure the data plane on Universal](/docs/{{ page.release }}/production/dp-config/dpp-on-universal/) - Universal deployment configuration
- [Transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/) - Traffic interception without application changes
- [Service health probes](/docs/{{ page.release }}/policies/service-health-probes/) - Health checking configuration
- [Built-in gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin/) - Gateway configuration
- [Mesh](/docs/{{ page.release }}/resources/mesh/) - Parent resource for all Dataplanes

## All options

{% schema_viewer kuma.io_dataplanes type=crd %}
