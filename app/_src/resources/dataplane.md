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

### Networking

Configuration for the data plane proxy's network interfaces and traffic handling.

**Type:** `Networking` | **Required:** Yes

#### Address

IP address on which the data plane proxy is accessible to the control plane and other data plane proxies in the same network. This can also be a hostname, in which case the control plane periodically resolves it.

**Type:** `string` | **Required:** Yes

#### Advertised address

In private networks (like Docker), a data plane proxy might not be reachable via its `address`. Configure `advertisedAddress` with a routable address so other proxies can connect to it. Envoy still binds to `address`, not `advertisedAddress`.

**Type:** `string` | **Required:** No

#### Inbound

List of inbound interfaces that the data plane proxy exposes. Each inbound represents a service implemented by the workload. All incoming traffic flows through inbound listeners, with one Envoy listener created per inbound.

**Type:** `[]Inbound` | **Required:** No (required for regular data plane proxies, not for gateways)

##### Port

Port of the inbound interface that forwards requests to the service. With [transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/), this is the port the service listens on. Without transparent proxying, Envoy binds to this port.

**Type:** `uint32` | **Required:** Yes

##### Service port

Port to which requests are forwarded. Defaults to the same value as `port`.

**Type:** `uint32` | **Required:** No | **Default:** Same as `port`

##### Service address

Address to which requests are forwarded. Defaults to `networking.address`, since the data plane proxy should be deployed next to the service.

**Type:** `string` | **Required:** No | **Default:** Same as `networking.address`

##### Address

Address on which the inbound listener is exposed. Defaults to `networking.address`.

**Type:** `string` | **Required:** No | **Default:** Same as `networking.address`

##### Tags

Key-value pairs associated with this inbound (for example, `kuma.io/service=web`, `version=1.0`). These tags identify the service and can be referenced in policies like [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission/).

The `kuma.io/service` tag is mandatory and identifies the service name.

**Type:** `map<string, string>` | **Required:** Yes (must include `kuma.io/service`)

##### Health

Status of the inbound. If not set, the data plane proxy is considered healthy. Unhealthy proxies are excluded from endpoint discovery. On Kubernetes, this is automatically filled if the pod has readiness probes. On Universal, it can be set by external health checking systems or [service probes](/docs/{{ page.release }}/policies/service-health-probes/).

**Type:** `Health` | **Required:** No

###### Ready

Indicates if the data plane proxy is ready to serve traffic.

**Type:** `bool` | **Required:** No

##### Service probe

Parameters for probing the service's health. When defined, Envoy periodically health checks the application and reports status to the control plane. On Kubernetes, this relies on Kubernetes probes instead.

**Type:** `ServiceProbe` | **Required:** No

###### Interval

Time between consecutive health checks.

**Type:** `Duration` | **Required:** No

###### Timeout

Maximum time to wait for a health check response.

**Type:** `Duration` | **Required:** No

###### Unhealthy threshold

Number of consecutive unhealthy checks before marking a host unhealthy.

**Type:** `uint32` | **Required:** No

###### Healthy threshold

Number of consecutive healthy checks before marking a host healthy.

**Type:** `uint32` | **Required:** No

###### TCP

TCP health checker that attempts to establish a TCP connection.

**Type:** `Tcp` | **Required:** No

##### State

Current state of the inbound listener:

- `Ready`: Inbound is ready to serve traffic
- `NotReady`: Inbound is not ready to serve traffic
- `Ignored`: Inbound is not created and cannot be targeted by policies, but the data plane proxy receives a certificate with this inbound's identity

**Type:** `State` (enum: `Ready`, `NotReady`, `Ignored`) | **Required:** No

##### Name

Optional name for referencing this inbound port, usable with [MeshService](/docs/{{ page.release }}/networking/meshservice/).

**Type:** `string` | **Required:** No

#### Outbound

List of services consumed by the data plane proxy. Each outbound creates a corresponding Envoy listener. Outbounds are only needed when not using [transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/).

**Type:** `[]Outbound` | **Required:** No

##### Address

IP on which the consumed service is available to this data plane proxy. On Kubernetes, this is typically a ClusterIP or PodIP of a headless service.

**Type:** `string` | **Required:** No | **Default:** `127.0.0.1`

##### Port

Port on which the consumed service is available. Without transparent proxying, Envoy binds to this port.

**Type:** `uint32` | **Required:** Yes

##### Tags

Tags of consumed data plane proxies. The `kuma.io/service` tag is required. These tags can be referenced in policy `destinations` sections. It's recommended to only use `kuma.io/service` and configure routing via [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/) or [MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/) instead of version-specific outbounds.

**Type:** `map<string, string>` | **Required:** When not using `backendRef`

##### Backend ref

Reference to a [MeshService](/docs/{{ page.release }}/networking/meshservice/). Experimental feature.

**Type:** `BackendRef` | **Required:** No

###### Kind

Type of object to target. Allowed value: `MeshService`

**Type:** `string` | **Required:** Yes

###### Name

Name of the targeted object.

**Type:** `string` | **Required:** Yes

###### Port

Port of the targeted object. Required when kind is `MeshService`.

**Type:** `uint32` | **Required:** When `kind=MeshService`

###### Labels

Labels to select a single object. If no object matches, the outbound is not created. If multiple objects match, the oldest is used.

**Type:** `map<string, string>` | **Required:** No

#### Gateway

Configuration for gateway mode. A gateway data plane proxy receives inbound traffic from outside the mesh and forwards it to services within the mesh.

**Type:** `Gateway` | **Required:** No

##### Tags

Tags associated with this gateway (for example, `kuma.io/service=gateway`). The `kuma.io/service` tag is mandatory.

**Type:** `map<string, string>` | **Required:** Yes (must include `kuma.io/service`)

##### Type

Type of gateway:

- `DELEGATED`: An independently deployed proxy (like Kong or Contour) that receives traffic from outside the mesh and forwards it through the data plane proxy
- `BUILTIN`: The data plane proxy itself acts as the gateway

**Type:** `GatewayType` (enum: `DELEGATED`, `BUILTIN`) | **Required:** No | **Default:** `DELEGATED`

#### Transparent proxying

Configuration for [transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/), which automatically intercepts traffic without requiring application configuration changes. Enabled by default on Kubernetes.

**Type:** `TransparentProxying` | **Required:** No

##### Redirect port inbound

Port to which all inbound traffic is transparently redirected.

**Type:** `uint32` | **Required:** Yes (when transparent proxying enabled)

##### Redirect port outbound

Port to which all outbound traffic is transparently redirected.

**Type:** `uint32` | **Required:** Yes (when transparent proxying enabled)

##### Direct access services

List of services accessed directly via IP:PORT, bypassing the proxy. Use `*` to access every service directly. Using `*` is resource-intensive—only use when needed.

**Type:** `[]string` | **Required:** No

##### Reachable services

List of services (by `kuma.io/service` value) reachable via transparent proxying. Setting an explicit list can dramatically improve mesh performance. If not specified, all mesh services are reachable.

**Type:** `[]string` | **Required:** No

##### IP family mode

IP family mode for transparent proxying:

- `DualStack`: Enables IPv4 and IPv6 (default)
- `IPv4`: IPv4 only
- `IPv6`: IPv6 only (future support)

**Type:** `IpFamilyMode` (enum: `DualStack`, `IPv4`, `IPv6`) | **Required:** No | **Default:** `DualStack`

##### Reachable backends

List of [MeshService](/docs/{{ page.release }}/networking/meshservice/), [MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice/), or [MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice/) backends reachable via transparent proxy. Setting an explicit list can dramatically improve performance. If not specified, all services are reachable.

**Type:** `ReachableBackends` | **Required:** No

###### Refs

List of backend references.

**Type:** `[]ReachableBackendRef` | **Required:** No

- `kind`: Type of backend (`MeshService`, `MeshExternalService`, `MeshMultiZoneService`)
- `name`: Backend name
- `namespace`: Backend namespace (optional)
- `port`: Backend port (optional)
- `labels`: Labels for backend selection (optional)

#### Admin

Configuration for Envoy's [admin interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin). For security, all admin endpoints are exposed only on localhost. The `/ready` endpoint is additionally exposed on `networking.address` for health checks. Other endpoints on `networking.address` are protected by mTLS for internal control plane use.

**Type:** `EnvoyAdmin` | **Required:** No

### Metrics

Configuration for metrics collection and exposure by the data plane proxy. Settings here override defaults defined at the [Mesh](/docs/{{ page.release }}/resources/mesh/) level.

**Type:** `MetricsBackend` | **Required:** No

### Probes

Configuration for exposing application endpoints without mTLS, useful for health check endpoints that orchestration systems (like Kubernetes) need to access. On Kubernetes, this feature is deprecated and no longer needed.

**Type:** `Probes` | **Required:** No | **Deprecated:** Yes (Universal only going forward)

#### Port

Port on which probe endpoints are exposed. Must not overlap with other ports.

**Type:** `uint32` | **Required:** Yes (when probes enabled)

#### Endpoints

List of endpoints to expose without mTLS.

**Type:** `[]Endpoint` | **Required:** No

##### Inbound port

Application port from which to expose the endpoint.

**Type:** `uint32` | **Required:** Yes

##### Inbound path

Application path from which to expose the endpoint. Should be as specific as possible.

**Type:** `string` | **Required:** Yes

##### Path

Path on which to expose the inbound path on the probes port.

**Type:** `string` | **Required:** Yes

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
