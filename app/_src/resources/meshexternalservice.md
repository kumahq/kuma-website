---
title: MeshExternalService
description: Reference for MeshExternalService resource that enables mesh workloads to consume external services with TLS origination, custom endpoints, and policy support.
keywords:
  - MeshExternalService
  - external services
  - networking
content_type: reference
category: resource
---

{% warning %}
This resource is experimental.
{% endwarning %}

`MeshExternalService` enables services inside the mesh to consume services outside the mesh. Unlike [MeshPassthrough](/docs/{{ page.release }}/policies/meshpassthrough/) which allows transparent traffic to external services, `MeshExternalService` declares external destinations as first-class resources with custom hostnames, virtual IPs, and policy targeting support.

{{site.mesh_product_name}} performs TLS origination at the sidecar proxy, allowing plaintext communication from applications while establishing secure connections to external endpoints. This enables centralized TLS management, certificate validation, and mTLS client authentication.

{% tip %}
For usage patterns, configuration examples, and differences from MeshPassthrough, see the [MeshExternalService guide](/docs/{{ page.release }}/networking/meshexternalservice/).
{% endtip %}

## Prerequisites

{% if_version gte:2.9.x %}

- [ZoneEgress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/) must be enabled
- [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) must be configured

{% endif_version %}

- [HostnameGenerator](/docs/{{ page.release }}/networking/hostnamegenerator/) with `meshExternalService` selector for DNS resolution

## Spec fields

| Field | Description |
|-------|-------------|
| `match` | Defines traffic routing rules. Required. |
| `match.type` | Match type, must be `HostnameGenerator`. Default: `HostnameGenerator`. |
| `match.port` | Port number for incoming requests (1-65535). Required. |
| `match.protocol` | Protocol: `tcp` (default), `grpc`, `http`, `http2`. |
| `endpoints` | Destination addresses for traffic. Optional if `extension` is configured. |
| `endpoints[].address` | IP address, domain name, or unix socket (`unix:///path/to/socket`). |
| `endpoints[].port` | Destination port number (1-65535, not used for unix sockets). |
| `tls` | TLS origination configuration. Optional. |
| `tls.enabled` | Enable TLS origination at sidecar. Default: `false`. |
| `tls.version` | TLS version constraints. |
| `tls.version.min` | Minimum TLS version: `TLSAuto` (default), `TLS10`, `TLS11`, `TLS12`, `TLS13`. |
| `tls.version.max` | Maximum TLS version: `TLSAuto` (default), `TLS10`, `TLS11`, `TLS12`, `TLS13`. |
| `tls.allowRenegotiation` | Allow TLS renegotiation (not recommended). Default: `false`. |
| `tls.verification` | TLS verification settings. |
| `tls.verification.mode` | Verification mode: `Secured` (default), `SkipSAN`, `SkipCA`, `SkipAll`. |
| `tls.verification.serverName` | Override SNI server name. |
| `tls.verification.subjectAltNames` | List of SANs to verify in certificate. |
| `tls.verification.subjectAltNames[].type` | Match type: `Exact` (default) or `Prefix`. |
| `tls.verification.subjectAltNames[].value` | Value to match against SAN. |
| `tls.verification.caCert` | CA certificate data source (`inline`, `inlineString`, or `secret` reference). |
| `tls.verification.clientCert` | Client certificate for mTLS (`inline`, `inlineString`, or `secret` reference). |
| `tls.verification.clientKey` | Client private key for mTLS (`inline`, `inlineString`, or `secret` reference). |
| `extension` | Plugin configuration for custom behavior. Optional. |
| `extension.type` | Extension type identifier. |
| `extension.config` | Freeform extension configuration. |

## Status fields

Status is managed by {{site.mesh_product_name}}:

| Field | Description |
|-------|-------------|
| `addresses` | Generated hostnames from [HostnameGenerators](/docs/{{ page.release }}/networking/hostnamegenerator/). |
| `vip.ip` | Virtual IP address allocated from mesh external service CIDR (default `242.0.0.0/8`, configurable via `KUMA_IPAM_MESH_EXTERNAL_SERVICE_CIDR`). |
| `hostnameGenerators` | Status of hostname generation from each HostnameGenerator. |

## TLS verification modes

- **`Secured`**: Full verification (CA + SAN). Default and recommended.
- **`SkipSAN`**: Verify CA only, skip SAN matching.
- **`SkipCA`**: Verify SAN only, skip CA validation.
- **`SkipAll`**: No verification (insecure, for testing only).

When `caCert` is not specified, the sidecar uses OS-specific system CA certificates. Override with `KUMA_DATAPLANE_RUNTIME_DYNAMIC_SYSTEM_CA_PATH` environment variable.

## Access control

MeshExternalService access is controlled at the [Mesh](/docs/{{ page.release }}/production/mesh/) level (MeshTrafficPermission not supported):

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    defaultForbidMeshExternalServiceAccess: true
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
routing:
  defaultForbidMeshExternalServiceAccess: true
```

{% endtab %}
{% endtabs %}

## Examples

### HTTP external service

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: httpbin
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 80
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: httpbin
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 80
```

{% endtab %}
{% endtabs %}

### HTTPS with TLS origination

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: httpbin-tls
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: httpbin.org
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: httpbin-tls
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: httpbin.org
```

{% endtab %}
{% endtabs %}

### TCP external service with mTLS

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: database
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: postgres.external.example.com
      port: 5432
  tls:
    enabled: true
    version:
      min: TLS12
      max: TLS13
    verification:
      mode: Secured
      serverName: postgres.external.example.com
      clientCert:
        secret: postgres-client-cert
      clientKey:
        secret: postgres-client-key
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: database
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: postgres.external.example.com
      port: 5432
  tls:
    enabled: true
    version:
      min: TLS12
      max: TLS13
    verification:
      mode: Secured
      serverName: postgres.external.example.com
      clientCert:
        secret: postgres-client-cert
      clientKey:
        secret: postgres-client-key
```

{% endtab %}
{% endtabs %}

### gRPC external service

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: grpc-api
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9000
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9001
  tls:
    enabled: true
    verification:
      serverName: grpcbin.test.k6.io
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: grpc-api
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9000
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9001
  tls:
    enabled: true
    verification:
      serverName: grpcbin.test.k6.io
```

{% endtab %}
{% endtabs %}

### Multiple endpoints with load balancing

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: api-gateway
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: api1.example.com
      port: 443
    - address: api2.example.com
      port: 443
    - address: 203.0.113.10
      port: 443
  tls:
    enabled: true
    verification:
      serverName: api.example.com
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: api-gateway
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: api1.example.com
      port: 443
    - address: api2.example.com
      port: 443
    - address: 203.0.113.10
      port: 443
  tls:
    enabled: true
    verification:
      serverName: api.example.com
```

{% endtab %}
{% endtabs %}

### unix domain socket

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: local-service
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: http
  endpoints:
    - address: unix:///var/run/service.sock
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: local-service
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 8080
    protocol: http
  endpoints:
    - address: unix:///var/run/service.sock
```

{% endtab %}
{% endtabs %}

### TLS with custom certificate authority

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: private-api
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: internal.corp.example.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: internal.corp.example.com
      caCert:
        secret: corporate-ca-cert
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: private-api
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: internal.corp.example.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: internal.corp.example.com
      caCert:
        secret: corporate-ca-cert
```

{% endtab %}
{% endtabs %}

### Verifying SAN with prefix matching

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: spiffe-service
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: service.example.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: service.example.com
      subjectAltNames:
        - type: Exact
          value: service.example.com
        - type: Prefix
          value: "spiffe://example.com/ns/production"
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshExternalService
name: spiffe-service
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 443
    protocol: http
  endpoints:
    - address: service.example.com
      port: 443
  tls:
    enabled: true
    verification:
      mode: Secured
      serverName: service.example.com
      subjectAltNames:
        - type: Exact
          value: service.example.com
        - type: Prefix
          value: "spiffe://example.com/ns/production"
```

{% endtab %}
{% endtabs %}

## Universal mode without transparent proxy

Configure outbound explicitly:

```yaml
type: Dataplane
mesh: default
name: backend
networking:
  address: 127.0.0.1
  inbound:
    - port: 8080
      servicePort: 8080
      tags:
        kuma.io/service: backend
  outbound:
    - port: 10080
      backendRef:
        kind: MeshExternalService
        name: httpbin
```

## See also

- [MeshExternalService guide](/docs/{{ page.release }}/networking/meshexternalservice/) - concepts and usage patterns
- [MeshPassthrough](/docs/{{ page.release }}/policies/meshpassthrough/) - transparent external traffic
- [HostnameGenerator](/docs/{{ page.release }}/networking/hostnamegenerator/) - DNS hostname generation
- [ZoneEgress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/) - egress gateway configuration
- [External Services (legacy)](/docs/{{ page.release }}/policies/external-services/) - deprecated approach

## All options

{% schema_viewer kuma.io_meshexternalservices type=crd %}
