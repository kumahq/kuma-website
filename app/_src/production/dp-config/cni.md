---
title: Configure the Kuma CNI
content_type: how-to
---

In order for traffic to flow through the {{site.mesh_product_name}} data plane, all inbound and
outbound traffic for a service needs to go through its data plane proxy.
The recommended way of accomplishing this is via {% if_version lte:2.1.x %}[transparent proxying](/docs/{{ page.version }}/networking/transparent-proxying){% endif_version %}{% if_version gte:2.2.x %}[transparent proxying](/docs/{{ page.version }}/production/dp-config/transparent-proxying/){% endif_version %}.

On Kubernetes it's handled automatically by default with the
`initContainer` `kuma-init`, but this container requires certain privileges.

Another option is to use the {{site.mesh_product_name}} CNI. This frees every
`Pod` in the mesh from requiring said privileges, which can make security compliance easier.

{% tip %}
The CNI `DaemonSet` itself requires elevated privileges because it
writes executables to the host filesystem as `root`.
{% endtip %}

Install the CNI using either
{% if_version lte:2.1.x %}[`kumactl`](/docs/{{ page.version }}/installation/kubernetes) or [Helm](/docs/{{ page.version }}/installation/helm){% endif_version %}
{% if_version gte:2.2.x %}[`kumactl`](/docs/{{ page.version }}/production/install-kumactl/) or [Helm](/docs/{{ page.version }}/production/install-kumactl/){% endif_version %}.
The default settings are tuned for OpenShift with Multus.
To use it in other environments, set the relevant configuration parameters.

{% warning %}
{{site.mesh_product_name}} CNI applies `NetworkAttachmentDefinitions` to applications in any namespace with `kuma.io/sidecar-injection` label.
To apply `NetworkAttachmentDefinitions` to applications not in a Mesh, add the label `kuma.io/sidecar-injection` with the value `disabled` to the namespace.
{% endwarning %}

## Installation

Below are the details of how to set up {{site.mesh_product_name}} CNI in different environments using both `kumactl` and `helm`.

{% tabs installation useUrlFragment=false %}
{% tab installation Cilium %}
{% tabs cilium useUrlFragment=false %}
{% tab cilium kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=05-cilium.conflist"
```

{% endtab %}
{% tab cilium helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=05-cilium.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}

{% warning %}
For Cilium versions < 1.14 you should use `{{site.set_flag_values_prefix}}cni.confName=05-cilium.conf` as this has changed
for version starting from [Cilium 1.14](https://docs.cilium.io/en/stable/operations/upgrade/#id2).
{% endwarning %}

{% endtab %}
{% tab installation Calico %}

{% tabs calico useUrlFragment=false %}
{% tab calico kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-calico.conflist"
```

{% endtab %}
{% tab calico Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-calico.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation K3D with Flannel %}
{% tabs k3d useUrlFragment=false %}
{% tab k3d kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-flannel.conflist"
```

{% endtab %}
{% tab k3d Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-flannel.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation Kind %}
{% tabs kind useUrlFragment=false %}
{% tab kind kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-kindnet.conflist"
```

{% endtab %}
{% tab kind Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-kindnet.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation Azure %}
{% tabs azure useUrlFragment=false %}
{% tab azure kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-azure.conflist"
```

{% endtab %}
{% tab azure Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-azure.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation Azure Overlay %}
{% tabs azure_overlay useUrlFragment=false %}
{% tab azure_overlay kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=15-azure-swift-overlay.conflist"
```

{% endtab %}
{% tab azure_overlay Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=15-azure-swift-overlay.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation AWS - EKS %}
{% tabs aws-eks useUrlFragment=false %}
{% tab aws-eks kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-aws.conflist" \
  --set "{{site.set_flag_values_prefix}}runtime.kubernetes.injector.sidecarContainer.redirectPortInboundV6=0" # EKS does not have ipv6 enabled by default
```

{% endtab %}
{% tab aws-eks Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/opt/cni/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-aws.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation Google - GKE %}

You need to [enable network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster (for existing clusters this redeploys the nodes).

{% tabs google-gke useUrlFragment=false %}
{% tab google-gke kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/home/kubernetes/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-calico.conflist"
```

{% endtab %}
{% tab google-gke Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.chained=true" \
  --set "{{site.set_flag_values_prefix}}cni.netDir=/etc/cni/net.d" \
  --set "{{site.set_flag_values_prefix}}cni.binDir=/home/kubernetes/bin" \
  --set "{{site.set_flag_values_prefix}}cni.confName=10-calico.conflist" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab insallation OpenShift 3.11 %}

1. Follow the instructions in [OpenShift 3.11 installation](/docs/{{ page.version }}/installation/openshift/#2-run-kuma)
   to get the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` enabled (this is required for regular {{site.mesh_product_name}} installation).

2. You need to grant privileged permission to kuma-cni service account:

```shell
oc adm policy add-scc-to-user privileged -z kuma-cni -n kube-system
```

{% tabs openshift-3 useUrlFragment=false %}
{% tab openshift-3 kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.containerSecurityContext.privileged=true"
```

{% endtab %}
{% tab openshift-3 Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
  --set "{{site.set_flag_values_prefix}}cni.containerSecurityContext.privileged=true" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% tab installation OpenShift 4 %}

{% tabs openshift-4 useUrlFragment=false %}
{% tab openshift-4 kumactl %}

```shell
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true"
```

{% endtab %}
{% tab openshift-4 Helm %}

```shell
helm install --create-namespace --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}cni.enabled=true" \
   {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endtab %}
{% endtabs %}
{% endtab %}

{% endtabs %}

{% if_version lte:2.1.x %}

## {{site.mesh_product_name}} CNI v2

The CNI v2 is a rewritten and improved version of the previous transparent-proxy.

To install v2 CNI append the following options to the command from [installation](#installation):

```
--set ... \
--set "{{site.set_flag_values_prefix}}cni.enabled=true" \
--set "{{site.set_flag_values_prefix}}experimental.cni=true"
```

Until 2.2.x the v2 CNI was behind an `experimental` flag, but now it's the default.
{% endif_version %}

### {{site.mesh_product_name}} CNI taint controller

To prevent a race condition described in [this issue](https://github.com/kumahq/kuma/issues/4560) a new controller was implemented.
The controller will taint a node with `NoSchedule` taint to prevent scheduling before the CNI DaemonSet is running and ready.
Once the CNI DaemonSet is running and ready it will remove the taint and allow other pods to be scheduled into the node.

To disable the taint controller use the following env variable:

```
KUMA_RUNTIME_KUBERNETES_NODE_TAINT_CONTROLLER_ENABLED=false
```

## Merbridge CNI with eBPF

To install merbridge CNI with eBPF append the following options to the command from [installation](#installation):

{% warning %}
To use Merbridge CNI with eBPF your environment has to use `Kernel >= 5.7`
and have `cgroup2` available
{% endwarning %}

```
--set ... \
--set "{{site.set_flag_values_prefix}}cni.enabled=true" \
--set "{{site.set_flag_values_prefix}}experimental.ebpf.enabled=true"
```

## {{site.mesh_product_name}} CNI logs

{% if_version lte:2.1.x %}
Logs of the CNI plugin are available in `/tmp/kuma-cni.log` on the node and the logs of the installer are available via `kubectl logs`.

If you are using the CNI v2 version logs are available via `kubectl logs` instead.
{% endif_version %}

{% if_version gte:2.2.x %}
Logs are available via `kubectl logs`.

{% warning %}
eBPF CNI currently doesn't have support for exposing its logs.
{% endwarning %}

{% endif_version %}
