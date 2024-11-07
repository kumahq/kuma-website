---
title: Transparent Proxy on Universal
content_type: how-to
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

Using the transparent proxy in Universal mode makes setup easier and enables features that wouldn’t be possible otherwise. Key benefits include:

- **Simplified `Dataplane` resources**: You can skip the `networking.outbound` section, so you don’t have to list each service your application connects to manually.

- **Simplified service connectivity**: Take advantage of [Kuma DNS]({{ docs }}/networking/dns/) to use `.mesh` domain names, like `https://service-1.mesh`, for easy service connections without needing `localhost` and ports in the `Dataplane` resource.

- **Flexible service naming**: With [MeshServices]({{ docs }}/networking/meshservice/) and [HostnameGenerators]({{ docs }}/networking/hostnamegenerator/), you can:

  - Keep your existing DNS names when moving to the service mesh.
  - Give a service multiple DNS names for easier access.
  - Set up custom routes, like targeting specific StatefulSet Pods or service versions.
  - Expose a service on multiple ports for different uses.

- **Simpler security, tracing, and observability**: Transparent proxy makes managing these features easier, with no extra setup required.

## Installation

Here are the steps to set up a transparent proxy for your service. Once set up, your service will run with a transparent proxy, giving you access to {{ Kuma }}'s features like traffic control, observability, and security.

Before you start, check the prerequisites below and adjust the settings for your environment, including IP addresses, custom ports, and DNS configurations.

### Prerequisites

{%- capture control-plane-and-service-network-accessibility-warning %}
{% warning %}
In a basic setup, the control plane **should not** be deployed in the same environment as the transparent proxy. This is because the transparent proxy redirects **all** traffic to `kuma-dp` (unless excluded), including traffic meant for the control plane.
{% endwarning %}
{%- endcapture %}

{%- capture control-plane-and-service-network-accessibility-tip %}
{% tip %}
For deployment instructions, see [Deploy a single-zone control plane]({{ docs }}/production/cp-deployment/single-zone/).
{% endtip %}
{%- endcapture %}

{%- capture data-plane-proxy-token-tip %}
{% tip %}
For instructions on generating this token, refer to the [Data plane proxy token]({{ docs }}/production/secure-deployment/dp-auth/#data-plane-proxy-token) section in the [Authentication with the data plane proxy]({{ docs }}/production/secure-deployment/dp-auth/#authentication-with-the-data-plane-proxy) documentation.
{% endtip %}
{%- endcapture %}

{%- capture binary-availability-tip %}
{% tip %}
To get the required binaries, see [Install Kuma]({{ docs }}/introduction/install-kuma/).
{% endtip %}
{% endcapture -%}

1. **Control plane deployment and network accessibility**: Ensure {{ Kuma }}'s control plane is already deployed and accessible from the service via an IP address or DNS name. Adapt the steps below to reflect the correct address for your setup.

   {{ control-plane-and-service-network-accessibility-warning | indent }}

   {{ control-plane-and-service-network-accessibility-tip | indent }}

2. **Service accessibility**: Ensure the environment with the transparent proxy and service is reachable by other services in the mesh via IP or DNS. Adjust the setup steps to match the appropriate address where the service is accessible.

3. **Data plane proxy token**: Place the data plane proxy token at `/kuma/example-server-token` (or adjust the steps if stored elsewhere).

   {{ data-plane-proxy-token-tip | indent }}

4. **Binary availability**: Ensure `kuma-dp`, `envoy`, and `coredns` binaries are accessible in `/usr/local/bin/`, and `kumactl` is in the system’s `PATH`. Adjust any subsequent commands if the binaries are located elsewhere.

   {{ binary-availability-tip | indent }}

### Step 1: Create a dedicated user for kuma-dp

For proper functionality, the service must run under a different user than the one designated for running `kuma-dp`. If both the service and `kuma-dp` are run by the same user, the transparent proxy will not work correctly, causing service traffic (inbound and outbound) to fail. To create a dedicated user for `kuma-dp`, use the following command:

```sh
useradd -u {{ tproxy.defaults.kuma-dp.username }} -U {{ tproxy.defaults.kuma-dp.username }}
```

{% warning %}
In some Linux distributions, the `useradd` command may not be available. In such cases, follow the specific guidelines for your system to manually create a user with a `UID` of `{{ tproxy.defaults.kuma-dp.uid }}` and the username `{{ tproxy.defaults.kuma-dp.username }}`.
{% endwarning %}

<!-- vale Google.Headings = NO -->
### Step 2: Prepare the Dataplane resource
<!-- vale Google.Headings = YES -->

In transparent proxy mode, configure your `Dataplane` resource without the `networking.outbound` section. Instead, use `networking.transparentProxying` for handling traffic redirection. Here’s an example:

If your `/kuma/example-server-dataplane.yaml` looks like this:

```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
    - port: {% raw %}{{ port }}{% endraw %}
      tags:
        kuma.io/service: example-server
  outbound:
    - port: 6379
      tags:
        kuma.io/service: redis
```

After updating it for transparent proxy, it should look like this:

```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
    - port: {% raw %}{{ port }}{% endraw %}
      tags:
        kuma.io/service: example-server
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
```

#### Redirect ports

In this example, `{{ tproxy.defaults.redirect.inbound.port }}` and `{{ tproxy.defaults.redirect.outbound.port }}` are the default ports for inbound and outbound traffic redirection. You can change these ports in the transparent proxy configuration during installation (`redirect.inbound.port` and `redirect.outbound.port`). For more details, see the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).

{% warning %}
**Important:** If you use different ports, be sure to update all related configurations and steps to match the new values.
{% endwarning %}

#### Using variables in your configuration

The placeholders `{% raw %}{{ name }}{% endraw %}`, `{% raw %}{{ address }}{% endraw %}`, and `{% raw %}{{ port }}{% endraw %}` are [Mustache templates](http://mustache.github.io/mustache.5.html), which will be dynamically filled using values passed via `--dataplane-var` CLI flags in a later step.

In practice, if these values are static, you can simply hard-code them in your configuration. This feature is designed to allow more flexible and reusable resources, making it easier to dynamically adjust values when starting `kuma-dp`.

#### More resources

For additional information on setting up the `Dataplane` resource, refer to the [Data Plane on Universal]({{ docs }}/production/dp-config/dpp-on-universal/#data-plane-on-universal) documentation.

### Step 3: Start the service

The service can be started in various ways depending on your environment and requirements. To keep this instruction simple, we’ll use Python 3’s built-in HTTP server. This server will listen on port `8080`, with both [STDOUT](https://en.wikipedia.org/wiki/Standard_streams#Standard_output_(stdout)) and [STDERR](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_(stderr)) redirected to a `service.log` file in the current directory, running in the background.

{% danger %}
**Remember that** the service must run under a **different** user than the one designated for `kuma-dp`. In the example below, the service will run as the user you're currently logged in as. **Ensure** that this is not the same user assigned to the `kuma-dp`.
{% enddanger %}

To start the service:

```sh
python3 -m http.server 8080 > service.log 2>&1 &
```

### Step 4: Start the kuma-dp

If you are using `systemd` to manage processes, you can refer to the [Systemd documentation]({{ docs }}/production/cp-deployment/systemd/) for an example of a `systemd` resource that can be customized to run `kuma-dp` in your environment.

Alternatively, if you're starting `kuma-dp` using a script or another form of automation, you can use `runuser` to run the process as the `{{ tproxy.defaults.kuma-dp.username }}` user. Below is an example of how to start `kuma-dp` with the necessary parameters:

```sh
# Set the Control Plane address (IP or DNS) accessible by this environment
export CP_ADDRESS="..."  

# Set the Data Plane address (IP or DNS) for the current environment, accessible by
# other services
export DP_ADDRESS="..."

runuser -u {{ tproxy.defaults.kuma-dp.username }} -- \
  /usr/local/bin/kuma-dp run \
    --cp-address="https://$CP_ADDRESS:5678" \
    --dataplane-token-file="/kuma/example-server-token" \
    --dataplane-file="/kuma/example-server-dataplane.yaml" \
    --dataplane-var="name=example-server-dataplane" \
    --dataplane-var="address=$DP_ADDRESS" \
    --dataplane-var="port=8080" \
    --binary-path="/usr/local/bin/envoy" \
    --dns-coredns-path="/usr/local/bin/coredns"
```

This command runs `kuma-dp` under the `{{ tproxy.defaults.kuma-dp.username }}` user, connects it to the control plane, and configures it with the necessary settings for the example server. Adjust the paths and values as needed for your specific setup.

### Step 5: Install the transparent proxy

Before proceeding with this step, please keep the following in mind:

{% warning %}
`kumactl` will return an error if you attempt to install the transparent proxy without `root` privileges. Ensure that you run the command as `root`.
{% endwarning %}

{% warning %}
Once the transparent proxy is installed, all traffic configured for redirection will be immediately routed to `kuma-dp`. Therefore, it's important to start `kuma-dp` **before** installing the transparent proxy. If `kuma-dp` is not running, redirected traffic will be dropped, leading to a potential loss of connectivity (including SSH connections if port `22` hasn't been excluded).

We strongly recommend starting `kuma-dp` **before** installing the transparent proxy. However, if you choose to install the transparent proxy first, make sure to exclude SSH traffic, for example by configuring `redirect.inbound.excludePorts` with `--exclude-inbound-ports` flag:

```sh
kumactl install transparent-proxy --redirect-dns --exclude-inbound-ports "22"
```
{% endwarning %}

{% danger %}
The transparent proxy **must** be configured to use **the same** user as the one running the `kuma-dp` process to function properly.
{% enddanger %}

{% danger %}
The following command **will modify** the host's `iptables` rules. If your environment already has existing `iptables` rules, ensure that the changes made by `kumactl` are compatible with your setup. You can check compatibility by running the command in dry-run mode using the `--dry-run` flag.
{% enddanger %}

To install the transparent proxy in your environment, run the following command:

```sh
kumactl install transparent-proxy --redirect-dns
```

This will result in the following:

- The transparent proxy will be set up to use the `{{ tproxy.defaults.kuma-dp.username }}` user as the designated user for running the `kuma-dp` process.

  {% capture default-kuma-dp-user-lookup-tip %}
  {% tip %}
  By default, `kumactl` searches for a user with UID `{{ tproxy.defaults.kuma-dp.uid }}` or the username `{{ tproxy.defaults.kuma-dp.username }}`. If you prefer to use a custom username or UID, you can specify it using the `--kuma-dp-user` flag. If the specified user cannot be found, the installation process will fail with an error.
  {% endtip %}
  {% endcapture %}
  {{ default-kuma-dp-user-lookup-tip | indent }}

- All **incoming traffic** will be redirected to `kuma-dp` on port `{{ tproxy.defaults.redirect.inbound.port }}`.

  {% capture default-redirect-port-inbound-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.inbound.port }}` is the default for redirecting incoming traffic. If you used a different port in your `Dataplane` resource definition, ensure it aligns with the transparent proxy configuration. To update it, modify the `redirect.inbound.port` setting during installation, for example by using the `--redirect-inbound-port` flag.
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-inbound-tip | indent }}

- All **outgoing traffic** will be redirected to `kuma-dp` on default port `{{ tproxy.defaults.redirect.outbound.port }}`.

  {% capture default-redirect-port-outbound-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.outbound.port }}` is the default used for redirecting outgoing traffic. If you used a different port in your `Dataplane` resource definition, ensure it aligns with the transparent proxy configuration. To update it, modify the `redirect.outbound.port` setting during installation, for example by using the `--redirect-outbound-port` flag.
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-outbound-tip | indent }}

- DNS traffic directed to the DNS servers configured in `{{ tproxy.defaults.resolv.conf.path }}` will be redirected to the `coredns` managed by `kuma-dp` on port `{{ tproxy.defaults.redirect.dns.port }}`.

  {% capture default-redirect-port-dns-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.dns.port }}` is the default used for redirecting DNS traffic. If you wish to modify this port, it is crucial to ensure consistency between the transparent proxy and `kuma-dp`. In this case, you must update the `kuma-dp run` command to include the `--dns-coredns-port` flag with the desired custom port. To adjust it for the transparent proxy, modify the `redirect.dns.port` setting during installation, for example by using the `--redirect-dns-port` flag.
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-dns-tip | indent }}

  {% capture resolv-conf-tip %}
  {% tip %}
  `{{ tproxy.defaults.resolv.conf.path }}` is the file used by default to parse DNS servers for redirecting DNS traffic through the transparent proxy. This file is relevant only if you opt to redirect DNS traffic specifically to the DNS servers listed within it (for example, by using the `--redirect-dns` flag during installation). If you're redirecting **all** DNS traffic (for example, by using the `--redirect-all-dns-traffic` flag), this path becomes irrelevant.

  **We strongly recommend against** changing this path. However, if your environment uses a different file to specify DNS servers (which must follow the same format as `{{ tproxy.defaults.resolv.conf.path }}`), you can adjust it by modifying the `redirect.dns.resolvConfigPath` setting during installation. This can be done, for example, using the `KUMA_TRANSPARENT_PROXY_REDIRECT_DNS_RESOLV_CONFIG_PATH` environment variable.
  {% endtip %}
  {% endcapture %}
  {{ resolv-conf-tip | indent }}

## Upgrading

The core `iptables` rules applied by {{ Kuma }}'s transparent proxy rarely change, but occasionally new features may require updates. To upgrade the transparent proxy on Universal environments, follow these steps:

### Step 1: Cleanup existing iptables rules (conditional)

{% warning %}
If you're upgrading from {{ Kuma }} version 2.9 or later, and you have **not** manually disabled the automatic addition of comments by setting `comments.disabled` to `true` in the transparent proxy configuration, **this step is unnecessary**.

Starting with {{ Kuma }} 2.9, all `iptables` rules are tagged with comments, allowing {{ Kuma }} to track rule ownership. This enables `kumactl` to automatically clean up any existing `iptables` rules or custom chains created by previous versions of the transparent proxy. This process runs automatically at the start of the installation, eliminating the need for any manual cleanup beforehand.
{% endwarning %}

To manually remove existing `iptables` rules, you can either restart the host (if the rules were not persisted using system start-up scripts or `firewalld`), or run the following commands:

{% danger %}
These commands will remove **all** `iptables` rules and **all** custom chains in the specified tables, including those created by {{ Kuma }} as well as any other applications or services.
{% enddanger %}

```sh
iptables --table nat --flush         # Flush all rules in the nat table (IPv4)
ip6tables --table nat --flush        # Flush all rules in the nat table (IPv6)
iptables --table nat --delete-chain  # Delete all custom chains in the nat table (IPv4)
ip6tables --table nat --delete-chain # Delete all custom chains in the nat table (IPv6)

# The raw table contains rules for DNS traffic redirection
iptables --table raw --flush         # Flush all rules in the raw table (IPv4)
ip6tables --table raw --flush        # Flush all rules in the raw table (IPv6)

# The mangle table contains rules to drop invalid packets
iptables --table mangle --flush      # Flush all rules in the mangle table (IPv4)
ip6tables --table mangle --flush     # Flush all rules in the mangle table (IPv6)
```

### Step 2: Install new transparent proxy

After clearing the `iptables` rules (if necessary), reinstall the transparent proxy by running:

```sh
kumactl install transparent-proxy [...]
```

This command will install the new version of the transparent proxy with the specified configuration. Adjust the flags as needed to suit your environment.

## Configuration

The default configuration works well for most scenarios, but there are cases where adjustments are needed.

{{ Kuma }} uses a unified configuration structure for transparent proxy across all components. For a detailed breakdown of this structure, including examples, expected formats, and variations between configuration methods, refer to the [Transparent Proxy Configuration reference]({{ docs }}/reference/transparent-proxy-configuration/).

In Universal mode, {{ Kuma }} there are three methods to adjust the configuration. Each can be used on its own or combined with others if needed.

{% warning %}
It’s best to stick to one method whenever possible. Using more than one can make things more complicated and harder to troubleshoot, as it may not be clear where each setting comes from. If you need to combine methods, check the [**Order of Precedence**](#order-of-precedence) section to see what the final configuration will look like based on the priority of each setting.
{% endwarning %}

<!-- vale Google.Headings = NO -->
### YAML / JSON
<!-- vale Google.Headings = YES -->

You can provide the configuration in either `YAML` or `JSON` format by using the `--config` or `--config-file` flags.

{% tip %}
For the configuration schema in YAML format, refer to the [Schema]({{ docs }}/reference/transparent-proxy-configuration/#schema) section in the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).
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

<!-- vale Google.Headings = NO -->
### Environment Variables
<!-- vale Google.Headings = YES -->

You can customize configuration settings by using environment variables. For example:

```sh
KUMA_TRANSPARENT_PROXY_IP_FAMILY_MODE="ipv4" kumactl install transparent-proxy
```

{% tip %}
To see all available environment variables, visit the [Environment Variables]({{ docs }}/reference/transparent-proxy-configuration/#environment-variables) section in the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).
{% endtip %}

<!-- vale Google.Headings = NO -->
### CLI Flags
<!-- vale Google.Headings = YES -->

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
To see all available CLI flags, visit the [CLI Flags]({{ docs }}/reference/transparent-proxy-configuration/#cli-flags) section in the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).
{% endtip %}

<!-- vale Google.Headings = NO -->
### Order of Precedence
<!-- vale Google.Headings = YES -->

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

## firewalld support

The changes made by running `kumactl install transparent-proxy` **will not persist** after a reboot. To ensure persistence, you can either add this command to your system's start-up scripts or leverage `firewalld` for managing `iptables`.

If you prefer using `firewalld`, you can include the `--store-firewalld` flag when installing the transparent proxy. This will store the `iptables` rules in `/etc/firewalld/direct.xml`, ensuring they persist across system reboots. Here's an example:

```sh
kumactl install transparent-proxy --redirect-dns --store-firewalld
```

{% warning %}
**Important:** Currently, there is no uninstall command for this feature. If needed, you will have to manually clean up the `firewalld` configuration.
{% endwarning %}