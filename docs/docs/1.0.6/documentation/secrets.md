# Secrets

Kuma provides a built-in interface to store sensitive information such as TLS keys and tokens that can be used later on by any policy at runtime. This functionality is being implemented by introducing a `Secret` resource.

Secrets belong to a specific [`Mesh`](/docs/1.0.6/policies/mesh) resource, and cannot be shared across different `Meshes`.

:::tip
Kuma will also leverage `Secret` resources internally for certain operations, for example when storing auto-generated certificates and keys when Mutual TLS is enabled.
:::

## Universal

A `Secret` is a simple resource that stores specific `data`:

```yaml
type: Secret
name: sample-secret
mesh: default
data: dGVzdAo= # bytes encoded in Base64
```

You can use `kumactl` to manage any `Secret` like you would do for other resources:

```sh
$ echo "type: Secret
mesh: default
name: sample-secret
data: dGVzdAo=" | kumactl apply -f -
```

### Access to the Secret HTTP API

This API is exposed on the Admin Server which means that by default it is only available on the same machine as the Control Plane.
Consult [Accessing Admin Server from a different machine](security/#accessing-admin-server-from-a-different-machine) how to configure remote access.

## Kubernetes

On Kubernetes, Kuma under the hood leverages the native [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) resource to store sensitive information.

Kuma secrets are stored in the same namespace as the Control Plane with `type` valued as `system.kuma.io/secret`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: kuma-system # Kuma will only manage secrets in the same namespace as the CP
  labels:
    kuma.io/mesh: default # specify the Mesh scope of the secret 
data:
  value: dGVzdAo= # bytes encoded in Base64
type: system.kuma.io/secret # Kuma will only manage secrets of this type
```

Use `kubectl` to manage secrets like any other Kubernetes resource.

```sh
$ echo "apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: kuma-system
  labels:
    kuma.io/mesh: default 
data:
  value: dGVzdAo=
type: system.kuma.io/secret" | kubectl apply -f -

$ kubectl get secrets -n kuma-system --field-selector='type=system.kuma.io/secret'
NAME            TYPE                    DATA   AGE
sample-secret   system.kuma.io/secret   1      3m12s
```

:::tip
Like any other Kuma resources, if `kuma.io/mesh` is not specified then the `Secret` will automatically belong to the `default` Mesh. 
:::

Kubernetes Secrets always belongs to a specific [`Mesh`](/docs/1.0.6/policies/mesh) resource and they are internally they are identified with the `name + namespace` format, therefore **it is not possible** to have a `Secret` with the same name in multiple meshes (since multiple `Meshes` always belong to one Kuma CP that always runs in one Namespace).

In order to reassign a `Secret` to another `Mesh` you need to delete the `Secret` resource and apply it again.

::: tip
The `data` field of a Kuma `Secret` should always be a Base64 encoded value. You can use the `base64` command in Linux or macOS to encode any value in Base64:

```sh
# Base64 encode a file
$ cat cert.pem | base64

# or Base64 encode a string
$ echo "value" | base64
```
:::

## Usage

Here is example of how you can use a Kuma `Secret` with a `provided` [Mutual TLS](/docs/1.0.6/policies/mutual-tls) backend.

The examples below assume that the `Secret` object has already been created before-hand.

### Universal

```yaml
type: Mesh
name: default
mtls:
  backends:
  - name: ca-1
    type: provided
    config:
      cert:
        secret: my-cert # name of the Kuma Secret
      key:
        secret: my-key # name of the Kuma Secret
```

### Kubernetes

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    backends:
    - name: ca-1
      type: provided
      config:
        cert:
          secret: my-cert # name of the Kubernetes Secret
        key:
          secret: my-key # name of the Kubernetes Secret   
```
