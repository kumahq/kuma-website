# Secret Management

Kuma lets you store sensitive information such as TLS keys, tokens etc. and reference them in Kuma policies.
Every Secret stored in Kuma is in a scope of the Mesh.

## Management

### Universal

The following snippet presents the format of Secret

```yaml
type: Secret
name: sample-secret
mesh: default
data: dGVzdAo= # bytes encoded in Base64
```

Use `kumactl` to manage secret like any other Kuma resource on Universal.

```sh
$ cat secret.yaml
type: Secret
mesh: default
name: sample-secret
data: dGVzdAo=

$ kumactl apply -f secret.yaml

$ kumactl get secrets
MESH      NAME
default   sample-secret 
```

#### Access to the Secret API

This API is exposed on Admin Server which means that by default it is only available on the same machine as the Control Plane.
Consult [Accessing Admin Server from a different machine](security/#accessing-admin-server-from-a-different-machine) how to configure remote access.

### Kubernetes

On Kubernetes, Kuma leverages native [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) mechanism.
Kuma secrets are stored in the same namespace as the Control Plane with type of `system.kuma.io/secret`

The following snippet presents the format of Secret that will be picked by Kuma

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
$ cat secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: kuma-system
  labels:
    kuma.io/mesh: default 
data:
  value: dGVzdAo=
type: system.kuma.io/secret

$ kubectl apply -f secret.yaml

$ kubectl get secrets -n kuma-system --field-selector='type=system.kuma.io/secret'
NAME            TYPE                    DATA   AGE
sample-secret   system.kuma.io/secret   1      3m12s
```

Kubernetes Secret belongs to one Mesh and it is identified by name + namespace, therefore it is not possible to have a Secret with the same name in multiple meshes.

To change the Mesh in which Secret belongs, first delete a Secret and reapply it again. 

Secrets without explicitly specified `kuma.io/mesh` belongs to `default` Mesh. 

::: tip
Kuma Secret stores encoded bytes in Base64. Use builtin `base64` in Linux and MacOS to encode the value:
```sh
$ cat cert.pem | base64
$ echo "token" | base64
```
:::

## Reference

Here is example of how you can reference Secret in Provided CA functionality

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
        secret: my-cert # name of the Kuma Secret
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
          secret: my-cert # name of the Kubernetes Secret   
```

