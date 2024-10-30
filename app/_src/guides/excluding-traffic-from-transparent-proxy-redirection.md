---
title: Excluding Traffic from Transparent Proxy
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% capture path-reference-tproxy-title %}{{ docs }}{{ tproxy.paths.reference.configs.tproxy }}#{{ tproxy.ids.reference.configs.tproxy.title }}{% endcapture %}
{% capture path-customize-k8s-title %}{{ docs }}{{ tproxy.paths.guides.customize-config.k8s }}#{{ tproxy.ids.guides.customize-config.k8s.title }}{% endcapture %}
{% capture path-customize-uni-title %}{{ docs }}{{ tproxy.paths.guides.customize-config.uni }}#{{ tproxy.ids.guides.customize-config.uni.title }}{% endcapture %}
{% capture path-method-k8s-configmap %}{{ docs }}{{ tproxy.paths.guides.customize-config.k8s }}#{{ tproxy.ids.guides.customize-config.k8s.methods.configmap }}{% endcapture %}
{% capture path-method-k8s-runtime %}{{ docs }}{{ tproxy.paths.guides.customize-config.k8s }}#{{ tproxy.ids.guides.customize-config.k8s.methods.runtime }}{% endcapture %}
{% capture path-method-k8s-annotations %}{{ docs }}{{ tproxy.paths.guides.customize-config.k8s }}#{{ tproxy.ids.guides.customize-config.k8s.methods.annotations }}{% endcapture %}
{% capture path-method-uni-env %}{{ docs }}{{ tproxy.paths.guides.customize-config.uni }}#{{ tproxy.ids.guides.customize-config.uni.methods.env }}{% endcapture %}
{% capture path-method-uni-cli %}{{ docs }}{{ tproxy.paths.guides.customize-config.uni }}#{{ tproxy.ids.guides.customize-config.uni.methods.cli }}{% endcapture %}
{% capture path-integrating-tproxy-title %}{{ docs }}{{ tproxy.paths.guides.integrate-tproxy }}#{{ tproxy.ids.guides.integrate-tproxy.title }}{% endcapture %}
{% capture path-step-install-tproxy %}{{ docs }}{{ tproxy.paths.guides.integrate-tproxy }}#{{ tproxy.ids.guides.integrate-tproxy.steps.install-tproxy }}{% endcapture %}

{% assign configuration-in-configmap = "Configuration in ConfigMap <sup>(experimental)</sup>" %}

This guide will show you how to exclude specific types of traffic from being redirected by the transparent proxy. It includes instructions for both **Universal** and **Kubernetes** modes and covers different types of traffic you might want to exclude, such as:

- [Exclude traffic on certain ports (incoming & outgoing)](#exclude-traffic-on-certain-ports)
- [Exclude traffic to and from specific IP addresses](#exclude-traffic-to-and-from-specific-ip-addresses)

Use this guide to control which traffic the transparent proxy intercepts and which it allows through directly.

## Key information

- This guide shows how to set up the transparent proxy to exclude certain types of traffic from redirection for selected workloads. We’ll cover some methods for both Kubernetes and Universal modes, but **not all possible scenarios are explained in detail**. For more information on options briefly mentioned here, check out:

  - [Customizing Transparent Proxy Configuration in Kubernetes Mode]({{ path-customize-k8s-title }})
{% if_version gte:2.9.x %}
  - [Customizing Transparent Proxy Configuration in Universal Mode]({{ path-customize-uni-title }})
  - [Transparent Proxy Configuration Reference]({{ path-reference-tproxy-title }})
{% endif_version %}

{% if_version gte:2.9.x -%}
- Right now, the recommended way to adjust transparent proxy settings (and the one mostly shown in this guide) is with [Kubernetes Annotations]({{ path-method-k8s-annotations }}), since the [{{ configuration-in-configmap }}]({{ path-method-k8s-configmap }}) option is still experimental. Once it’s stable, it will become the suggested method.
{%- endif_version %}

## Terminology overview

- **Workload**: In this guide, **workload** refers to an application running in a Kubernetes cluster, usually represented by a [**Pod**](https://kubernetes.io/docs/concepts/workloads/pods/). Kubernetes resources like [**Deployment**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [**ReplicaSet**](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/), and [**StatefulSet**](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) are used to define and manage these workloads, resulting in one or more **Pods** where the application actually runs.

- **ConfigMap**: In this guide, **ConfigMap** refers to the Kubernetes [**ConfigMap**](https://kubernetes.io/docs/concepts/configuration/configmap/) resource. It’s used to store configuration data as key-value pairs that can be easily accessed by other resources in the cluster, such as Pods, Deployments, and StatefulSets.

- **Service**: In this guide, **service** means the application running in a Universal mode environment where the transparent proxy will be installed. This term does not refer to Kubernetes [**Service**](https://kubernetes.io/docs/concepts/services-networking/service/) resources.

## Prerequisites

1. **Understand transparent proxy basics**: You should already be familiar with what a transparent proxy is, how to install it, and how to adjust its settings. This guide won’t cover those basics. The following resources can help:

   - For options to customize transparent proxy settings, check the resources listed in the [Key Information](#key-information) section.
<!-- vale Vale.Terms = NO -->
   - For an in-depth look at how the transparent proxy works in {{ Kuma }} and its mechanisms, see the [Transparent Proxying]({{ docs }}/networking/transparent-proxying/) documentation.
<!-- vale Vale.Terms = YES -->
   - To install the transparent proxy in Universal mode, refer to [Integrating Transparent Proxy into Your Service Environment]({{ path-integrating-tproxy-title }}).
   - For upgrade steps, see [Upgrading Transparent Proxy]({{ docs }}/guides/upgrading-transparent-proxy).

2. **Set up {{ Kuma }}**: Ensure {{ Kuma }} is installed and running.

   {% capture prerequisites-setup-kuma %}
   {% tabs prerequisites-setup-kuma %}
   {% tab prerequisites-setup-kuma Kubernetes %}
   Follow the [Kubernetes Quickstart]({{ docs }}/quickstart/kubernetes-demo/) guide to set up a zone control plane and demo application.
   {% endtab %}
   {% tab prerequisites-setup-kuma Universal %}
   Confirm that all necessary components are up and running. The following resources may be useful:

  - To set up a single-zone control plane, follow the [Single Zone Control Plane Deployment]({{ docs }}/production/cp-deployment/single-zone/) guide.

  - To generate a data plane proxy token (needed to authorize data plane proxies), refer to [Data Plane Proxy Token]({{ docs }}/production/secure-deployment/dp-auth/#data-plane-proxy-token) documentation.

  - To prepare your service environment and start the data plane proxy, follow the [Integrating Transparent Proxy into Your Service Environment]({{ path-integrating-tproxy-title }}) guide up to [Step {% inc install-tproxy if_version="lte:2.4.x" init_value=5 %}: Install the Transparent Proxy]({{ path-step-install-tproxy }}).
    {% endtab %}
    {% endtabs %}
    {% endcapture %}
    {{ prerequisites-setup-kuma | indent }}

## Exclude traffic on certain ports

This example shows how to exclude incoming traffic on port `1234` and outgoing traffic on ports `5678` and `8900`.

{% tabs excluding-incoming-traffic-to-specific-ports useUrlFragment=false %}
{% tab excluding-incoming-traffic-to-specific-ports Kubernetes %}
To exclude these ports in Kubernetes mode, add the `traffic.kuma.io/exclude-inbound-ports` annotation for incoming traffic and `traffic.kuma.io/exclude-outbound-ports` for outgoing traffic. For example, your Pod configuration could look like this:

```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: example-app
  annotations:
    traffic.kuma.io/exclude-inbound-ports: "1234"
    traffic.kuma.io/exclude-outbound-ports: "5678,8900"
...
```

You can add these annotations manually in your Kubernetes manifests or by using this command:

```sh
kubectl annotate pods example-app \
  "traffic.kuma.io/exclude-inbound-ports=1234" \
  "traffic.kuma.io/exclude-outbound-ports=5678,8900"
```

{% include snippets/tproxy/guide-excluding-traffic-other-options-k8s.html.liquid data=tproxy.data.guides.exclude-traffic.excludePorts %}
{% endtab %}

{% tab excluding-incoming-traffic-to-specific-ports Universal %}
{% if_version gte:2.9.x %}
To exclude specific ports in Universal mode, configure the transparent proxy with `redirect.inbound.excludePorts` and `redirect.outbound.excludePorts` settings. Here’s an example:

```sh
echo "
redirect:
  inbound:
    excludePorts: [1234]
  outbound:
    excludePorts: [5678, 8900]
" | kumactl install transparent-proxy --config-file -
```

### Other configuration options
{:.no-anchor#excluding-incoming-traffic-to-specific-ports-universal-other-options}

[**Environment Variables**]({{ path-method-uni-env }})

```sh
KUMA_TRANSPARENT_PROXY_REDIRECT_INBOUND_EXCLUDE_PORTS="1234" \
KUMA_TRANSPARENT_PROXY_REDIRECT_OUTBOUND_EXCLUDE_PORTS="5678,8900" \
kumactl install transparent-proxy
```

[**CLI Flags**]({{ path-method-uni-cli }})

```sh
kumactl install transparent-proxy \
  --exclude-inbound-ports "1234" \
  --exclude-outbound-ports "5678,8900"
````
{% endif_version %}

{% if_version lte:2.8.x %}
To exclude specific ports in Universal mode, use the `--exclude-inbound-ports` and `--exclude-outbound-ports` flags:

```sh
kumactl install transparent-proxy \
  --exclude-inbound-ports "1234" \
  --exclude-outbound-ports "5678,8900"
```
{% endif_version %}
{% endtab %}
{% endtabs %}

## Exclude traffic to and from specific IP addresses

This example shows how to exclude incoming traffic coming from addresses in range `10.0.0.0/8` and outgoing traffic directed to address `192.168.10.1` or addresses in range `fd10::/16`.

{% tabs exclude-traffic-to-and-from-specific-ip-addresses useUrlFragment=false %}
{% tab exclude-traffic-to-and-from-specific-ip-addresses Kubernetes %}
To exclude these addresses in Kubernetes mode, add the `traffic.kuma.io/exclude-inbound-ips` annotation for incoming traffic and `traffic.kuma.io/exclude-outbound-ips` for outgoing traffic. For example, your Pod configuration could look like this:

```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: example-app
  annotations:
    traffic.kuma.io/exclude-inbound-ips: "10.0.0.0/8"
    traffic.kuma.io/exclude-outbound-ips: "192.168.10.1,fd10::/16"
...
```

You can add these annotations manually in your Kubernetes manifests or by using this command:

```sh
kubectl annotate pods example-app \
  "traffic.kuma.io/exclude-inbound-ips=10.0.0.0/8" \
  "traffic.kuma.io/exclude-outbound-ips=192.168.10.1,fd10::/16"
```

{% include snippets/tproxy/guide-excluding-traffic-other-options-k8s.html.liquid data=tproxy.data.guides.exclude-traffic.excludeIPs %}
{% endtab %}
{% tab exclude-traffic-to-and-from-specific-ip-addresses Universal %}
{% if_version gte:2.9.x %}
To exclude these addresses in Universal mode, configure the transparent proxy with `redirect.inbound.excludePortsForIPs` and `redirect.outbound.excludePortsForIPs` settings. Here’s an example:

```sh
echo "
redirect:
  inbound:
    excludePortsForIPs: [10.0.0.0/8]
  outbound:
    excludePortsForIPs: [192.168.10.1, fd10::/16]
" | kumactl install transparent-proxy --config-file -
```

### Other configuration options
{:.no-anchor#exclude-traffic-to-and-from-specific-ip-addresses-universal-other-options}

[**Environment Variables**]({{ path-method-uni-env }})

```sh
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS="10.0.0.0/8" \
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS="192.168.10.1,fd10::/16" \
kumactl install transparent-proxy
```

[**CLI Flags**]({{ path-method-uni-cli }})

```sh
kumactl install transparent-proxy \
  --exclude-inbound-ips "10.0.0.0/8" \
  --exclude-outbound-ips "192.168.10.1,fd10::/16"
````
{% endif_version %}

{% if_version lte:2.8.x %}
To exclude these addresses in Universal mode, use the `--exclude-inbound-ips` and `--exclude-outbound-ips` flags:

```sh
kumactl install transparent-proxy \
  --exclude-inbound-ips "10.0.0.0/8" \
  --exclude-outbound-ips "192.168.10.1,fd10::/16"
```
{% endif_version %}
{% endtab %}
{% endtabs %}
