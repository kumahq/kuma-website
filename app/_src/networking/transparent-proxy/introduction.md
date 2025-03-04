---
title: Transparent Proxy Introduction
content_type: explanation
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}

{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}
{% capture Note %}{% if page.edition and page.edition != "kuma" %}**Note:** {% endif %}{% endcapture %}

A transparent proxy is a mechanism that intercepts and redirects network traffic without requiring any changes to the application. It allows traffic to be automatically routed through a proxy without the application being aware of it.

When enabled, all inbound and outbound traffic is transparently routed through the [data plane proxy]({{ docs }}/production/dp-config/dpp/#data-plane-proxy). This allows users to benefit from {{ Kuma }}'s features, such as traffic management, security policies, and observability, without modifying their applications.

{% tip %}
{{ Note }}For details on how the transparent proxy works in {{ Kuma }}, see the [Technical Overview]({{ docs }}/networking/transparent-proxy/technical-overview/).
{% endtip %}

## Kubernetes

In [Kubernetes mode]({{ docs }}/introduction/architecture/#kubernetes-mode), the transparent proxy is automatically set up through the `kuma-init` container or [{{ Kuma }} CNI]({{ docs }}/networking/transparent-proxy/cni/). By default, it intercepts all incoming and outgoing traffic and routes it through the `kuma-dp` sidecar container, so no changes to the application code are needed.

{{ Kuma }} works smoothly with [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) and provides its own [{{ Kuma }} DNS]({{ docs }}/networking/transparent-proxy/dns/), which is especially helpful in multi-zone setups for cross-zone service discovery.

In this mode, {{ Kuma }} requires the transparent proxy to be enabled, so it **cannot be turned off**.

{% tip %}
{{ Note }}For more details on using the transparent proxy with Kubernetes, see [Transparent Proxy on Kubernetes]({{ docs }}/networking/transparent-proxy/kubernetes/).
{% endtip %}

## Universal

Using the transparent proxy in Universal mode makes setup easier and enables features that wouldn’t be possible otherwise. Key benefits include:

- **Simplified `Dataplane` resources**: You can skip the `networking.outbound` section, so you don’t have to list each service your application connects to manually.

- **Simplified service connectivity**: Take advantage of [{{ Kuma }} DNS]({{ docs }}/networking/transparent-proxy/dns/), for easy service connections without needing `localhost` and ports in the `Dataplane` resource.

{% tip %}
{{ Note }}For more details on using the transparent proxy with Universal, see [Transparent Proxy on Universal]({{ docs }}/networking/transparent-proxy/universal/).
{% endtip %}

### Transparent proxy with eBPF (experimental)

Starting from {{ Kuma }} 2.0 you can set up transparent proxy to use eBPF instead of iptables.

{% warning %}
{{ Important }}To use the transparent proxy with eBPF your environment has to use `Kernel >= 5.7` and have `cgroup2` available
{% endwarning %}

{% tabs ebpf useUrlFragment=false additionalClasses="codeblock" %}
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
{{ Note }}If your environment contains more than one non-loopback network interface, and you want to specify explicitly which one should be used for transparent proxying you should provide it using `--ebpf-tc-attach-iface <IFACE_NAME>` flag, during transparent proxy installation.
{% endtip %}
{% endtab %}
{% endtabs %}
