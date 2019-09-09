# Policies

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

Once installed, Kuma can be configured via its policies. You can apply policies with `kumactl` on Universal, and with `kubectl` on Kubernetes. Regardless of what environment you use, you can always read the latest Kuma state with `kumactl` on both environments.

::: tip
We follow the best practices. You should always change your Kubernetes state with CRDs, that's why Kuma disables `kumactl apply` when running on K8s environments.
:::

These policies can be applied either by file via the `kumactl -f [path]` or `kubectl -f [path]` syntax, or by using the following command:

```sh
echo "
  type: ..
  spec: ..
" | kumactl -f -
```

or - on Kubernetes - by using the equivalent:

```sh
echo "
  apiVersion: kuma.io/v1alpha1
  kind: ..
  spec: ..
" | kubectl -f -
```

Below you can find the policies that Kuma supports. In addition to `kumactl`, you can also retrive the state via the Kuma HTTP API as well.

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

You can apply with `kumactl -f [file-path]`.

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

You can apply with `kubectl -f [file-path]`.

Currently Kuma supports self-signed certificates for every data-plane in the Mesh (`builtin`). In the future we plan to add support for third-party Certificate Authorities.

## Traffic Permissions

TODO: Document YAML object

## Traffic Route

Join us on [Slack](/community) to get access to an early preview of Routing.

## Traffic Tracing

TODO: Document YAML object

## Traffic Logging

TODO: Document YAML object

## Proxy Configuration

TODO: Document YAML object