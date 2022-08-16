# Kuma CNI

The operation of the Kuma data plane proxy,
precludes that all the relevant inbound and outbound traffic on the host (or container)
that runs the service is diverted to pass through the proxy itself.
This is done through [transparent proxying](../transparent-proxying),
which is set up automatically on Kubernetes.
Installing it requires certain privileges,
which are delegated to pre-sidecar initialisation steps.
There are two options to do this with Kuma:

* use the standard `kuma-init`, which is the default
* use the Kuma CNI

Kuma CNI can be leveraged in the two installation methods for Kubernetes: using [`kumactl`](../../installation/kubernetes) and with [Helm](../../installation/helm).
The default settings are tuned for OpenShift with Multus,
therefore to use it in other environments we need to set the relevant configuration parameters.

:::warning
Kuma CNI applies NetworkAttachmentDefinition(NAD) to applications in a namespace with `kuma.io/sidecar-injection` label.
To apply NAD to the applications not in a Mesh, add the label `kuma.io/sidecar-injection` with the value `disabled` to the namespace.
:::

# Installation

Below are the details of how to set up Kuma CNI in different environments.

To enable the CNI setup and configure it for chaining with the CNI plugin you can use both `kumactl` and `helm`.

:::::: tabs
::::: tab "Calico"

:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/opt/cni/bin" \
  --set "cni.confName=10-calico.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir="/etc/cni/net.d",cni.binDir=/opt/cni/bin,cni.confName=10-calico.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "K3D with Flannel"
:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d" \
  --set "cni.binDir=/bin" \
  --set "cni.confName=10-flannel.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d,cni.binDir=/bin,cni.confName=10-flannel.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "Kind"
:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/opt/cni/bin" \
  --set "cni.confName=10-kindnet.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/etc/cni/net.d,cni.binDir=/opt/cni/bin,cni.confName=10-kindnet.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "Azure"
:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/opt/cni/bin" \
  --set "cni.confName=10-azure.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/etc/cni/net.d,cni.binDir=/opt/cni/bin,cni.confName=10-azure.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "AWS - EKS"
:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/opt/cni/bin" \
  --set "cni.confName=10-aws.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/etc/cni/net.d,cni.binDir=/opt/cni/bin,cni.confName=10-aws.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "Google - GKE"

You need to [enable network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster (for existing clusters this redeploys the nodes).

:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/home/kubernetes/bin" \
  --set "cni.confName=10-calico.conflist"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/etc/cni/net.d,cni.binDir=/home/kubernetes/bin,cni.confName=10-calico.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::: tab "OpenShift 3.10"

You need to grant privileged permission to kuma-cni service account:

```shell
oc adm policy add-scc-to-user privileged -z kuma-cni -n kube-system
```

:::: tabs
::: tab "kumactl"

```shell
kumactl install control-plane \
  --set "cni.enabled=true" \
  --set "cni.chained=true" \
  --set "cni.netDir=/etc/cni/net.d" \
  --set "cni.binDir=/opt/cni/bin" \
  --set "cni.confName=10-calico.conflist" \
  --set "cni.securityContext.privileged=true"
```

:::
::: tab "Helm"

```shell
helm install --namespace kuma-system \
  --set cni.enabled=true,cni.chained=true,cni.netDir=/etc/cni/net.d,cni.binDir=/home/kubernetes/bin,cni.confName=10-calico.conflist \
   kuma kuma/kuma
```

:::
::::
:::::

::::::

# Kuma CNI v2

The new version of the CNI is using new [kuma-net](https://github.com/kumahq/kuma-net/) engine to do transparent proxying.

The new engine is capable of using the following methods to transparently redirect traffic:
- iptables (default)
- eBPF

To use the new CNI with eBPF add `experimental.cni=true` and `experimental.ebpf.enabled=true` settings to either `kumactl` or `helm`.

Currently, the v2 CNI is behind an `experimental` flag, but it's intended to be the default CNI in future releases.

## Taint controller

To prevent a race condition described in [this issue](https://github.com/kumahq/kuma/issues/4560) a new controller was implemented.
The controller will taint a node with `NoSchedule` taint to prevent scheduling before the CNI DaemonSet is running and ready.
Once the CNI DaemonSet is running and ready it will remove the taint and allow other pods to be scheduled into the node.

## Logs

Logs of the v2 CNI plugin are located in `/tmp/kuma-cni.log` on  the node itself
and logs of the CNI installer are located in `/tmp/install-cni.log` on the CNI DaemonSet pod.
