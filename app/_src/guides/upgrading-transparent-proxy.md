---
title: Upgrading Transparent Proxy
content_type: tutorial
description: Clean up existing iptables rules and reinstall the transparent proxy on Universal environments.
keywords:
  - transparent proxy
  - iptables
  - upgrade
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}

{% capture Warning %}{% if page.edition and page.edition != "kuma" %}**Warning:** {% endif %}{% endcapture %}
{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}
{% capture brbr %}{% if page.edition and page.edition != "kuma" %}<br /><br />{% endif %}{% endcapture %}

The core `iptables` rules applied by {{ Kuma }}'s transparent proxy rarely change, but occasionally new features may require updates. To upgrade the transparent proxy on Universal environments, follow these steps:

### Step 1: Cleanup existing iptables rules{% if_version gte:2.9.x inline:true %} (conditional){% endif_version %}

{% if_version gte:2.9.x %}
{% warning %}
{{ Important }}If you're upgrading from {{ Kuma }} version 2.9 or later, and you have **not** manually disabled the automatic addition of comments by setting `comments.disabled` to `true` in the transparent proxy configuration, **this step is unnecessary**.
{{ brbr }}
Starting with {{ Kuma }} 2.9, all `iptables` rules are tagged with comments, allowing {{ Kuma }} to track rule ownership. This enables `kumactl` to automatically clean up any existing `iptables` rules or custom chains created by previous versions of the transparent proxy. This process runs automatically at the start of the installation, eliminating the need for any manual cleanup beforehand.
{% endwarning %}
{% endif_version %}

To manually remove existing `iptables` rules, you can either restart the host (if the rules were not persisted using system start-up scripts or `firewalld`), or run the following commands:

{% danger %}
{{ Warning }}These commands will remove **all** `iptables` rules and **all** custom chains in the specified tables, including those created by {{ Kuma }} as well as any other applications or services.
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

### Step 2: Install the new transparent proxy

After clearing the `iptables` rules (if necessary), reinstall the transparent proxy. For example:

```sh
kumactl install transparent-proxy --kuma-dp-user kuma-dp --redirect-dns --verbose
```

This installs the latest version of the transparent proxy with the specified configuration. Adjust the flags as needed for your environment.
