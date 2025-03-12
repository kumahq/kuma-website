---
title: Zone Egress
content_type: how-to
---

`ZoneEgress` proxy is used when it is required to isolate outgoing traffic (to services in other
zones or [external services](/docs/{{ page.release }}/policies/external-services) in the local zone).


{%tip%}
Because `ZoneEgress` uses [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) to route traffic, [mTLS](/docs/{{ page.release }}/policies/mutual-tls) is required.
{%endtip%}

This proxy is not attached to any particular workload. In multi-zone the proxy is bound to a specific zone.
Zone Egress can proxy the traffic between all meshes, so we need only one deployment for every zone.

When Zone Egress is present:
* In multi-zone, all requests that are sent from local data plane proxies to other
  zones will be directed through the local Zone Egress instance, which then will
  direct the traffic to the proper instance of the Zone Ingress.
* All requests that are sent from local data plane proxies to [external services](/docs/{{ page.release }}/policies/external-services)
  available within the Zone will be directed through the local Zone Egress
  instance.

{% tip %}
Currently `ZoneEgress` is a purely optional component.
In the future it will become compulsory for using external services.
{% endtip %}

The `ZoneEgress` entity includes a few sections:

* `type`: must be `ZoneEgress`.
* `name`: this is the name of the `ZoneEgress` instance, and it must be **unique**
   for any given `zone`.
* `networking`: contains networking parameters of the Zone Egress
    * `address`: the address of the network interface Zone Egress is listening on.
    * `port`: is a port that Zone Egress is listening on
    * `admin`: determines parameters related to Envoy Admin API
      * `port`: the port that Envoy Admin API will listen to
* `zone` **[auto-generated on {{site.mesh_product_name}} CP]** : zone where Zone Egress belongs to

{% tabs %}
{% tab Kubernetes %}
To install `ZoneEgress` in Kubernetes when doing `kumactl install control-plane` use the `--egress-enabled`. If using helm add `{{site.set_flag_values_prefix}}egress.enabled: true` to your `values.yaml`.

{% endtab %}
{% tab Universal %}

In Universal mode, the token is required to authenticate `ZoneEgress` instance. Create the token by using `kumactl` binary:

```bash
kumactl generate zone-token --valid-for 720h --scope egress > /path/to/token
```

Create a `ZoneEgress` data plane proxy configuration to allow `kuma-cp` services to be configured to proxy traffic to other zones or external services through `ZoneEgress`:

```yaml
type: ZoneEgress
name: zoneegress-1
networking:
  address: 192.168.0.1
  port: 10002
```

Apply the `ZoneEgress` configuration, passing the IP address of the control plane and your instance should start.

```bash
kuma-dp run \
--proxy-type=egress \
--cp-address=https://<kuma-cp-address>:5678 \
--dataplane-token-file=/path/to/token \
--dataplane-file=/path/to/config
```

{% endtab %}
{% endtabs %}


A `ZoneEgress` deployment can be scaled horizontally.

In addition to MTLS, there's a configuration in the `Mesh` policy to route traffic through the `ZoneEgress`

{% tabs %}
{% tab Kubernetes %}

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    zoneEgress: true
  mtls: # mTLS is required to use ZoneEgress
    [...]" | kubectl apply -f -
```

{% endtab %}
{% tab Universal %}

```shell
cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls: # mTLS is required to use ZoneEgress
  [...]
routing:
  zoneEgress: true
EOF
```

{% endtab %}
{% endtabs %}

This configuration will force cross zone communication and external services to go through `ZoneEgress`.
If enabled but no `ZoneEgress` is available the communication will fail.
