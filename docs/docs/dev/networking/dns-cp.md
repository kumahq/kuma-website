# DNS in the control plane

::: warning
This is deprecated way of handling Kuma DNS that will be removed in the future versions of Kuma. Consider using [DNS embedded in kuma-dp](../dns)
:::

In this mode, DNS traffic is not intercepted and resolved by Envoy, but the DNS resolver is explicitly configured with `kuma-cp` DNS server for defined domains (`.mesh` by default).

## How Kuma DNS in the control plane works

Kuma DNS in the control plane works in a similar way as Kuma DNS embedded in `kuma-dp`, but DNS server is run by `kuma-cp`.
The DNS server in kuma-cp listens on port `5653`.

## Installation

The Kuma control plane exposes a DNS service which handles the name resolution in the `.mesh` DNS zone.

Usually DNS configuration expects DNS server to be served on port `53` therefore we need to [configure](../documentation/configuration.md) the control plane with `KUMA_DNS_SERVER_PORT` set to `53`.

:::: tabs
::: tab "Kubernetes" :options="{ useUrlFragment: false }"
1. When you install the control plane, [configure](../documentation/configuration.md) it with the following environment variable to disable the data plane proxy DNS:

`KUMA_RUNTIME_KUBERNETES_INJECTOR_BUILTIN_DNS_ENABLED=false`

2. Plug Kuma DNS resolver into Kube DNS or Core DNS

`kumactl install dns`
:::
::: tab "Universal"
Follow the instruction in [transparent proxying](../transparent-proxying), but when `install transparent-proxy` is executed. Set the following arguments

```shell
kumactl install transparent-proxy \
          --kuma-dp-user kuma-dp \
          --kuma-cp-ip <KUMA_CP_IP_ADDRESS>
```

In addition to changing `iptables`, this command will also modify `/etc/resolv.conf`.
:::
::::
