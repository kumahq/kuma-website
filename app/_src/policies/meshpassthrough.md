---
title: MeshPassthrough
---

{% warning %}
This policy uses new policy matching algorithm.
{% endwarning %}

This policy enables {{site.mesh_product_name}} to configure external traffic for specific sidecar.
When using this policy, the [passthrough mode](/docs/{{ page.version }}/networking/non-mesh-traffic/#outgoing) flag is ignored.

## TargetRef support matrix

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`           | Allowed kinds        |
| --------------------- | ---------------------|
| `targetRef.kind`      | `Mesh`, `MeshSubset` |
{% endtab %}
{% endtabs %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

{% warning %}
This policy doesn't work with sidecars not using [transparent-proxy](/docs/{{ page.version }}/networking/transparent-proxying/#what-is-transparent-proxying)
{% endwarning %}

The following describes the default configuration settings of the `MeshPassthrough` policy:

- **`enabled`**: (Optional) If true, allows traffic to all external destinations.
- **`appendMatch`**: List of destinations that sidecar should be able to reach. When `enabled` is `true` this list is not used. It works only when `enabled` is `false`.
  - **`type`**: Defines what type of destination should be allowed. Either `Domain`, `IP` or `CIDR`
  - **`value`**: Destination address based on the defined `type`.
  - **`port`**: Port at which exterbal service is available. When not defined it caches all traffic to the address.
  - **`protocol`**: Defines protocol of the external service.
    - **`tcp`**: **Can't be used when `type` is `Domain` (at TCP level we are not able to disinguish domain, in this case it is going to hijack whole traffic on this port)**.
    - **`tls`**:  Should be used when TLS traffic is originated by the client application.
    - **`http`**
    - **`http2`**
    - **`grpc`**
  
### Wildcard domains

A `MeshPassthrough` policy allows you to create a match for a wildcard domain. You can match a subdomain and allow this traffic to go outside of the cluster.

{% warning %}
Currently, partial matches are not possible. For example, the domain `*ww.example.com` will be rejected.
{% endwarning %}

{% policy_yaml wildcard %}
```yaml
type: MeshPassthrough
name: wildcard-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    appendMatch:
    - type: Domain
      value: `*.cluster-1.kafka.aws.us-east-2.com`
      protocol: tls
      port: 443
```
{% endpolicy_yaml %}

### Security

It is advised that the `MeshOperator` is responsible for the `MeshPassthrough` policy. This policy can introduce traffic outside of the mesh or even the cluster, and the `MeshOperator` should be aware of this. If you want to secure access to `MeshPassthrough` to specific services, you must choose them manually. If you rely on tags in the top-level `targetRef` you might consider securing them by one of the:

* Make sure that service owners can't freely set them (using something like `kyverno`, `OPA`)
* Accept the risk of being able to "impersonate" a passthrough label and rely on auditing.

### Limitations

* Due to the nature of some traffic, it is not possible to combine certain protocols on the same port. You can create a `MeshPassthrough` policy that handles `tcp`, `tls`, and one of `http`, `http2`, or `grpc` traffic on the same port. Layer 7 protocols cannot be distinguished, which could introduce unexpected behavior.
* It is currently not possible to route passthrough traffic through the [zone egress](/docs/{{ page.version }}/production/cp-deployment/zoneegress/#zone-egress). However, this feature will be implemented in the future.
* Gateways are currently not supported.

## Examples

### Disable passthrough for all sidecars

{% policy_yaml example1 %}
```yaml
type: MeshPassthrough
name: disable-passthrough
mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    enabled: false
```
{% endpolicy_yaml %}

### Enable passthrough for a subset sidecars

{% policy_yaml example2 %}
```yaml
type: MeshPassthrough
name: enable-passthrough
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: demo-app_kuma-demo_svc_5000
  default:
    enabled: true
```
{% endpolicy_yaml %}

### Allow a subset of services to communicate with specifc external endpoints

{% policy_yaml example3 %}
```yaml
type: MeshPassthrough
name: allow-some-passthrough
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: demo-app_kuma-demo_svc_5000
  default:
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

## All policy options

{% json_schema MeshPassthrough %}
