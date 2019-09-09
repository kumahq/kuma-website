# Policies

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

Once installing Kuma

## Mesh

This policy allows to create multiple Service Meshes on top of the same Kuma cluster.

On Universal:

```yaml
type: Mesh
mesh: default
name: default
```

On Kuberentes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
spec:
  name: default
```

Because of a limitation of Kuma 0.1, you will have to type the `name` of the Mesh also in a `mesh` field. The redundant `mesh` field will be removed from Kuma starting from version 0.2.

## Mutual TLS

By default, mTLS is **not** enabled. You can enable Mutual TLS by updating the [`Mesh`](#mesh) policy with the `mtls` setting.

On Universal:

```yaml
type: Mesh
mesh: default
name: default
mtls:
  enabled: true 
  ca:
    builtin: {}
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
spec:
  name: default
  mtls:
    enabled: true 
    ca:
      builtin: {}
```

Currently Kuma supports self-signed certificates for every data-plane in the Mesh (`builtin`). In the future we plan to add support for third-party Certificate Authorities.

## Traffic Permissions

TODO: Document YAML object

## Traffic Route

TODO: Document YAML object

## Traffic Tracing

TODO: Document YAML object

## Traffic Logging

TODO: Document YAML object

## Proxy Configuration

TODO: Document YAML object