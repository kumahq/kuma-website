---
title: Transparent Proxy
content_type: how-to
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% capture tproxy-config-reference-info %}
For a complete list of transparent proxy settings, including examples and allowed configuration methods for each field, see the [Transparent Proxy Configuration Reference]({{ docs }}{{ tproxy.paths.reference.configs.tproxy }}#transparent-proxy-configuration).
{% endcapture %}

A transparent proxy is a server that intercepts network traffic going to and from a service without requiring any changes to the application code. In {{ Kuma }}, it captures this traffic and routes it to the [data plane proxy]({{ docs }}/production/dp-config/dpp/#data-plane-proxy), allowing [Mesh policies]({{ docs }}/policies/introduction/#policies) to be applied.

{{ Kuma }} uses [iptables](https://linux.die.net/man/8/iptables){% if_version gte:2.0.x inline: true%} and also has experimental support for [`eBPF`](#transparent-proxy-with-ebpf-experimental){% endif_version %} to make this possible.

{% tip %}
For a closer look at how the transparent proxy works in {{ Kuma }}, visit the [Transparent Proxying]({{ docs }}/networking/transparent-proxying/#transparent-proxying) page in our Service Discovery & Networking documentation.
{% endtip %}

## Kubernetes Mode

In [Kubernetes mode]({{ docs }}/introduction/architecture/#kubernetes-mode), the transparent proxy is automatically set up through the `kuma-init` container or [Kuma CNI]({{ docs }}/production/dp-config/cni/#configure-the-kuma-cni). By default, it intercepts all incoming and outgoing traffic and routes it through the `kuma-dp` sidecar container, so no changes to the application code are needed.

{{ Kuma }} works smoothly with [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) and provides its own [Kuma DNS]({{ docs }}/networking/dns/#dns), which is especially helpful in multi-zone setups for cross-zone service discovery.

In this mode, {{ Kuma }} requires the transparent proxy to be enabled, so it **cannot be turned off**.

### Adjusting Transparent Proxy Settings in Kubernetes Mode

If the default settings don’t meet your needs, see the [Customizing Transparent Proxy Configuration in Kubernetes Mode]({{ docs }}{{ tproxy.paths.guides.customize-config.k8s }}#customizing-transparent-proxy-configuration-in-kubernetes-mode) guide. This guide explains different ways to change settings and when to use each one.

{% if_version gte:2.9.x %}
{{ tproxy-config-reference-info }}
{% endif_version %}

## Universal Mode

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

- **Easier service naming**: Use the `.mesh` [DNS domain]({{ docs }}/networking/dns/#dns) to connect to services, like `https://service-1.mesh`, without needing `localhost` and ports from the `Dataplane` resource.

- **Flexible service naming with [VirtualOutbound]({{ docs }}/policies/virtual-outbound) policy**: It lets you:

  - Keep existing DNS names when moving to the service mesh.
  - Assign multiple DNS names to a service for renaming or convenience.
  - Create specific routes, like targeting individual StatefulSet Pods or service versions.
  - Expose multiple inbounds for a service on different ports.

- **Simpler security, tracing, and observability**: Transparent proxy makes managing these features easier, with no extra setup required.

### Installing Transparent Proxy in Universal Mode

To learn how to integrate the Transparent Proxy with your existing services or to set up a service environment from scratch, follow the [Integrating Transparent Proxy into Your Service Environment]({{ docs }}/guides/integrating-transparent-proxy-into-your-service-environment/#integrating-transparent-proxy-into-your-service-environment) guide. This guide provides step-by-step instructions for both scenarios.

{% if_version gte:2.9.x %}
### Adjusting Transparent Proxy Settings In Universal Mode

If the default settings don’t meet your needs, see the [Customizing Transparent Proxy Configuration in Universal Mode]({{ docs }}{{ tproxy.paths.guides.customize-config.uni }}#customizing-transparent-proxy-configuration-in-universal-mode) guide. This guide explains different ways to change settings and when to use each one.

{{ tproxy-config-reference-info }}
{% endif_version %}

## Reachable Services

When the transparent proxy is enabled, {{ Kuma }} automatically configures each data plane proxy to connect with every other data plane proxy in the same mesh. This setup ensures broad service-to-service communication but can create issues in large service meshes:

- **Increased Memory Usage**: The configuration for each data plane proxy can consume significant memory as the mesh grows.
- **Slower Propagation**: Even small configuration changes for one service must be propagated to all data planes, which can be slow and resource-intensive.
- **Excessive Traffic**: Frequent updates generate additional traffic between the control plane and data plane proxies, especially when services are added or changed often.

In real-world scenarios, services usually need to communicate only with a few other services rather than all services in the mesh. To address these challenges, {{ Kuma }} offers the **Reachable Services** feature, allowing you to define only the services that each proxy should connect to. Specifying reachable services helps reduce memory usage, improves configuration propagation speed, and minimizes unnecessary traffic.

Here’s how to configure reachable services:

{% tabs reachable-services useUrlFragment=false %}
{% tab reachable-services Kubernetes %}
Specify the list of reachable services in the `kuma.io/transparent-proxying-reachable-services` annotation, separating each service with a comma. Your workload configuration could look like this:

```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-client
  annotations:
    kuma.io/transparent-proxying-reachable-services: "redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
...
```

You can update your workload manifests manually or use a command like:

```sh
kumactl annotate pods example-app \
  "kuma.io/transparent-proxying-reachable-services=redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
```
{% endtab %}
{% tab reachable-services Universal %}
To specify reachable services in your `Dataplane` resource, add them under the `networking.transparentProxying.reachableServices` path. Here’s an example:

```yaml
type: Dataplane
mesh: default
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
    reachableServices:
      - redis_kuma-demo_svc_6379
      - elastic_kuma-demo_svc_9200 
```
{% endtab %}
{% endtabs %}

This configuration ensures that `example-app` only connects to `redis_kuma-demo_svc_6379` and `elastic_kuma-demo_svc_9200`, reducing the overhead associated with managing connections to all services in the mesh.

{% if_version gte:2.9.x %}
## Reachable Backends

{% warning %}
This feature works only when [MeshService]({{ docs }}/networking/meshservice) is enabled.
{% endwarning %}

Reachable Backends provides similar functionality to [Reachable Services](#reachable-services), but it applies to resources such as [MeshService]({{ docs }}/networking/meshservice), [MeshExternalService]({{ docs }}/networking/meshexternalservice), and [MeshMultiZoneService]({{ docs }}/networking/meshmultizoneservice).

By default, each data plane proxy tracks all other data planes in the mesh, which can impact performance and use more resources. Configuring `reachableBackends` allows you to specify only the services your application actually needs to communicate with, improving efficiency.

Unlike Reachable Services, Reachable Backends uses a structured model to define the resources.

### Model

- **refs**: Lists the resources your application needs to connect with, including:
  - **kind**: Type of resource. Options include:
    - **MeshService**
    - **MeshExternalService**
    - **MeshMultiZoneService**
  - **name**: Name of the resource.
  - **namespace**: (Kubernetes only) Namespace where the resource is located. Required if using `namespace`.
  - **labels**: A list of labels to match resources. You can define either `labels` or `name`.
  - **port**: (Optional) Port for the service, used with `MeshService` and `MeshMultiZoneService`.

{% tabs reachable-backends-model useUrlFragment=false %}
{% tab reachable-backends-model Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-client
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        name: redis
        namespace: kuma-demo
        port: 8080
      - kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: test-server
      - kind: MeshExternalService
        name: mes-http
        namespace: kuma-system
...
```
{% endtab %}
{% tab reachable-backends-model Universal %}
```yaml
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
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
      - kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: test-server
      - kind: MeshExternalService
        name: mes-http
```
{% endtab %}
{% endtabs %}

### Examples

#### `demo-client` communicates only with `redis` on port 6379

{% tabs reachable-backends useUrlFragment=false %}
{% tab reachable-backends Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-client
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        name: redis
        namespace: kuma-demo
        port: 6379
...
```
{% endtab %}
{% tab reachable-backends Universal %}
```yaml
type: Dataplane
mesh: default
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
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
        port: 6379
```
{% endtab %}
{% endtabs %}

#### `demo-client` doesn’t need to communicate with any service

{% tabs reachable-backends-no-services useUrlFragment=false %}
{% tab reachable-backends-no-services Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-client
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: ""
...
```
{% endtab %}
{% tab reachable-backends-no-services Universal %}
```yaml
type: Dataplane
mesh: default
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
    reachableBackends: {}
```
{% endtab %}
{% endtabs %}

#### `demo-app` communicates with all MeshServices in the `kuma-demo` namespace

{% tabs reachable-backends-in-namespace useUrlFragment=false %}
{% tab reachable-backends-in-namespace Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        labels:
          k8s.kuma.io/namespace: kuma-demo
...
```
{% endtab %}
{% endtabs %}
{% endif_version %}

### firewalld Support

{% tip %}
In **Kubernetes** mode, transparent proxy is automatically set up using the `kuma-init` container or [Kuma CNI]({{ docs }}/production/dp-config/cni/#configure-the-kuma-cni). Since the proxy is reinstalled each time your workload restarts, there is no need to persist it. This feature is specifically designed for **Universal** environments.
{% endtip %}

The changes made by running `kumactl install transparent-proxy` **will not persist** after a reboot. To ensure persistence, you can either add this command to your system's start-up scripts or leverage `firewalld` for managing `iptables`.

If you prefer using `firewalld`, you can include the `--store-firewalld` flag when installing the transparent proxy. This will store the `iptables` rules in `/etc/firewalld/direct.xml`, ensuring they persist across system reboots. Here's an example:

```sh
kumactl install transparent-proxy --redirect-dns --store-firewalld
```

{% warning %}
**Important:** Currently, there is no uninstall command for this feature. If needed, you will have to manually clean up the `firewalld` configuration.
{% endwarning %}

{% if_version gte:2.0.x %}
### Transparent Proxy with eBPF (experimental)

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
{% endif_version %}