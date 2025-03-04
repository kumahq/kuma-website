---
title: Transparent Proxy on Universal
content_type: how-to
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% capture Warning %}{% if page.edition and page.edition != "kuma" %}**Warning:** {% endif %}{% endcapture %}
{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}
{% capture Note %}{% if page.edition and page.edition != "kuma" %}**Note:** {% endif %}{% endcapture %}
{% capture brbr %}{% if page.edition and page.edition != "kuma" %}<br /><br />{% endif %}{% endcapture %}

Using the transparent proxy in Universal mode makes setup easier and enables features that wouldn’t be possible otherwise. Key benefits include:

- **Simplified `Dataplane` resources**: You can skip the `networking.outbound` section, so you don’t have to list each service your application connects to manually.

- **Simplified service connectivity**: Take advantage of [{{ Kuma }} DNS]({{ docs }}/networking/transparent-proxy/dns/), for easy service connections without needing `localhost` and ports in the `Dataplane` resource.

## Configuration

The default configuration works well for most scenarios, but there are cases where adjustments are needed.

{{ Kuma }} uses a unified configuration structure for transparent proxy across all components. For a detailed breakdown of this structure, including examples, expected formats, and variations between configuration methods, refer to the [configuration reference]({{ docs }}/networking/transparent-proxy/configuration-reference/).

In Universal mode, {{ Kuma }} there are three methods to adjust the configuration. Each can be used on its own or combined with others if needed.

{% warning %}
{{ Important }}It’s best to stick to one method whenever possible. Using more than one can make things more complicated and harder to troubleshoot, as it may not be clear where each setting comes from. If you need to combine methods, check the [**Order of Precedence**](#order-of-precedence) section to see what the final configuration will look like based on the priority of each setting.
{% endwarning %}

<!-- vale off -->
### yaml / json
<!-- vale on -->

You can provide the configuration in either `yaml` or `json` format by using the `--config` or `--config-file` flags.

{% tip %}
{{ Note }}For the configuration schema in yaml format, refer to the [Schema]({{ docs }}/networking/transparent-proxy/configuration-reference/#schema) section in the [configuration reference]({{ docs }}/networking/transparent-proxy/configuration-reference/).
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

   Both formats are valid yaml inputs.

3. **Passing configuration via [stdin](https://en.wikipedia.org/wiki/Standard_streams#Standard_input_(stdin))**

   If you need to pass the configuration via stdin, set `--config-file` to `-` as shown below:

   ```sh
   echo "
   kumaDPUser: dataplane
   verbose: true
   " | kumactl install transparent-proxy --config-file -
   ```

<!-- vale Google.Headings = NO -->
### Environment Variables
<!-- vale Google.Headings = YES -->

You can customize configuration settings by using environment variables. For example:

```sh
KUMA_TRANSPARENT_PROXY_IP_FAMILY_MODE="ipv4" kumactl install transparent-proxy
```

{% tip %}
{{ Note }}To see all available environment variables, visit the [Environment Variables]({{ docs }}/networking/transparent-proxy/configuration-reference/#environment-variables) section in the [configuration reference]({{ docs }}/networking/transparent-proxy/configuration-reference/).
{% endtip %}

<!-- vale Google.Headings = NO -->
### Order of Precedence
<!-- vale Google.Headings = YES -->

1. **Default Values**
2. **Values from** `--config` / `--config-file` **flags**
3. **Environment Variables**

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
     kumactl install transparent-proxy --config-file config.yaml
   ```

3. In this situation, the possible values for `redirect.dns.port` are:

   - **`{{ tproxy.defaults.redirect.dns.port }}`** (Default Value)
   - **`10001`** (from config file)
   - **`10002`** (from environment variable)

4. Since environmental variable have the highest precedence, the final value for `redirect.dns.port` will be **`10002`**.

## firewalld support

The changes made by running `kumactl install transparent-proxy` **will not persist** after a reboot. To ensure persistence, you can either add this command to your system's start-up scripts or leverage `firewalld` for managing `iptables`.

If you prefer using `firewalld`, you can include the `--store-firewalld` flag when installing the transparent proxy. This will store the `iptables` rules in `/etc/firewalld/direct.xml`, ensuring they persist across system reboots. Here's an example:

```sh
kumactl install transparent-proxy --redirect-dns --store-firewalld
```

{% warning %}
**Important:** Currently, there is no uninstall command for this feature. If needed, you will have to manually clean up the `firewalld` configuration.
{% endwarning %}
