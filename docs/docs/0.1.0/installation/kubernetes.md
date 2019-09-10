# Kubernetes

::: tip
**Don't forget!** The [Official Documentation](/docs/0.1.0/) of Kuma is a great place to learn about both basic and more advanced topics.
:::

To install and run Kuma on Kubernetes execute the following steps:

## 1. Download and run Kuma

You can download Kuma from [here]() or by running:

```sh
$ wget downloads.kuma.io/0.1.0/kuma-k8s.amd64.tar.gz
```

You can extract the archive and check the contents by running:

```sh
$ tar xvzf kuma-k8s.amd64.tar.gz
$ cd bin && ls
kumactl
```

To install and run Kuma execute:

```sh
$ kumactl install control-plane | kubectl apply -f -
```

By executing this operation, a new `kuma-system` namespace will be created.

## 2. Start services

On Kubernetes, we can start a simple service by executing the following command:

```sh
kubectl apply -f https://raw.githubusercontent.com/Kong/kuma/master/examples/kubernetes/sample-service.yaml
```

Note that two things are happening in the YAML file:

* We are including a `kuma.io/sidecar-injection: enabled` label in the `Namespace` to automatically inject Kuma sidecars into every Pod belonging to the namespace.
* We are adding a `kuma.io/mesh: default` annotation to determine on what [`Mesh`](/docs/0.1.0/policies/#mesh) the service belongs.

## 3. Apply Policies

Now you can start applying [Policies](/docs/0.1.0/policies) to your `default` Service Mesh, like Mutual TLS:

```sh
$ echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  mtls:
    enabled: true
    ca:
      builtin: {}" | kubectl apply -f -
```

## 4. Done!

::: tip
You can configure `kumactl` to point to any remote `kuma-cp` instance by running:

```sh
$ kumactl config control-planes add --name=XYZ --address=http://address.to.kuma:5681
```
:::

You can now review the entities created by Kuma by using the [`kumactl`](/docs/0.1.0/documentation/#kumactl) CLI. For example you can list the Meshes:

```sh
$ kumactl get meshes
NAME
default
```

and you can list the data-planes that have been registered, and their status:

```sh
$ kumactl get dataplanes
MESH      NAME        TAGS
default   dp-echo-1   service=echo

$ kumactl inspect dataplanes
MESH      NAME        TAGS              STATUS   LAST CONNECTED AGO   LAST UPDATED AGO   TOTAL UPDATES   TOTAL ERRORS
default   dp-echo-1   service=echo      Online   19s                  18s                2               0
```