---
title: Integrating Transparent Proxy into Your Service Environment 
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% tip %}
This guide is intended for **Universal** deployments, where {{ Kuma }} must be configured manually for each environment. In **Kubernetes** environments, the transparent proxy is automatically installed through the [`kuma-init` container]({{ docs }}/production/dp-config/dpp-on-kubernetes/) or the [Kuma CNI]({{ docs }}/production/dp-config/cni/#configure-the-kuma-cni), so the instructions below are not applicable.
{% endtip %}

This guide provides a step-by-step walkthrough on integrating a transparent proxy into your service environment using {{ Kuma }}. Transparent proxy simplifies service management and traffic routing within a mesh, ensuring that all traffic flows through the designated data plane proxy without requiring changes to your application code.

By the end of this guide, your service will be running under a transparent proxy, allowing you to leverage {{ Kuma }}'s advanced service management features, such as traffic control, observability, and security.

Make sure to review the key assumptions and information outlined in the guide before proceeding with the installation. Adjust the parameters as needed to match your environment's specific details, such as IP addresses, custom ports, and DNS configurations.

## Terminology Overview

- **Service**: In this guide, **service** refers to an application running in the environment where the transparent proxy is deployed. An exception is when we refer to [systemd](https://systemd.io/) services; in these cases, **service** specifically means a [systemd service unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html).

## Prerequisites

{%- capture control-plane-and-service-network-accessibility-warning %}
{% warning %}
For this guide, the Control Plane **should not** be deployed in the same environment as the transparent proxy. This is because the transparent proxy redirects **all** traffic (unless specifically excluded) to `kuma-dp`, including traffic meant for the Control Plane.

While it is technically possible to manually exclude Control Plane traffic during setup, this is complex and easy to misconfigure, as it requires excluding **all** necessary ports and routes.

In real deployments, you can work around it by running the Control Plane and other components in separate network namespaces using `systemd`, which keeps Control Plane traffic separate from `kuma-dp` and the service.
{% endwarning %}
{%- endcapture %}

{%- capture control-plane-and-service-network-accessibility-tip %}
{% tip %}
For deployment instructions, see [Deploy a Single Zone Control Plane]({{ docs }}/production/deployment/single-zone/#single-zone-deployment).
{% endtip %}
{%- endcapture %}

{%- capture data-plane-proxy-token-tip %}
{% tip %}
For instructions on generating this token, refer to the [Data Plane Proxy Token]({{ docs }}/production/secure-deployment/dp-auth/#data-plane-proxy-token) section in the [Authentication with the Data Plane Proxy]({{ docs }}/production/secure-deployment/dp-auth/#authentication-with-the-data-plane-proxy) documentation.
{% endtip %}
{%- endcapture %}

{%- capture binary-availability-tip %}
{% tip %}
To easily download all necessary binaries, you can use the following script, which automatically detects your operating system and fetches the required binaries:

```sh
curl -L {{ site.links.web }}{% if page.edition %}/{{ page.edition }}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -
```
{:.no-line-numbers}

Omitting the `VERSION` variable will install the latest version.
{% endtip %}
{% endcapture -%}

1. **Control Plane Deployment and Network Accessibility**: Ensure {{ Kuma }}'s Control Plane is already deployed and accessible from the service via an IP address or DNS name. Adapt the steps below to reflect the correct address for your setup.

   {{ control-plane-and-service-network-accessibility-warning | indent }}

   {{ control-plane-and-service-network-accessibility-tip | indent }}

2. **Mesh Service Reachability**: Ensure the environment with the transparent proxy and service is reachable by other services in the mesh via IP or DNS. Adjust the setup steps to match the appropriate address where the service is accessible.

3. **Data Plane Proxy Token**: Place the data plane proxy token at **`/kuma/example-server-token`** (or adjust the steps if stored elsewhere).

   {{ data-plane-proxy-token-tip | indent }}

4. **Binary Availability**: Ensure `kuma-dp`, `envoy`, and `coredns` binaries are accessible in `/usr/local/bin/`, and `kumactl` is in the system’s `PATH`. Adjust any subsequent commands if the binaries are located elsewhere.

   {{ binary-availability-tip | indent }}

{% if_version lte:2.4.x %}
## Step {% inc step_number if_version=lte:2.4.x %}: Ensure the correct version of iptables.
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.ensure-iptables }}}

{{ Kuma }} prior to 2.5 [isn't compatible](https://github.com/kumahq/kuma/issues/8293) with `nf_tables`. You can check the version of `iptables` with the command:

```sh
iptables --version
# iptables v1.8.7 (nf_tables)
```

On recent Ubuntu versions, switch to the legacy `iptables`:

```sh
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
iptables --version
# iptables v1.8.7 (legacy)
```
{% endif_version %}

## Step {% inc step_number %}: Create a dedicated user for kuma-dp
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.create-user }}}

For proper functionality, the service must run under a different user than the one designated for running `kuma-dp`. If both the service and `kuma-dp` are run by the same user, the transparent proxy will not work correctly, causing service traffic (inbound and outbound) to fail. To create a dedicated user for `kuma-dp`, use the following command:

```sh
useradd -u {{ tproxy.defaults.kuma-dp.username }} -U {{ tproxy.defaults.kuma-dp.username }}
```

{% warning %}
In some Linux distributions, the `useradd` command may not be available. In such cases, follow the specific guidelines for your system to manually create a user with a `UID` of `{{ tproxy.defaults.kuma-dp.uid }}` and the username `{{ tproxy.defaults.kuma-dp.username }}`.
{% endwarning %}

## Step {% inc step_number %}: Prepare the Dataplane Resource
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.prepare-dp }}}

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

### Redirect Ports

In this example, `{{ tproxy.defaults.redirect.inbound.port }}` and `{{ tproxy.defaults.redirect.outbound.port }}` are the default ports for inbound and outbound traffic redirection. {% if_version lte:2.8.x %}You can adjust these ports by specifying different values during installation via flags.{% endif_version %}{% if_version gte:2.9.x %}You can change these ports in the transparent proxy configuration during installation (`redirect.inbound.port` and `redirect.outbound.port`). For more details, see the [Transparent Proxy Configuration Reference]({{ docs }}{{ tproxy.paths.reference.configs.tproxy }}#transparent-proxy-configuration).{% endif_version %}

{% warning %}
**Important:** If you use different ports, be sure to update all related configurations and steps to match the new values.
{% endwarning %}

### Using Variables in Your Configuration

The placeholders `{% raw %}{{ name }}{% endraw %}`, `{% raw %}{{ address }}{% endraw %}`, and `{% raw %}{{ port }}{% endraw %}` are [Mustache templates](http://mustache.github.io/mustache.5.html), which will be dynamically filled using values passed via `--dataplane-var` CLI flags in a later step.

In practice, if these values are static, you can simply hardcode them in your configuration. This feature is designed to allow more flexible and reusable resources, making it easier to dynamically adjust values when starting `kuma-dp`.

### More Resources

For additional information on setting up the `Dataplane` resource, refer to the [Data Plane on Universal]({{ docs }}/production/dp-config/dpp-on-universal/#data-plane-on-universal) documentation.

## Step {% inc step_number %}: Start the Service
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.start-service }}}

The service can be started in various ways depending on your environment and requirements. To keep this guide simple, we’ll use Python 3’s built-in HTTP server. This server will listen on port `8080`, with both [STDOUT](https://en.wikipedia.org/wiki/Standard_streams#Standard_output_(stdout)) and [STDERR](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_(stderr)) redirected to a `service.log` file in the current directory, running in the background.

{% danger %}
**Remember that** the service must run under a **different** user than the one designated for `kuma-dp`. In the example below, the service will run as the user you're currently logged in as. **Ensure** that this is not the same user assigned to the `kuma-dp`.
{% enddanger %}

To start the service:

```sh
python3 -m http.server 8080 > service.log 2>&1 &
```

## Step {% inc step_number %}: Start kuma-dp
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.start-kuma-dp }}}

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

## Step {% inc step_number %}: Install the Transparent Proxy
{:#{{ tproxy.ids.guides.integrate-tproxy.steps.install-tproxy }}}

Before proceeding with this step, please keep the following in mind:

{% warning %}
{% if_version gte:2.9.x %}`kumactl` will return an error if you attempt to install the transparent proxy without `root` privileges.{% endif_version %} Ensure that you run the command as `root`{% if_version lte:2.8.x %}, as executing it without `root` privileges may lead to unexpected behavior{% endif_version %}.
{% endwarning %}

{% warning %}
Once the transparent proxy is installed, all traffic configured for redirection will be immediately routed to `kuma-dp`. Therefore, it's important to start `kuma-dp` **before** installing the transparent proxy. If `kuma-dp` is not running, redirected traffic will be dropped, leading to a potential loss of connectivity (including SSH connections if port `22` hasn't been excluded).

We strongly recommend starting `kuma-dp` **before** installing the transparent proxy. However, if you choose to install the transparent proxy first, make sure to exclude SSH traffic{% if_version gte:2.9.x %}, for example by configuring `redirect.inbound.excludePorts` with {% endif_version %}{% if_version lte:2.8.x %} by using{% endif_version %} `--exclude-inbound-ports` flag:

{% if_version gte:2.9.x %}
```sh
kumactl install transparent-proxy --redirect-dns --exclude-inbound-ports "22"
```
{% endif_version %}
{% if_version lte:2.8.x %}
```sh
kumactl install transparent-proxy \
  --kuma-dp-user "{{ tproxy.defaults.kuma-dp.username }}" \
  --exclude-inbound-ports "22" \
  --redirect-dns
```
{% endif_version %}
{% endwarning %}

{% danger %}
The transparent proxy **must** be configured to use **the same** user as the one running the `kuma-dp` process to function properly.
{% enddanger %}

{% danger %}
The following command **will modify** the host's `iptables` rules. If your environment already has existing `iptables` rules, ensure that the changes made by `kumactl` are compatible with your setup. You can check compatibility by running the command in dry-run mode using the `--dry-run` flag.
{% enddanger %}

To install the transparent proxy in your environment, run the following command:

{% if_version gte:2.9.x %}
```sh
kumactl install transparent-proxy --redirect-dns
```
{% endif_version %}
{% if_version lte:2.8.x %}
```sh
kumactl install transparent-proxy --kuma-dp-user "{{ tproxy.defaults.kuma-dp.username }}" --redirect-dns
```
{% endif_version %}

This will result in the following:

- The transparent proxy will be set up to use the `{{ tproxy.defaults.kuma-dp.username }}` user as the designated user for running the `kuma-dp` process.

{% if_version gte:2.9.x %}
  {% capture default-kuma-dp-user-lookup-tip %}
  {% tip %}
  By default, `kumactl` searches for a user with UID `{{ tproxy.defaults.kuma-dp.uid }}` or the username `{{ tproxy.defaults.kuma-dp.username }}`. If you prefer to use a custom username or UID, you can specify it using the `--kuma-dp-user` flag. If the specified user cannot be found, the installation process will fail with an error.
  {% endtip %}
  {% endcapture %}
  {{ default-kuma-dp-user-lookup-tip | indent }}
{% endif_version %}

- All **incoming traffic** will be redirected to `kuma-dp` on port `{{ tproxy.defaults.redirect.inbound.port }}`.

  {% capture default-redirect-port-inbound-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.inbound.port }}` is the default for redirecting incoming traffic. If you used a different port in your `Dataplane` resource definition, ensure it aligns with the transparent proxy configuration. {% if_version lte:2.8.x %}You can adjust this during installation by using the `--redirect-inbound-port` flag.{% endif_version %}{% if_version gte:2.9.x %}To update it, modify the `redirect.inbound.port` setting during installation, for example by using the `--redirect-inbound-port` flag.{% endif_version %}
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-inbound-tip | indent }}

- All **outgoing traffic** will be redirected to `kuma-dp` on default port `{{ tproxy.defaults.redirect.outbound.port }}`.

  {% capture default-redirect-port-outbound-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.outbound.port }}` is the default used for redirecting outgoing traffic. If you used a different port in your `Dataplane` resource definition, ensure it aligns with the transparent proxy configuration. {% if_version lte:2.8.x %}You can adjust this during installation by using the `--redirect-outbound-port` flag.{% endif_version %}{% if_version gte:2.9.x %}To update it, modify the `redirect.outbound.port` setting during installation, for example by using the `--redirect-outbound-port` flag.{% endif_version %}
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-outbound-tip | indent }}

- DNS traffic directed to the DNS servers configured in `{{ tproxy.defaults.resolv.conf.path }}` will be redirected to the `coredns` managed by `kuma-dp` on port `{{ tproxy.defaults.redirect.dns.port }}`.

  {% capture default-redirect-port-dns-tip %}
  {% tip %}
  Port `{{ tproxy.defaults.redirect.dns.port }}` is the default used for redirecting DNS traffic. If you wish to modify this port, it is crucial to ensure consistency between the transparent proxy and `kuma-dp`. In this case, you must update the `kuma-dp run` command to include the `--dns-coredns-port` flag with the desired custom port. {% if_version lte:2.8.x %}To configure this port for the transparent proxy, use the `--redirect-dns-port` flag during installation.{% endif_version %}{% if_version gte:2.9.x %}To adjust it for the transparent proxy, modify the `redirect.dns.port` setting during installation, for example by using the `--redirect-dns-port` flag.{% endif_version %}
  {% endtip %}
  {% endcapture %}
  {{ default-redirect-port-dns-tip | indent }}

  {% capture resolv-conf-tip %}
  {% tip %}
  `{{ tproxy.defaults.resolv.conf.path }}` {% if_version lte:2.8.x %}is the static value and **cannot be changed** in {{ Kuma }} versions prior to 2.9. It {% endif_version %}is the file used by default to parse DNS servers for redirecting DNS traffic through the transparent proxy. This file is relevant only if you opt to redirect DNS traffic specifically to the DNS servers listed within it (e.g., by using the `--redirect-dns` flag during installation). If you're redirecting **all** DNS traffic (e.g., by using the `--redirect-all-dns-traffic` flag), this path becomes irrelevant.

  {% if_version gte:2.9.x %}
  **We strongly recommend against** changing this path. However, if your environment uses a different file to specify DNS servers (which must follow the same format as `{{ tproxy.defaults.resolv.conf.path }}`), you can adjust it by modifying the `redirect.dns.resolvConfigPath` setting during installation. This can be done, for example, using the `KUMA_TRANSPARENT_PROXY_REDIRECT_DNS_RESOLV_CONFIG_PATH` environment variable.
  {% endif_version %}
  {% endtip %}
  {% endcapture %}
  {{ resolv-conf-tip | indent }}

## Additional Resources

- **Excluding Traffic from Transparent Proxy Redirection**: If you need to prevent certain services or specific types of traffic from being routed through `kuma-dp`, you can fine-tune the transparent proxy configuration to exclude them. For more information, refer to the [Excluding Traffic From Transparent Proxy Redirection]({{ docs }}{{ tproxy.paths.guides.exclude-traffic }}#excluding-traffic-from-transparent-proxy) guide.

{% if_version gte:2.9.x %}
- **Customizing Transparent Proxy Configuration**: For detailed instructions on customizing the transparent proxy configuration, see the [Configure Transparent Proxying]({{ docs }}/production/dp-config/transparent-proxying/#transparent-proxy) documentation.
{% endif_version %}

- **Upgrading Transparent Proxy**: If you need to upgrade your transparent proxy, refer to the [Upgrading Transparent Proxy]({{ docs }}/guides/upgrading-transparent-proxy/#upgrading-transparent-proxy) guide for the necessary steps and best practices.

{% if_version gte:2.9.x %}
- **Configuration Reference**: For detailed information on transparent proxy settings, check the [Transparent Proxy Configuration Reference]({{ docs }}{{ tproxy.paths.reference.configs.tproxy }}).
{% endif_version %}
