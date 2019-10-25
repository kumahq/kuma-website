# Kubernetes

::: tip
**Don't forget!** The [Official Documentation](/docs/%%VER%%/) of Kuma is a great place to learn about both basic and more advanced topics.
:::

To install and run Kuma on Kubernetes execute the following steps:

## 1. Download and run Kuma

To run Kuma on Kubernetes, you need to download a compatible version of Kuma for the machine where you will be executing the commands.

* [CentOS](https://kong.bintray.com/kuma/kuma-%%VER%%-centos-amd64.tar.gz)
* [RedHat](https://kong.bintray.com/kuma/kuma-%%VER%%-rhel-amd64.tar.gz)
* [Debian](https://kong.bintray.com/kuma/kuma-%%VER%%-debian-amd64.tar.gz)
* [Ubuntu](https://kong.bintray.com/kuma/kuma-%%VER%%-ubuntu-amd64.tar.gz)
* [macOS](https://kong.bintray.com/kuma/kuma-%%VER%%-darwin-amd64.tar.gz)

Once downloaded, we can extract the content of the archive with:

```sh
$ tar xvzf [FILE]
$ cd bin && ls
envoy   kuma-cp   kuma-dp   kuma-tcp-echo kumactl
```

::: tip
**Note**: On Kubernetes - of all the Kuma binaries in the `bin` folder - we only need `kumactl`.
:::

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
* We are adding a `kuma.io/mesh: default` annotation to determine on what [`Mesh`](/docs/%%VER%%/policies/#mesh) the service belongs.

## 3. Apply Policies

Now you can start applying [Policies](/docs/%%VER%%/policies) to your `default` Service Mesh, like Mutual TLS:

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

You can now review the entities created by Kuma by using the [`kumactl`](/docs/%%VER%%/documentation/#kumactl) CLI. For example you can list the Meshes:

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