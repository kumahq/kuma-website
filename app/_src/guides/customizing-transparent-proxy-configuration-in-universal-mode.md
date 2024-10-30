---
title: Customizing Transparent Proxy Configuration in Universal Mode
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}

{% assign tproxy = site.data.tproxy %}

{% assign ref = docs | append: tproxy.paths.reference.configs.tproxy %}
{% assign ref-section = ref | append: "#" %}
{% assign ref-section-schema = ref-section | append: tproxy.ids.reference.configs.tproxy.schema %}
{% assign ref-section-env = ref-section | append: tproxy.ids.reference.configs.tproxy.env %}
{% assign ref-section-cli = ref-section | append: tproxy.ids.reference.configs.tproxy.cli %}
{% assign ref-section-default = ref-section | append: tproxy.ids.reference.configs.tproxy.default %}
{% assign ref-section-full = ref-section | append: tproxy.ids.reference.configs.tproxy.full %}

The default transparent proxy configuration works well for most scenarios, but there are cases where adjustments are needed. This guide explains the various methods available for modifying the configuration, along with their limitations and recommendations on when to use each one.

## Configuration reference

{{ Kuma }} uses a unified configuration structure for transparent proxy across all components. For a detailed breakdown of this structure, including examples, expected formats, and variations between configuration methods, refer to the [Full Reference]({{ ref-section-full }}) section in the [Transparent Proxy Configuration Reference]({{ ref }}).

If you're only interested in specific parts of the reference, here are links to simplified sections:

| Section                                                 | Description                                                                             |
|:--------------------------------------------------------|:----------------------------------------------------------------------------------------|
| [**Schema**]({{ ref-section-schema }})                  | A concise version of the configuration schema, including default values.                |
| [**Environment&nbsp;Variables**]({{ ref-section-env }}) | A configuration structure showing fields and their corresponding environment variables. |
| [**CLI&nbsp;Flags**]({{ ref-section-cli }})             | A configuration structure showing fields and their corresponding CLI flags.             |
| [**Default&nbsp;Values**]({{ ref-section-default }})    | A structure displaying only the fields with their default values.                       |

## Methods of customizing the configuration

In Universal environments, {{ Kuma }} provides three ways to adjust the transparent proxy configuration. Each method can be used on its own or combined with others if needed.

{% warning %}
It’s best to stick to one method whenever possible. Using more than one can make things more complicated and harder to troubleshoot, as it may not be clear where each setting comes from. If you need to combine methods, check the [**Order of Precedence**](#order-of-precedence) to see what the final configuration will look like based on the priority of each setting.
{% endwarning %}

Here are the methods, listed by precedence, from lowest to highest. 

<!-- vale Google.Headings = NO -->
### Method 1: YAML or JSON configuration
{:#{{ tproxy.ids.guides.customize-config.uni.methods.yaml-json }}}
<!-- vale Google.Headings = YES -->

You can provide the configuration in either `YAML` or `JSON` format by using the `--config` or `--config-file` flags.

{% tip %}
For the configuration schema in YAML format, refer to the [Schema]({{ ref-section-schema }}) section in the [Transparent Proxy Configuration Reference]({{ ref }}).
{% endtip %}

{% tip %}
For simplicity, the following examples use YAML format, but you can easily convert them to JSON if preferred. Both formats work exactly the same, so feel free to choose the one that best suits your needs.
{% endtip %}

Below are examples of using these flags in different ways:

1. **Providing configuration via the `--config-file` flag**

   Assume you have a `config.yaml` file with the following content:

   ```yaml
   kumaDPUser: dataplane
   verbose: true
   ```

   You can install the transparent proxy using:

   ```sh
   kumactl install transparent-proxy --config-file config.yaml
   ```

2. **Passing configuration directly via the `--config` flag**

   To pass the configuration content directly:

   ```sh
   kumactl install transparent-proxy --config "kumaDPUser: dataplane\nverbose: true"
   ```

   Alternatively:

   ```sh
   kumactl install transparent-proxy --config "{ kumaDPUser: dataplane, verbose: true }"
   ```

   Both formats are valid YAML inputs.

3. **Passing configuration via [STDIN](https://en.wikipedia.org/wiki/Standard_streams#Standard_input_(stdin))**

   If you need to pass the configuration via STDIN, set `--config-file` to `-` as shown below:

   ```sh
   echo "
   kumaDPUser: dataplane
   verbose: true
   " | kumactl install transparent-proxy --config-file -
   ```

### Method 2: Using environment variables
{:#{{ tproxy.ids.guides.customize-config.uni.methods.env }}}

You can customize configuration settings by using environment variables. For example:

```sh
KUMA_TRANSPARENT_PROXY_IP_FAMILY_MODE="ipv4" kumactl install transparent-proxy
```

{% tip %}
To see all available environment variables, visit the [Environment Variables]({{ ref-section-env }}) section in the [Transparent Proxy Configuration Reference]({{ ref }}).
{% endtip %}

### Method 3: CLI flags
{:#{{ tproxy.ids.guides.customize-config.uni.methods.cli }}}

Most configuration values can also be specified directly through CLI flags. For example:

```sh
kumactl install transparent-proxy --kuma-dp-user dataplane --verbose
```

{% warning %}
The following settings cannot be modified directly via CLI flags (corresponding flags are not available):

- `redirect.dns.resolvConfigPath`
- `redirect.inbound.includePorts`
- `redirect.inbound.excludePortsForUIDs`
- `redirect.outbound.enabled`
- `redirect.outbound.includePorts`
- `ebpf.instanceIPEnvVarName`
- `log.level`
- `cniMode`
{% endwarning %}

{% tip %}
To see all available CLI flags, visit the [CLI Flags]({{ ref-section-cli }}) section in the [Transparent Proxy Configuration Reference]({{ ref }}).
{% endtip %}

## Order of precedence

1. **Default Values**
2. **Values from** `--config` / `--config-file` **flags**
3. **Environment Variables**
4. **CLI Flags**

To understand how the order of precedence works, consider this scenario:

1. You have a `config.yaml` file with the following content:

   ```yaml
   redirect:
     dns:
       port: 10001
   ```

2. You install the transparent proxy using this command:

   ```sh
   KUMA_TRANSPARENT_PROXY_REDIRECT_DNS_PORT="10002" \
     kumactl install transparent-proxy \
       --config-file config.yaml \
       --redirect-dns-port 10003
   ```

3. In this situation, the possible values for `redirect.dns.port` are:

   - **`{{ tproxy.defaults.redirect.dns.port }}`** (Default Value)
   - **`10001`** (From Config File)
   - **`10002`** (From Environment Variable)
   - **`10003`** (From CLI Flag)

4. Since CLI flags have the highest precedence, the final value for `redirect.dns.port` will be **`10003`**.
