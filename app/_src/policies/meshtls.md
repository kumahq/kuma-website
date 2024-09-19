---
title: MeshTLS
---

{% warning %}
This policy uses new policy matching algorithm.
{% endwarning %}

This policy enables {{site.mesh_product_name}} to configure TLS mode, ciphers and version. 
Backends and default mode values are taken from [the Mesh object](/docs/{{ page.version }}/policies/mutual-tls/).

## TargetRef support matrix

{% tabs targetRef useUrlFragment=false %}
{% tab targetRef For tls ciphers/version %}
| `targetRef`             | Allowed kinds       |
| ----------------------- | ------------------- |
| `targetRef.kind`        | `Mesh`              |
| `from[].targetRef.kind` | `Mesh`              |
{% endtab %}
{% tab targetRef For mode %}
| `targetRef`             | Allowed kinds        |
| ----------------------- | -------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset` |
| `from[].targetRef.kind` | `Mesh`               |
{% endtab %}
{% endtabs %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

The following describes the default configuration settings of the `MeshTLS` policy:

- **`tlsVersion`**: Defines TLS versions to be used by **both client and server**. Allowed values: `TLSAuto`, `TLS10`, `TLS11`, `TLS12`, `TLS13`.
- **`tlsCiphers`**: Defines TLS ciphers to be used by **both client and server**. Allowed values: `ECDHE-ECDSA-AES128-GCM-SHA256`, `ECDHE-ECDSA-AES256-GCM-SHA384`, `ECDHE-ECDSA-CHACHA20-POLY1305`, `ECDHE-RSA-AES128-GCM-SHA256`, `ECDHE-RSA-AES256-GCM-SHA384`, `ECDHE-RSA-CHACHA20-POLY1305`.
- **`mode`**: Defines the mTLS mode - `Permissive` mode encrypts outbound connections the same way as `Strict` mode, but inbound connections on the server-side accept both TLS and plaintext. Allowed values: `Strict`, `Permissive`.

{% tip %}
Setting the TLS version and ciphers on both the client and server makes it harder to misconfigure.
If you want to try out a specific version/cipher combination, we recommend creating a [temporary mesh](/docs/{{ page.version }}/production/mesh/#usage), deploying two applications within it, and testing whether communication is working.
If you have a use case for configuring a different set of allowed versions/ciphers on different workloads, we'd love to hear about it.
In that case, please open an [issue](https://github.com/kumahq/kuma/issues).
{% tip %}

## Examples

### Set specific TLS version and ciphers

{% policy_yaml example1 %}
```yaml
type: MeshTLS
name: set-version-and-ciphers
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        tlsVersion:
          min: TLS13
          max: TLS13
        tlsCiphers:
          - ECDHE-ECDSA-AES256-GCM-SHA384
```
{% endpolicy_yaml %}

### Enable strict mode on specific subset

{% policy_yaml example2 %}
```yaml
type: MeshTLS
name: strict-mode
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: redis_kuma-demo_svc_6379
  from:
    - targetRef:
        kind: Mesh
      default:
        mode: Strict
```
{% endpolicy_yaml %}

## All policy options

{% json_schema MeshTLSes %}
