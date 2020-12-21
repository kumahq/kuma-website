# Using the Transparent Proxy in Universal mode

The Transparent proxy mode allows for seamless integration of all the services within a single Kuma cluster.
This is useful for Universal deployments in cros-zone and hybrid modes, but is also helpful in standalone deployments.

There are several advantages of using Transparent Proxy mode when in Universal:

 * simpler Dataplane resource, as the outbound section becomes obsolete
 * universal service naming using `.mesh` DNS domain
 * better service manageability (security, tracing)

### Preparing the Kuma Control plane

The Kuma control plane exposes a DNS service which handles the name resolution in the `.mesh` DNS zone. By default it listens
on port UDP/5653. For this setup we need it to listen on port UDP/53, therefore make sure that this environment variable is set
before running it `KUMA_DNS_SERVER_PORT=53`.

::: tip
The IP address of the host that runs Kuma Control plane will be used in the next section. Make sure to have it once, `kuma-cp` is started.
:::

### Setting up the service host

The host that will run the `kuma-dp` in Transparent Proxy mode needs to be prepared with the following steps:

 1. create a dedicated user that will be used
 2. redirect all the relevant inbound and outbound traffic to the Kuma Data plane proxy
 3. make the DNS resolving for `.mesh` is handled by `kuma-cp` embedded DNS server

Kuma comes with `kumactl` enabled to assist in preparing the host. Due to the wide variety of Linux setup options, these
steps may vary and may need to be adjusted for the specifics of the particular deployment. However, the common steps would be to
execute the following commands as `root`:

```shell
# create a dedicated user called kuma-dp
$ useradd -U kuma-dp

# use kumactl
$ kumactl install transparent-proxy \
          --kuma-dp-user kuma-dp \
          --kuma-cp-ip <kuma-cp IP>
```

Where `kuma-dp` is the name of the dedicated user that will be used to run `kuma-dp` process and `<kuma-cp IP>` is the IP address of the
Kuma control plane. This command will change the host iptables rules as well as modify `/etc/resolf.conf`, while keeping a backup copy of the original file.
The command has several other options which allow to change the default inbound and outbound redirect ports, add ports for exclusion and also disable the iptables or `resolve.conf` modification
steps. The command's help has enumerated and documented the available options.

::: tip
The default settings are to keep the SSH port `22` excluded from the redirection, thus allowing the remote host access to be preserved.
If the host is set up to use other remote management mechanisms, use `--exclude-inbound-ports` to provide a comma separated'KUMA_DNS_SERVER_PORT=53' list of the
relevant TCP ports to not be redirected.
:::

The changes will persist over restarts, so this command is needed only once. Reverting back to the original state of the host can be done by issuing `kumactl uninstall transparent-proxy`.

### The Dataplane resource

In the Transparent Proxy mode, the `Dataplane` resource that will be should ommit the `networking.outbound` section and use
`networking.transparentProxying` instead.

```yaml
type: Dataplane
mesh: default
name: {{ name }}
networking:
  address: {{ address }}
  inbound:
  - port: {{ port }}
    tags:
      kuma.io/service: demo-client
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
```

The ports show are the default that `kumactl install transparent-proxy` will set. These can be changed using the relevant flags to that command.

### Invoking the Kuma Data plane

The important thing when running `kuma-dp` is to make sure it runs as he dedicated user that was specified to `kumactl install transparent-proxy --kuma-dp-user`.
When systemd is used, this will be and entry `User=kuma-dp` in the `[Service]` section of the service file.
When systemd is used, this will be and entry `User=kuma-dp` in the `[Service]` section of the service file.
When starting `kuma-dp` with a script or some other automation, we can use `runuser` with the aforementioned yaml resource as follows:

```shell
$ runuser -u kuma-dp -- \
  /usr/bin/kuma-dp run \
    --cp-address=https://172.19.0.2:5678 \
    --dataplane-token-file=/kuma/token-demo \
    --dataplane-file=/kuma/dpyaml-demo \
    --dataplane-var name=dp-demo \
    --dataplane-var address=172.19.0.4 \
    --dataplane-var port=80  \
    --binary-path /usr/local/bin/envoy
```
