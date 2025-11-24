---
title: MeshPassthrough
---

{% warning %}
This policy uses new policy matching algorithm.
{% endwarning %}

This policy enables {{site.mesh_product_name}} to configure traffic to external destinations that is allowed to pass outside the mesh.
When using this policy, the [passthrough mode](/docs/{{ page.release }}/networking/non-mesh-traffic/#outgoing) flag is ignored.

## TargetRef support matrix

{% tabs %}
{% tab Sidecar %}
{% if_version lte:2.9.x %}
| `targetRef`           | Allowed kinds         |
| --------------------- | --------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`  |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`           | Allowed kinds                                 |
| --------------------- | --------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `Dataplane`, `MeshSubset(deprecated)` |
{% endif_version %}
{% endtab %}
{% if_version gte:2.9.x %}
{% tab Delegated Gateway %}
| `targetRef`             | Allowed kinds        |
| ----------------------- | -------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset` |
{% endtab %}
{% endif_version %}
{% endtabs %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

{% warning %}
This policy doesn't work with sidecars without [transparent-proxy](/docs/{{ page.release }}/networking/transparent-proxying/#what-is-transparent-proxying).
{% endwarning %}

The following describes the default configuration settings of the `MeshPassthrough` policy:

- **`passthroughMode`**: (Optional) Defines behaviour for handling traffic. Allowed values: `All`, `None` and `Matched`. Default: `None`
  - **`All`** enables all traffic to pass through.
  - **`Matched`** allows only the traffic defined in `appendMatch`.
  - **`None`** disallows all traffic.
- **`appendMatch`**: List of destinations that are allowed to pass through. When `passthroughMode` is `All` or `None` this list is not used. It only takes effect when `passthroughMode` is `Matched`.
  - **`type`**: Defines what type of destination is allowed. Either `Domain`, `IP` or `CIDR`.
  - **`value`**: Destination address based on the defined `type`.
  - **`port`**: Port at which external destination is available. When not defined it caches all traffic to the address.
  - **`protocol`**: Defines protocol of the external destination.
    - **`tcp`**: **Can't be used when `type` is `Domain` (at TCP level we are not able to distinguish domain, in this case it is going to hijack whole traffic on this port)**.
    - **`tls`**: Should be used when TLS traffic is originated by the client application.
    - **`http`**
    - **`http2`**
    - **`grpc`**
    {% if_version gte:2.10.x %}- **`mysql`**{% endif_version %}
  
### Wildcard DNS matching

`MeshPassthrough` policy allows you to create a match for a wildcard subdomain.

{% warning %}
Currently, support for partial subdomain matching is not implemented. For example, a match for `*w.example.com` will be rejected.
{% endwarning %}

{% if_version eq:2.9.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: wildcard-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Sidecar"]
  default:
    passthroughMode: Matched
    appendMatch:
    - type: Domain
      value: '*.cluster-1.kafka.aws.us-east-2.com'
      protocol: tls
      port: 443
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: wildcard-passthrough
mesh: default
spec:
  targetRef:
    kind: Dataplane
  default:
    passthroughMode: Matched
    appendMatch:
    - type: Domain
      value: '*.cluster-1.kafka.aws.us-east-2.com'
      protocol: tls
      port: 443
```
{% endpolicy_yaml %}
{% endif_version %}

### Security

It is advised that the Mesh Operator is responsible for managing the `MeshPassthrough` policy.
This policy can introduce traffic outside of the mesh or even the cluster, and the Mesh Operator should be aware of this.
If you want to restrict access to `MeshPassthrough` to specific services, you must choose them manually.
If you rely on tags in the top-level `targetRef` you might consider securing them by using one of the following techniques:

* Make sure that service owners can't freely modify them (using something like [`kyverno`](https://kyverno.io/), [`OPA`](https://www.openpolicyagent.org/) or similar)
* Accept the risk of being able to "impersonate" a passthrough label and rely on auditing to figure out any violations.

### Limitations

* Due to the nature of some traffic, it is not possible to combine certain protocols on the same port. You can create a `MeshPassthrough` policy that handles `tcp`, `tls`, and one of `http`, `http2`, or `grpc` traffic on the same port. Layer 7 protocols cannot be distinguished, which could introduce unexpected behavior.
* It isn't possible to route passthrough traffic through the [zone egress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/#zone-egress).
* Wildcard domains with L7 protocol and all ports is not supported.
* {% if_version gte:2.9.x %}Builtin gateway is not supported.{% endif_version %}{% if_version lte:2.8.x %}Gateways are currently not supported.{% endif_version %}
* Envoy prioritizes matches in the following order: [first by Port, second by Address IP, and third by SNI](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener_components.proto#envoy-v3-api-msg-config-listener-v3-filterchainmatch). For example, if you have an HTTP domain match configured for a specific port (e.g., 80) and a CIDR match also configured for port 80, a request to this domain may match the CIDR configuration if the domain's address falls within the CIDR range. However, if the domain's address does not match the CIDR, the request might fail to match entirely due to the absence of an appropriate matcher for that IP. This behavior is a limitation and could potentially be addressed in the future with the adoption of the [Matcher API](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/matching/matching_api).

## Examples

### Disable passthrough for all sidecars

{% if_version eq:2.9.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: disable-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
    proxyTypes: ["Sidecar"]
  default:
    passthroughMode: None
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: disable-passthrough
mesh: default
spec:
  targetRef:
    kind: Dataplane
  default:
    passthroughMode: None
```
{% endpolicy_yaml %}
{% endif_version %}

### Enable passthrough for a subset of sidecars

{% if_version eq:2.9.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: enable-passthrough
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      kuma.io/service: demo-app_kuma-demo_svc_5000
  default:
    passthroughMode: All
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: enable-passthrough
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  default:
    passthroughMode: All
```
{% endpolicy_yaml %}
{% endif_version %}

### Allow a subset of services to communicate with specific external endpoints

{% if_version eq:2.9.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: allow-some-passthrough
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    proxyTypes: ["Sidecar"]
    tags:
      kuma.io/service: demo-app_kuma-demo_svc_5000
  default:
    passthroughMode: Matched
    appendMatch:
    - type: Domain
      value: httpbin.org
      protocol: tls
      port: 443
    - type: IP
      value: 10.240.15.39
      protocol: tcp
      port: 8888
    - type: CIDR
      value: 10.250.0.0/16
      protocol: tcp
      port: 10000
    - type: Domain
      value: '*.wikipedia.org'
      protocol: tls
      port: 443
    - type: Domain
      value: httpbin.dev
      protocol: http
      port: 80
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml %}
```yaml
type: MeshPassthrough
name: allow-some-passthrough
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  default:
    passthroughMode: Matched
    appendMatch:
    - type: Domain
      value: httpbin.org
      protocol: tls
      port: 443
    - type: IP
      value: 10.240.15.39
      protocol: tcp
      port: 8888
    - type: CIDR
      value: 10.250.0.0/16
      protocol: tcp
      port: 10000
    - type: Domain
      value: '*.wikipedia.org'
      protocol: tls
      port: 443
    - type: Domain
      value: httpbin.dev
      protocol: http
      port: 80
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
### Allow a service to communicate with MySQL

{% warning %}
The `mysql` protocol does not support `type: Domain` due to the nature of the handshake and an `Envoy` limitation that disrupts the connection to MySQL when using [inspector](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/tls_inspector).
{% endwarning %}

{% policy_yaml %}
```yaml
type: MeshPassthrough
name: allow-mysql-connection
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  default:
    passthroughMode: Matched
    appendMatch:
    - type: CIDR
      value: 10.250.0.0/16
      protocol: mysql
      port: 3306
```
{% endpolicy_yaml %}
{% endif_version %}

## See also

- [MeshExternalService](../networking/meshexternalservice) - Define external services in the mesh
- [MeshTrafficPermission](meshtrafficpermission) - Control access to external destinations
- [Non-mesh traffic](../networking/non-mesh-traffic) - Understanding passthrough modes

## All policy options

{% json_schema MeshPassthroughs %}
