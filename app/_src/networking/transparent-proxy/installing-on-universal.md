---
title: Installing Transparent Proxy on Universal
content_type: how-to
---

{% assign docs = "/docs/" | append: page.version %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% tip %}
These instructions apply to **Universal** mode, where {{ Kuma }} needs to be manually configured for each environment. In **Kubernetes** mode, the transparent proxy is set up automatically using the [`kuma-init` container]({{ docs }}/production/dp-config/dpp-on-kubernetes/) or [Kuma CNI]({{ docs }}/production/dp-config/cni/), so the steps below do not apply.
{% endtip %}

This page provides instructions for setting up a transparent proxy in your service environment. A transparent proxy helps streamline service management and traffic routing within a mesh, directing all traffic through the data plane proxy without requiring changes to your application code.

Once completed, your service will run under a transparent proxy, allowing you to use {{ Kuma }}'s service management features, like traffic control, observability, and security.

Before starting, review the prerequisites below and adjust settings to fit your environment, including IP addresses, custom ports, and DNS configurations.

## Terminology overview

- **Service**: In this instruction, **service** refers to an application running in the environment where the transparent proxy is deployed. An exception is when we refer to [systemd](https://systemd.io/) services; in these cases, **service** specifically means a [systemd service unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html).

## Prerequisites

{%- capture control-plane-and-service-network-accessibility-warning %}
{% warning %}
For this instruction, the control plane **should not** be deployed in the same environment as the transparent proxy. This is because the transparent proxy redirects **all** traffic (unless specifically excluded) to `kuma-dp`, including traffic meant for the control plane.

While it is technically possible to manually exclude control plane traffic during setup, this is complex and easy to misconfigure, as it requires excluding **all** necessary ports and routes.

In real deployments, you can work around it by running the control plane and other components in separate network namespaces using systemd, which keeps control plane traffic separate from `kuma-dp` and the service.
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
To easily download all necessary binaries, you can use the following script, which automatically detects your operating system and fetches the required binaries:

```sh
curl -L {{ site.links.web }}{% if page.edition %}/{{ page.edition }}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -
```
{:.no-line-numbers}

Omitting the `VERSION` variable will install the latest version.
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

## Step 1: Create a dedicated user for kuma-dp

For proper functionality, the service must run under a different user than the one designated for running `kuma-dp`. If both the service and `kuma-dp` are run by the same user, the transparent proxy will not work correctly, causing service traffic (inbound and outbound) to fail. To create a dedicated user for `kuma-dp`, use the following command:

```sh
useradd -u {{ tproxy.defaults.kuma-dp.username }} -U {{ tproxy.defaults.kuma-dp.username }}
```

{% warning %}
In some Linux distributions, the `useradd` command may not be available. In such cases, follow the specific guidelines for your system to manually create a user with a `UID` of `{{ tproxy.defaults.kuma-dp.uid }}` and the username `{{ tproxy.defaults.kuma-dp.username }}`.
{% endwarning %}

<!-- vale Google.Headings = NO -->
## Step 2: Prepare the Dataplane resource
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

### Redirect ports

In this example, `{{ tproxy.defaults.redirect.inbound.port }}` and `{{ tproxy.defaults.redirect.outbound.port }}` are the default ports for inbound and outbound traffic redirection. You can change these ports in the transparent proxy configuration during installation (`redirect.inbound.port` and `redirect.outbound.port`). For more details, see the [Transparent Proxy Configuration Reference]({{ docs }}/reference/transparent-proxy-configuration/).

{% warning %}
**Important:** If you use different ports, be sure to update all related configurations and steps to match the new values.
{% endwarning %}

### Using variables in your configuration

The placeholders `{% raw %}{{ name }}{% endraw %}`, `{% raw %}{{ address }}{% endraw %}`, and `{% raw %}{{ port }}{% endraw %}` are [Mustache templates](http://mustache.github.io/mustache.5.html), which will be dynamically filled using values passed via `--dataplane-var` CLI flags in a later step.

In practice, if these values are static, you can simply hard-code them in your configuration. This feature is designed to allow more flexible and reusable resources, making it easier to dynamically adjust values when starting `kuma-dp`.

### More resources

For additional information on setting up the `Dataplane` resource, refer to the [Data Plane on Universal]({{ docs }}/production/dp-config/dpp-on-universal/#data-plane-on-universal) documentation.

## Step 3: Start the service

The service can be started in various ways depending on your environment and requirements. To keep this instruction simple, we’ll use Python 3’s built-in HTTP server. This server will listen on port `8080`, with both [STDOUT](https://en.wikipedia.org/wiki/Standard_streams#Standard_output_(stdout)) and [STDERR](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_(stderr)) redirected to a `service.log` file in the current directory, running in the background.

{% danger %}
**Remember that** the service must run under a **different** user than the one designated for `kuma-dp`. In the example below, the service will run as the user you're currently logged in as. **Ensure** that this is not the same user assigned to the `kuma-dp`.
{% enddanger %}

To start the service:

```sh
python3 -m http.server 8080 > service.log 2>&1 &
```

## Step 4: Start the kuma-dp

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

## Step 5: Install the transparent proxy

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
