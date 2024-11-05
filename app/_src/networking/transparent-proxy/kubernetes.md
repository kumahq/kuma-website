---
title: Transparent Proxy on Kubernetes
content_type: how-to
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma-system = site.mesh_namespace %}
{% assign controlPlane = site.set_flag_values_prefix | append: "controlPlane" %}
{% assign transparentProxy = site.set_flag_values_prefix | append: "transparentProxy" %}
{% assign kuma-control-plane = site.mesh_cp_name %}
{% assign kuma-control-plane-config = kuma-control-plane | append: "-config" %}

In Kubernetes mode, transparent proxy is automatically set up through the `kuma-init` container or [Kuma CNI]({{ docs }}/production/dp-config/cni/). By default, it intercepts all incoming and outgoing traffic and routes it through the `kuma-dp` sidecar container, so no changes to the application code are needed.

{{ Kuma }} works smoothly with [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) and provides its own [Kuma DNS]({{ docs }}/networking/dns/), which is especially helpful in multi-zone setups for cross-zone service discovery.

In this mode, {{ Kuma }} requires the transparent proxy to be enabled, so it **cannot be turned off**.

## Configuration

The default configuration works well for most scenarios, but there are cases where adjustments are needed.

In Kubernetes mode, {{ Kuma }} there are three methods to adjust the configuration. Each can be used on its own or combined with others if needed.

{% warning %}
It’s best to stick to one method whenever possible. Using more than one can make things more complicated and harder to troubleshoot, as it may not be clear where each setting comes from. If you need to combine methods, check the [**Order of Precedence** section](#order-of-precedence) to see what the final configuration will look like based on the priority of each setting.
{% endwarning %}

<!-- vale Google.Headings = NO -->
### Control Plane Runtime Configuration
<!-- vale Google.Headings = YES -->

The control plane runtime configuration is a section of {{ Kuma }}'s configuration that contains important settings for how the control plane operates, including options for the transparent proxy and other key components.

Some transparent proxy settings can be adjusted here, and **for certain settings, this is the only place they can be modified**.

Currently, it’s best to use the control plane runtime configuration as the main place to store transparent proxy settings that apply to all [workloads](https://kubernetes.io/docs/concepts/workloads/). In the future, once the [Configuration in ConfigMap](#configuration-in-configmap-experimental) feature is fully supported, we’ll recommend using ConfigMaps for these settings. However, a few restricted settings that are rarely customized will still need to be in the control plane’s runtime configuration.

{% tip %}
For more details, see the [Control Plane Configuration Reference]({{ docs }}/reference/kuma-cp/) under `runtime.kubernetes`. You can also find transparent proxy-specific settings in the [Control Plane Runtime Configuration section]({{ docs }}/reference/transparent-proxy-configuration/#control-plane-runtime-configuration) of the Transparent Proxy Configuration reference.
{% endtip %}

#### Settings restricted to control plane runtime configuration

Some transparent proxy settings **can only be changed through the control plane’s runtime configuration** because they are shared with other {{ Kuma }} components. These settings handle essential tasks like creating [`Dataplane` resources]({{ docs }}/production/dp-config/dpp/) for workloads and setting up the [`kuma-dp` sidecar container]({{ docs }}/production/dp-config/dpp-on-kubernetes/) alongside them. For example, the DNS port used to redirect traffic is shared between the transparent proxy and the `kuma-dp run` command in the sidecar container. Keeping these settings consistent across workloads prevents misconfigurations. These settings are:

- `runtime.kubernetes.injector.sidecarContainer.redirectPortInbound`
- `runtime.kubernetes.injector.sidecarContainer.redirectPortOutbound`
- `runtime.kubernetes.injector.sidecarContainer.uid`
- `runtime.kubernetes.injector.builtinDNS.enabled`
- `runtime.kubernetes.injector.builtinDNS.port`

{% danger %}
⚠️ IMPORTANT
{:.custom-block-title}

If you change these settings, but with values different from the runtime configuration, they will be ignored, and a warning will appear in the control plane logs (except for DNS-related settings).

If `builtinDNS.enabled` or `builtinDNS.port` is updated using deprecated annotations while [Configuration in ConfigMap](#configuration-in-configmap-experimental) is disabled, the changes may still apply, potentially causing DNS redirection issues. This could prevent `kuma-dp` from starting the DNS server or listening on the correct port, leading to environment disruptions.
{% enddanger %}

#### Modifying control plane runtime configuration

For instructions on modifying the control plane configuration, see the [Modifying the Configuration]({{ docs }}/documentation/configuration/#modifying-the-configuration) section in the [Control Plane Configuration]({{ docs }}/documentation/configuration/) documentation.

#### Overriding list-based configuration settings

For list-based settings like `runtime.kubernetes.injector.sidecarTraffic.excludeOutboundPorts`, only the value from the highest-precedence method will be applied; values from other methods will not be combined.

For example, if `excludeOutboundPorts` is set in the control plane runtime configuration but an annotation like `traffic.kuma.io/exclude-outbound-ports` is used on a workload, the annotation will override the control plane setting, so only the ports in the annotation will be excluded.

See the [**Order of Precedence**](#order-of-precedence) section for more details.

<!-- vale Google.Headings = NO -->
### Configuration in ConfigMap (experimental)
<!-- vale Google.Headings = YES -->

{% warning %}
Because this feature impacts multiple underlying components, it is considered experimental. Use it with caution. {% if site.mesh_product_name == "Kuma" %} If you encounter any unexpected behavior or issues, please [**contact us**](/community) and [**submit an issue on GitHub**](https://github.com/kumahq/kuma/issues/new/choose). Your feedback is essential in helping us improve this feature. {% endif %}
{% endwarning %}

Until {{ Kuma }} 2.9, transparent proxy settings could only be modified through the [Control Plane Runtime Configuration](#control-plane-runtime-configuration) and [Annotations](#annotations), which had several limitations:

- Not all settings were available through both methods; some could only be adjusted with annotations, while others were limited to the runtime configuration.
- Control plane runtime settings were applied globally to all workloads with injected data planes, making it hard to customize settings for specific groups of workloads.
- Annotation-based settings had to be added to each workload individually, making it difficult to manage the same configuration across multiple workloads.

To address these issues, {{ Kuma }} now supports storing transparent proxy settings in dedicated ConfigMaps. These ConfigMaps can be applied at the namespace or individual workload level, offering greater flexibility and easier configuration.

To enable this feature, set `{{ transparentProxy }}.configMap.enabled` during installation:

{% cpinstall transparent-proxy-config-configmap-enabling %}
{{ transparentProxy }}.configMap.enabled=true
{% endcpinstall %}

{% warning %}
If you set `{{ transparentProxy }}.configMap.config` to an empty value, it will override `{{ transparentProxy }}.configMap.enabled` and disable the feature, even if `{{ transparentProxy }}.configMap.enabled` is set to `true`.
{% endwarning %}

<!-- vale Google.Headings = NO -->
#### ConfigMap auto-creation and configuration
<!-- vale Google.Headings = YES -->

During installation, {{ Kuma }} will automatically create a ConfigMap in the `{{ kuma-system }}` namespace. The ConfigMap will be named based on the `{{ transparentProxy }}.configMap.name` setting, and its content will come from the YAML configuration defined in `{{ transparentProxy }}.configMap.config`, which holds the transparent proxy settings.

Here is an example of how to modify parts of this configuration during installation:

{% cpinstall transparent-proxy-config-configmap-auto-creation-examples %}
{{ transparentProxy }}.configMap.config.enabled=true
{{ transparentProxy }}.configMap.config.redirect.outbound.excludePortsForIPs=10\.1\.0\.254\,172\.10\.1.254
{{ transparentProxy }}.configMap.config.redirect.verbose=false
{% endcpinstall %}

You can apply the same method of providing these values as explained in the **Store the desired settings in the `{{ kuma-control-plane-config }}` ConfigMap** option in the [**Modifying Control Plane Runtime Configuration**](#modifying-control-plane-runtime-configuration) section.

{% tip %}
For more information about the structure of this configuration, see the [Kuma Control Plane Helm Values]({{ docs }}/reference/kuma-cp/#helm-valuesyaml) documentation, particularly under the `{{ transparentProxy }}.configMap.config` path. You can also refer to the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/) for additional details.
{% endtip %}

<!-- vale Google.Headings = NO -->
#### ConfigMap lookup strategy
<!-- vale Google.Headings = YES -->

{{ Kuma }} follows a specific order when searching for the ConfigMap:

- If the workload is annotated with `traffic.kuma.io/transparent-proxy-configmap-name`, {{ Kuma }} first looks for the resource with the specified name in the workload’s namespace. If not found, it will then check the `{{ kuma-system }}` namespace for the same ConfigMap.

- If the workload is not annotated, or the ConfigMap specified in the annotation is not found, {{ Kuma }} will search for the resource named in the `{{ transparentProxy }}.configMap.name` setting. It first looks in the workload's namespace, and if not found, it checks the `{{ kuma-system }}` namespace.

{% warning %}
The ConfigMap in the `{{ kuma-system }}` namespace is required for proper operation, so it must be present even if custom ones are used in all individual workload namespaces.
{% endwarning %}

<!-- vale Google.Headings = NO -->
#### Custom ConfigMap name
<!-- vale Google.Headings = YES -->

The name of the ConfigMap is defined by the `{{ transparentProxy }}.configMap.name` setting. By default, this name is set to `kuma-transparent-proxy-config`.

To apply a custom name for all workloads, you can modify the `{{ transparentProxy }}.configMap.name` setting during installation:

{% cpinstall transparent-proxy-config-configmap-custom-name-globally %}
{{ transparentProxy }}.configMap.name=custom-name
{% endcpinstall %}

To use a different resource for specific workloads, apply the `traffic.kuma.io/transparent-proxy-configmap-name` annotation to those workloads. For example:

```sh
kubectl annotate pods <pod_name> "traffic.kuma.io/transparent-proxy-configmap-name=custom-name"
```

This allows flexibility, enabling different workloads to use distinct ConfigMap settings while maintaining a global default.

### Annotations

Kubernetes annotations can be applied to individual workloads to modify the transparent proxy configuration. These annotations allow fine-tuning of specific behaviors for a single workload without affecting others.

{% tip %}
Before {{ Kuma }} 2.9, annotations were the only way to modify the transparent proxy configuration on a per-workload basis. In {{ Kuma }} 2.9, the [Configuration in ConfigMap](#configuration-in-configmap-experimental) feature was introduced, offering a more efficient way to configure groups of workloads. When this feature is no longer experimental, it will become the recommended approach for managing transparent proxy settings across multiple workloads. Annotations will still be useful for fine-tuning specific configurations when you need an individual workload to behave differently from the others.
{% endtip %}

Below you can find a list of annotations that can be used to configure specific transparent proxy settings. 

- `traffic.kuma.io/exclude-inbound-ips`

- `traffic.kuma.io/exclude-inbound-ports`

- `traffic.kuma.io/exclude-outbound-ips`

- `traffic.kuma.io/exclude-outbound-ports`

- `traffic.kuma.io/exclude-outbound-ports-for-uids`

- `traffic.kuma.io/drop-invalid-packets`

- `traffic.kuma.io/iptables-logs`

- `kuma.io/transparent-proxying-ebpf`

- `kuma.io/transparent-proxying-ebpf-bpf-fs-path`

- `kuma.io/transparent-proxying-ebpf-cgroup-path`

- `kuma.io/transparent-proxying-ebpf-tc-attach-iface`

- `kuma.io/transparent-proxying-ebpf-instance-ip-env-var-name`

- `kuma.io/transparent-proxying-ebpf-programs-source-path`

- `kuma.io/transparent-proxying-ip-family-mode`

The following annotations also affect the configuration, but their values are automatically managed by {{ Kuma }} and cannot be manually adjusted. Values of these annotations will always match those specified in the [Control Plane Runtime Configuration](#control-plane-runtime-configuration). For more details, refer to [Settings restricted to control plane runtime configuration](#settings-restricted-to-control-plane-runtime-configuration).

- `kuma.io/sidecar-uid`

- `kuma.io/transparent-proxying-inbound-port`

- `kuma.io/transparent-proxying-outbound-port`

{% warning %}
The following two annotations are deprecated and will be removed in future releases. They are provided here for reference only, and we **strongly advise against using them**.

- `kuma.io/builtin-dns`

- `kuma.io/builtin-dns-port`
{% endwarning %}

The following annotation indirectly adjusts the transparent proxy configuration by configuring other components, resulting in changes to the transparent proxy behavior. While its value is automatically set by {{ Kuma }}, you can override it by manually providing a value.

- `kuma.io/application-probe-proxy-port`

  This annotation defines the port (default: `9001`) to be excluded from incoming traffic redirection, similar to using the `traffic.kuma.io/exclude-inbound-ports` annotation or other configuration methods. For more information, refer to the [Kubernetes]({{ docs }}/policies/service-health-probes/#kubernetes) section in the [Service Health Probes]({{ docs }}/policies/service-health-probes/) documentation.

The following annotations differ from others mentioned earlier as they are related to the transparent proxy, but do not directly or indirectly configure specific individual settings.

- `kuma.io/transparent-proxying`

  This annotation is automatically applied to workloads with [injected sidecar containers]({{ docs }}/production/dp-config/dpp-on-kubernetes/#kubernetes-sidecar-containers). In Kubernetes environments, the transparent proxy is mandatory meaning you cannot disable it. Any attempt to explicitly disable it using this annotation will trigger a warning and have no effect. Therefore, the value of this annotation will always be set to `true`.

- `traffic.kuma.io/transparent-proxy-config`

  This annotation is automatically applied in environments using [Kuma CNI]({{ docs }}/production/dp-config/cni/#configure-the-kuma-cni) instead of init containers. It contains the final configuration for installing the transparent proxy. Manually modifying or setting this annotation has no effect, regardless of whether Kuma CNI is used. Its primary purpose is to efficiently pass the transparent proxy configuration between Kubernetes workloads and the Kuma CNI, which handles the actual installation of the transparent proxy for those workloads.

- `traffic.kuma.io/transparent-proxy-configmap-name`

  This annotation lets you specify a custom name for the ConfigMap that holds the transparent proxy configuration when the [Configuration in ConfigMap](#configuration-in-configmap-experimental) feature is enabled. For more details, refer to the [Custom ConfigMap name](#custom-configmap-name) section.

### Automatically applied annotations

Certain annotations are automatically added to workloads with [injected sidecar containers]({{ docs }}/production/dp-config/dpp-on-kubernetes/#kubernetes-sidecar-containers), regardless of whether they are explicitly defined. These annotations reflect the final values used to configure the transparent proxy. For settings that can be manually specified, these annotations will still be applied, even if not explicitly provided, using values from the [Control Plane Runtime Configuration](#control-plane-runtime-configuration).

The automatically applied annotations include:

- `kuma.io/transparent-proxying`
- `kuma.io/sidecar-uid`
- `kuma.io/transparent-proxying-inbound-port`
- `kuma.io/transparent-proxying-outbound-port`
- `kuma.io/builtin-dns`
- `kuma.io/builtin-dns-port`
- `kuma.io/application-probe-proxy-port`
- `kuma.io/transparent-proxying-ebpf`
- `kuma.io/transparent-proxying-ebpf-bpf-fs-path`
- `kuma.io/transparent-proxying-ebpf-cgroup-path`
- `kuma.io/transparent-proxying-ebpf-tc-attach-iface`
- `kuma.io/transparent-proxying-ebpf-instance-ip-env-var-name`
- `kuma.io/transparent-proxying-ebpf-programs-source-path`
- `kuma.io/transparent-proxying-ip-family-mode`
- `traffic.kuma.io/transparent-proxy-config` (only in environments using Kuma CNI)

These annotations ensure that the proper configuration is automatically applied to each workload, aligning with the global and per-workload settings.

<!-- vale Google.Headings = NO -->
### Order of Precedence
<!-- vale Google.Headings = YES -->

When using multiple configuration methods, it's important to understand the order in which they are applied to avoid conflicts and ensure the correct settings are used.

1. [Default values]({{ docs }}/reference/transparent-proxy-configuration/#default-values)

2. [Control Plane Runtime Configuration](#control-plane-runtime-configuration)

3. [Configuration in ConfigMap](#configuration-in-configmap-experimental)

4. [Annotations](#annotations)
