---
title: Transparent Proxy
content_type: how-to
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% capture tproxy-config-reference-info %}
For a full list of transparent proxy settings with examples and configuration options, see the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).
{% endcapture %}

A transparent proxy is a server that intercepts network traffic going to and from a service without requiring any changes to the application code. In {{ Kuma }}, it captures this traffic and routes it to the [data plane proxy]({{ docs }}/production/dp-config/dpp/#data-plane-proxy), allowing [Mesh policies]({{ docs }}/policies/introduction/#policies) to be applied.

{{ Kuma }} uses [iptables](https://linux.die.net/man/8/iptables) and also has experimental support for [eBPF](#transparent-proxy-with-ebpf-experimental) to make this possible.

{% tip %}
For details on how the transparent proxy works in {{ Kuma }}, see the [Technical Overview]({{ docs }}/networking/transparent-proxy/technical-overview/).
{% endtip %}

## Kubernetes

In [Kubernetes mode]({{ docs }}/introduction/architecture/#kubernetes-mode), the transparent proxy is automatically set up through the `kuma-init` container or [Kuma CNI]({{ docs }}/production/dp-config/cni/). By default, it intercepts all incoming and outgoing traffic and routes it through the `kuma-dp` sidecar container, so no changes to the application code are needed.

{{ Kuma }} works smoothly with [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) and provides its own [Kuma DNS]({{ docs }}/networking/dns/), which is especially helpful in multi-zone setups for cross-zone service discovery.

In this mode, {{ Kuma }} requires the transparent proxy to be enabled, so it **cannot be turned off**.

### Configuration
{:#kubernetes-configuration}

If the default settings don’t fit your needs, see [Adjusting Transparent Proxy Configuration on Kubernetes]({{ docs }}/networking/transparent-proxy/configuration-on-kubernetes/) for ways to change settings and their recommended uses.

{{ tproxy-config-reference-info }}

## Universal

Using the transparent proxy in [Universal mode]({{ docs }}/introduction/architecture/#universal-mode) makes setup easier and enables features that wouldn’t be possible otherwise. Key benefits include:

- **Simplified `Dataplane` resources**: You can skip the `networking.outbound` section, so you don’t have to list each service your application connects to manually. Here’s an example without outbound entries:

  ```yaml
  type: Dataplane
  name: {% raw %}{{ name }}{% endraw %}
  networking:
    address: {% raw %}{{ address }}{% endraw %}
    inbound:
    - port: {% raw %}{{ port }}{% endraw %}
      tags:
        kuma.io/service: demo-client 
    transparentProxying:
      redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
      redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
  ```

- **Easier service naming**: Use the `.mesh` [DNS domain]({{ docs }}/networking/dns/) to connect to services, like `https://service-1.mesh`, without needing `localhost` and ports from the `Dataplane` resource.

- **Flexible service naming with [VirtualOutbound]({{ docs }}/policies/virtual-outbound) policy**: It lets you:

  - Keep existing DNS names when moving to the service mesh.
  - Assign multiple DNS names to a service for renaming or convenience.
  - Create specific routes, like targeting individual StatefulSet Pods or service versions.
  - Expose multiple inbounds for a service on different ports.

- **Simpler security, tracing, and observability**: Transparent proxy makes managing these features easier, with no extra setup required.

### Installation
{:#universal-installation}

To learn how to integrate the transparent proxy with your existing services or set up a service environment from scratch, see [Installing Transparent Proxy on Universal]({{ docs }}/networking/transparent-proxy/installing-on-universal/).

### Configuration
{:#universal-configuration}

If the default settings don’t fit your needs, see [Adjusting Transparent Proxy Configuration on Universal]({{ docs }}/networking/transparent-proxy/configuration-on-universal/) for ways to modify settings and their recommended uses.

{{ tproxy-config-reference-info }}

### firewalld support

{% tip %}
In **Kubernetes** mode, transparent proxy is automatically set up using the `kuma-init` container or [Kuma CNI]({{ docs }}/production/dp-config/cni/). Since the proxy is reinstalled each time your workload restarts, there is no need to persist it. This feature is specifically designed for **Universal** environments.
{% endtip %}

The changes made by running `kumactl install transparent-proxy` **will not persist** after a reboot. To ensure persistence, you can either add this command to your system's start-up scripts or leverage `firewalld` for managing `iptables`.

If you prefer using `firewalld`, you can include the `--store-firewalld` flag when installing the transparent proxy. This will store the `iptables` rules in `/etc/firewalld/direct.xml`, ensuring they persist across system reboots. Here's an example:

```sh
kumactl install transparent-proxy --redirect-dns --store-firewalld
```

{% warning %}
**Important:** Currently, there is no uninstall command for this feature. If needed, you will have to manually clean up the `firewalld` configuration.
{% endwarning %}

<!-- vale Google.Headings = NO -->
### Transparent proxy with eBPF (experimental)
<!-- vale Google.Headings = YES -->

Starting from {{ Kuma }} 2.0 you can set up transparent proxy to use eBPF instead of iptables.

{% warning %}
To use the transparent proxy with eBPF your environment has to use `Kernel >= 5.7` and have `cgroup2` available
{% endwarning %}

{% tabs ebpf useUrlFragment=false %}
{% tab ebpf Kubernetes %}
```sh
kumactl install control-plane \
  --set "{{ site.set_flag_values_prefix }}experimental.ebpf.enabled=true" \
  | kubectl apply -f-
```
{% endtab %}

{% tab ebpf Universal %}
```sh
kumactl install transparent-proxy \
  --ebpf-enabled \
  --ebpf-instance-ip <IP_ADDRESS> \
  --ebpf-programs-source-path <PATH>
```

{% tip %}
If your environment contains more than one non-loopback network interface, and you want to specify explicitly which one should be used for transparent proxying you should provide it using `--ebpf-tc-attach-iface <IFACE_NAME>` flag, during transparent proxy installation.
{% endtip %}
{% endtab %}
{% endtabs %}
