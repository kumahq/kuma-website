---
title: Excluding Traffic from Transparent Proxy Redirection
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

This guide will show you how to exclude specific types of traffic from being redirected by the transparent proxy. It includes instructions for both **Universal** and a **Kubernetes** modes and covers different types of traffic you might want to exclude, such as:

- [Exclude traffic on certain ports (incoming & outgoing)](#exclude-traffic-on-certain-ports)
- [Exclude traffic to and from specific IP addresses](#exclude-traffic-to-and-from-specific-ip-addresses)

Use this guide to control which traffic the transparent proxy intercepts and which it allows through directly.

## Terminology overview

- **Workload**: In this guide, **workload** refers to an application running in a Kubernetes cluster, usually represented by a [**Pod**](https://kubernetes.io/docs/concepts/workloads/pods/). Kubernetes resources like [**Deployment**](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [**ReplicaSet**](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/), and [**StatefulSet**](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) are used to define and manage these workloads, resulting in one or more **Pods** where the application actually runs.

- **ConfigMap**: In this guide, **ConfigMap** refers to the Kubernetes [**ConfigMap**](https://kubernetes.io/docs/concepts/configuration/configmap/) resource. It’s used to store configuration data as key-value pairs that can be easily accessed by other resources in the cluster, such as Pods, Deployments, and StatefulSets.

- **Service**: In this guide, **service** means the application running in a Universal mode environment where the transparent proxy will be installed. This term does not refer to Kubernetes [**Service**](https://kubernetes.io/docs/concepts/services-networking/service/) resources.

## Prerequisites

1. **Familiarity with transparent proxy:** You should already understand what a transparent proxy is, how to install it, and how to configure its settings. Use the following resources if needed:

   - **Installation on Universal:** Follow the [Deploy Kuma on Docker quick start guide]({{ docs }}/quickstart/docker-demo/) for setup instructions.
   - **Customizing settings:** See [Configuration on Kubernetes]({{ docs }}/networking/transparent-proxy/kubernetes/#configuration), [Configuration on Universal]({{ docs }}/networking/transparent-proxy/universal/#configuration), and the [Configuration Reference]({{ docs }}/networking/transparent-proxy/configuration-reference/).
   - **How it works:** For a deep dive into {{ Kuma }}'s transparent proxy mechanisms, see the [Technical Overview]({{ docs }}/networking/transparent-proxy/technical-overview/).
   - **Upgrades:** See the [Upgrading Transparent Proxy guide]({{ docs }}/guides/upgrading-transparent-proxy/) for upgrade steps.

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

   - To set up your service environment and start the data plane proxy, follow the steps in the quickstart guide.
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

You can add these annotations manually in your Kubernetes manifests or by using below command:

```sh
kubectl annotate pods example-app \
  "traffic.kuma.io/exclude-inbound-ports=1234" \
  "traffic.kuma.io/exclude-outbound-ports=5678,8900"
```
{% endtab %}

{% tab excluding-incoming-traffic-to-specific-ports Universal %}
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

You can add these annotations manually in your Kubernetes manifests or by using below command:

```sh
kubectl annotate pods example-app \
  "traffic.kuma.io/exclude-inbound-ips=10.0.0.0/8" \
  "traffic.kuma.io/exclude-outbound-ips=192.168.10.1,fd10::/16"
```
{% endtab %}
{% tab exclude-traffic-to-and-from-specific-ip-addresses Universal %}
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
{% endtab %}
{% endtabs %}
