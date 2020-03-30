# Kubernetes

To install and run Kuma on Kubernetes execute the following steps:

### 1. Download and run Kuma

To run Kuma on Kubernetes, you need to download a compatible version of Kuma for the machine where you will be executing the commands.

```sh
curl -L https://kuma.io/installer.sh | sh -
```

Once downloaded, we can see the Kuma files by entering in the `kuma-0.4.0` directory. To enter the `bin` folder and start using `kumactl`, we can execute:

```sh
cd kuma-0.4.0/bin
```

From within the `bin` folder, we can also permanently add the Kuma binaries to our `PATH` by executing:

```sh
printf "\n#Kuma Binaries\nexport PATH=\$PATH:%s\n" "`pwd`" >> ~/.profile && \
source ~/.profile
```

::: tip
**Note**: On Kubernetes - of all the Kuma binaries in the `bin` folder - we only need `kumactl`.
:::

To install and run Kuma first connect to the appropriate Kubernetes cluster with `kubectl`, then execute:

```sh
$ ./kumactl install control-plane | kubectl apply -f -
```

By executing this operation, a new `kuma-system` namespace will be created.

### 2. Start services

On Kubernetes, we can start a simple service by executing the following command:

```sh
./kubectl apply -f https://raw.githubusercontent.com/Kong/kuma-demo/master/kubernetes/kuma-demo-aio.yaml
```

Note that two things are happening in the YAML file:

* We are including a `kuma.io/sidecar-injection: enabled` label in the `Namespace` to automatically inject Kuma sidecars into every Pod belonging to the namespace.
* We are adding a `kuma.io/mesh: default` annotation to determine on what [`Mesh`](../../policies/mesh) the service belongs.

### 3. Apply Policies

Now you can start applying [Policies](../../policies/introduction) to your `default` Service Mesh, like Mutual TLS:

```sh
$ echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabled: true
    ca:
      builtin: {}" | ./kubectl apply -f -
```

With mTLS enabled, all traffic is restricted by default unless we specify a [Traffic Permission](../../policies/traffic-permissions) policy that enables it again. For example, we can apply the following permissive policy to enable all traffic across every data-plane again:

```sh
$ echo "apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  namespace: default
  name: enable-all-traffic
spec:
  sources:
    - match:
        service: '*'
  destinations:
    - match:
        service: '*'" | ./kubectl apply -f -
```

### 4. Done!

::: tip
You can configure `kumactl` to point to any remote `kuma-cp` instance by running:

```sh
$ ./kumactl config control-planes add --name=XYZ --address=http://address.to.kuma:5681
```
:::

You can now review the entities created by Kuma by using the [`kumactl`](../../documentation/kumactl) CLI. For example you can list the Meshes and the Traffic Permissions:

```sh
$ ./kumactl get meshes
NAME      mTLS   CA        METRICS
default   on     builtin   off

$ ./kumactl get traffic-permissions
MESH      NAME
default   enable-all-traffic
```

and you can list the data-planes that have been registered, and their status:

```sh
$ ./kumactl get dataplanes
MESH      NAME        TAGS
default   dp-echo-1   service=echo

$ ./kumactl inspect dataplanes
MESH      NAME        TAGS              STATUS   LAST CONNECTED AGO   LAST UPDATED AGO   TOTAL UPDATES   TOTAL ERRORS
default   dp-echo-1   service=echo      Online   19s                  18s                2               0
```