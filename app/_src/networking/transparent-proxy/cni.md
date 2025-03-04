---
title: Configure the Kuma CNI
content_type: how-to
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma-system = site.mesh_namespace %}

In order for traffic to flow through the {{ Kuma }} data plane, all inbound and outbound traffic for a service needs to go through its data plane proxy. The recommended way of accomplishing this is via [transparent proxying]({{ docs }}/{% if_version lte:2.8.x %}production/dp-config/transparent-proxying/{% endif_version %}{% if_version gte:2.9.x %}networking/transparent-proxy/introduction/{% endif_version %}).

On Kubernetes it's handled automatically by default with the `initContainer` `kuma-init`, but this container requires certain privileges.

Another option is to use the {{ Kuma }} CNI. This frees every `Pod` in the mesh from requiring said privileges, which can make security compliance easier.

{% tip %}
The CNI `DaemonSet` itself requires elevated privileges because it writes executables to the host filesystem as `root`.
{% endtip %}

Install the CNI using either {% if_version lte:2.8.x %}[kumactl]({{ docs }}/production/install-kumactl/) or [Helm]https://helm.sh/){% endif_version %}{% if_version gte:2.9.x %}[kumactl]({{ docs }}/introduction/install/) or [Helm](https://helm.sh/).{% endif_version %}
The default settings are tuned for OpenShift with Multus. To use it in other environments, set the relevant configuration parameters.

{% warning %}
{{ Kuma }} CNI applies `NetworkAttachmentDefinitions` to applications in any namespace with `kuma.io/sidecar-injection` label. To apply `NetworkAttachmentDefinitions` to applications not in a Mesh, add the label `kuma.io/sidecar-injection` with the value `disabled` to the namespace.
{% endwarning %}

## Installation

Below are the details of how to set up {{ Kuma }} CNI in different environments using both `kumactl` and `helm`.

{% tabs installation useUrlFragment=false %}
{% tab installation Cilium %}
{% cpinstall cilium %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=05-cilium.conflist
{% endcpinstall %}

{% warning %}
You need to set the Cilium config value `cni-exclusive` or the corresponding Helm chart value `cni.exclusive` to `false` in order to use Cilium and {{ site.mesh_product_name }} together. This is necessary starting with the release of Cilium v1.14.
{% endwarning %}

{% warning %}
For installing {{ Kuma }} CNI with Cilium on GKE, you should follow the `Google - GKE` section.
{% endwarning %}

{% warning %}
For Cilium versions < 1.14 you should use `{{site.set_flag_values_prefix}}cni.confName=05-cilium.conf` as this has changed for version starting from [Cilium 1.14](https://docs.cilium.io/en/v1.14/operations/upgrade/#id2).
{% endwarning %}
{% endtab %}

{% tab installation Calico %}
{% cpinstall calico %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-calico.conflist
{% endcpinstall%}

{% warning %}
For installing {{ Kuma }} CNI with Calico on GKE, you should follow the `Google - GKE` section.
{% endwarning %}
{% endtab %}

{% tab installation K3D %}
{% warning %}
**Important**: These instructions apply to [k3d](https://k3d.io) with the default networking setup using Flannel.
{% endwarning %}

{% cpinstall k3d %}
cni.enabled=true
cni.chained=true
cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d
cni.binDir=/bin
cni.confName=10-flannel.conflist
{% endcpinstall %}
{% endtab %}

{% tab installation KinD %}
{% cpinstall kind %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-kindnet.conflist
{% endcpinstall %}
{% endtab %}

{% tab installation AKS %}
Choose the correct `CNI_CONF_NAME` value based on your networking solution:  

{% tabs azure-networking additionalClasses="codeblock" %}
{% tab azure-networking kubenet (default) %}
```sh
export CNI_CONF_NAME="10-azure.conflist"
```
{% endtab %}
{% tab azure-networking Azure CNI Overlay %}
```sh
export CNI_CONF_NAME="15-azure-swift-overlay.conflist"
```
{% endtab %}
{% endtabs %}

Once set, apply the configuration:

{% cpinstall azure %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName={% raw %}$CNI_CONF_NAME{% endraw %}
{% endcpinstall %}
{% endtab %}

{% tab installation EKS %}
{% cpinstall aws-eks %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-aws.conflist
controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_IP_FAMILY_MODE=ipv4
{% endcpinstall %}

{% tip %}
Add `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_IP_FAMILY_MODE=ipv4` as EKS has IPv6 disabled by default.
{% endtip %}
{% endtab %}

{% tab installation GKE %}

You need to [enable network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster (for existing clusters this redeploys the nodes).

Define the Variable `CNI_CONF_NAME` by your CNI, like: `export CNI_CONF_NAME=05-cilium.conflist` or `export CNI_CONF_NAME=10-calico.conflist`
{% cpinstall google-gke %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/home/kubernetes/bin
cni.confName=${CNI_CONF_NAME}
{% endcpinstall %}
{%endtab%}

{% tab installation OpenShift 3.11 %}

1. Follow the instructions in [OpenShift 3.11 installation]({{ docs }}/production/cp-deployment/{% if_version gte:2.6.x inline:true %}single-zone{% endif_version %}{% if_version lte:2.5.x inline:true %}stand-alone{% endif_version %}) to get the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` enabled (this is required for regular {{ Kuma }} installation).

2. You need to grant privileged permission to kuma-cni service account:

   ```shell
   oc adm policy add-scc-to-user privileged -z kuma-cni -n kube-system
   ```

{% cpinstall openshift-3 %}
cni.enabled=true
cni.containerSecurityContext.privileged=true
{% endcpinstall %}
{% endtab %}

{% tab installation OpenShift 4 %}
{% cpinstall openshift-4 %}
cni.enabled=true
cni.containerSecurityContext.privileged=true
{% endcpinstall %}
{% endtab %}

{% endtabs %}

### {{ Kuma }} CNI taint controller

To prevent a race condition described in [this issue](https://github.com/kumahq/kuma/issues/4560) a new controller was implemented. The controller will taint a node with `NoSchedule` taint to prevent scheduling before the CNI DaemonSet is running and ready. Once the CNI DaemonSet is running and ready it will remove the taint and allow other pods to be scheduled into the node.

To disable the taint controller use the following environment variable:

```sh
KUMA_RUNTIME_KUBERNETES_NODE_TAINT_CONTROLLER_ENABLED="false"
```

## Merbridge CNI with eBPF

To install merbridge CNI with eBPF append the following options to the command from [installation](#installation):

{% warning %}
To use Merbridge CNI with eBPF your environment has to use `Kernel >= 5.7` and have `cgroup2` available
{% endwarning %}

```sh
--set ... \
--set "{{site.set_flag_values_prefix}}cni.enabled=true" \
--set "{{site.set_flag_values_prefix}}experimental.ebpf.enabled=true"
```

## {{ Kuma }} CNI logs

Logs of the {{ Kuma }} CNI are available via `kubectl logs`.

{% warning %}
eBPF CNI currently doesn't have support for exposing its logs.
{% endwarning %}
