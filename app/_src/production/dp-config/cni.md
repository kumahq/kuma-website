---
title: Configure the Kuma CNI
content_type: how-to
---

The operation of the {{site.mesh_product_name}} data plane proxy,
precludes that all the relevant inbound and outbound traffic on the host (or container)
that runs the service is diverted to pass through the proxy itself.
This is done through {% if_version lte:2.1.x %}[transparent proxying](/docs/{{ page.version }}/networking/transparent-proxying){% endif_version %}{% if_version gte:2.2.x %}[transparent proxying](/docs/{{ page.version }}/production/dp-config/transparent-proxying/){% endif_version %},
which is set up automatically on Kubernetes.
Installing it requires certain privileges,
which are delegated to pre-sidecar initialisation steps.
There are two options to do this with {{site.mesh_product_name}}:

- use the standard `kuma-init`, which is the default
- use the {{site.mesh_product_name}} CNI

{{site.mesh_product_name}} CNI can be leveraged in the two installation methods for Kubernetes: using 
{% if_version lte:2.1.x %}[`kumactl`](/docs/{{ page.version }}/installation/kubernetes) and with [Helm](/docs/{{ page.version }}/installation/helm){% endif_version %}
{% if_version gte:2.2.x %}[`kumactl`](/docs/{{ page.version }}/production/install-kumactl/) and with [Helm](/docs/{{ page.version }}/production/install-kumactl/){% endif_version %}.
The default settings are tuned for OpenShift with Multus,
therefore to use it in other environments we need to set the relevant configuration parameters.

{% warning %}
{{site.mesh_product_name}} CNI applies NetworkAttachmentDefinition(NAD) to applications in a namespace with `kuma.io/sidecar-injection` label.
To apply NAD to the applications not in a Mesh, add the label `kuma.io/sidecar-injection` with the value `disabled` to the namespace.
{% endwarning %}

## Installation

Below are the details of how to set up {{site.mesh_product_name}} CNI in different environments using both `kumactl` and `helm`.

{% tabs installation useUrlFragment=false %}
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

The CNI v2 is a rewritten and improved version of our original transparent-proxy.  

To install v2 CNI append the following options to the command from [installation](#installation):

```
--set ... \
--set "{{site.set_flag_values_prefix}}cni.enabled=true" \
--set "{{site.set_flag_values_prefix}}experimental.cni=true"
```

Currently, the v2 CNI is behind an `experimental` flag, but it is default in versions newer than 2.2.x 
{% endif_version %}

### {{site.mesh_product_name}} CNI Taint controller

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

## {{site.mesh_product_name}} CNI Logs

{% if_version lte:2.1.x %}
Logs of the CNI plugin are available in `/tmp/kuma-cni.log` on the node and the logs of the installer are available via `kubectl logs`.

If you are using the CNI v2 or eBPF version logs will be available via `kubectl logs` instead.
{% endif_version %}

{% if_version gte:2.2.x %}
Logs of the installer are available via `kubectl logs`.
{% endif_version %}
