---
title: Zone Ingress
content_type: how-to
description: Configure ZoneIngress proxies to enable cross-zone communication in multi-zone deployments.
keywords:
  - ZoneIngress
  - multi-zone
  - cross-zone
---

To implement cross-zone communication when {{site.mesh_product_name}} is deployed in a [multi-zone](/docs/{{ page.release }}/production/deployment/multi-zone/) mode, there is a new proxy type `ZoneIngress`.
These proxies are not attached to any particular workload. Instead, they are bound to that particular zone.
Zone Ingress can proxy the traffic between all meshes, so we need only one deployment in each zone.  
All requests that are sent from one zone to another will be directed to the proper instance by the Zone Ingress.

{%tip%}
Because `ZoneIngress` uses [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) to route traffic, [mTLS](/docs/{{ page.release }}/policies/mutual-tls) is required to do cross zone communication.
{%endtip%}

The `ZoneIngress` entity includes a few sections:

* `type`: must be `ZoneIngress`.
* `name`: this is the name of the Zone Ingress instance, and it must be **unique** for any given `zone`.
* `networking`: contains networking parameters of the Zone Ingress
    * `address`: the address of the network interface Zone Ingress is listening on. Could be the address of either
      public or private network interface, but the latter must be used with a load balancer.
    * `port`: is a port that Zone Ingress is listening on default to 10001
    * `advertisedAddress`: an IP address or hostname which will be used to communicate with the Zone Ingress. Zone Ingress
      doesn't listen on this address. If Zone Ingress is exposed using a load balancer, then the address of the load balancer
      should be used here. If Zone Ingress is listening on the public network interface, then the address of the public network
      interface should be used here.
    * `advertisedPort`: a port which will be used to communicate with the Zone Ingress. Zone Ingress doesn't listen on this port.
    * `admin`: determines parameters related to Envoy Admin API
      * `port`: the port that Envoy Admin API will listen to
* `availableServices` **[auto-generated on {{site.mesh_product_name}} CP]** : the list of services that could be consumed through the Zone Ingress
* `zone` **[auto-generated on {{site.mesh_product_name}} CP]** : zone where Zone Ingress is running 

Zone Ingress without `advertisedAddress` and `advertisedPort` is not taken into account when generating Envoy configuration, because they cannot be accessed by data plane proxies from other zones.

{% tabs %}
{% tab Kubernetes %}
To install `ZoneIngress` in Kubernetes when doing `kumactl install control-plane` use the `--ingress-enabled`. If using helm add `{{site.set_flag_values_prefix}}ingress.enabled: true` to your `values.yaml`.

{{site.mesh_product_name}} will set `advertisedAddress` and `advertisedPort` automatically by checking the Service associated with this Zone Ingress.

If the Service type is Load Balancer, {{site.mesh_product_name}} will wait for public IP to be resolved. It may take a couple of minutes to receive public IP depending on the LB implementation of your Kubernetes provider.
If the Service type is Node Port, {{site.mesh_product_name}} will take an External IP of the first Node in the cluster and combine it with Node Port.

You can provide your own public address and port using the following annotations on the Ingress deployment:
* `kuma.io/ingress-public-address`
* `kuma.io/ingress-public-port`

{% endtab %}
{% tab Universal %}

In Universal mode, the token is required to authenticate `ZoneIngress` instance. Create the token by using `kumactl` binary:

```bash
kumactl generate zone-token --valid-for 720h --scope ingress > /path/to/token
```

Create a `ZoneIngress` configuration to allow services to receive traffic from other zones:

```yaml
type: ZoneIngress
name: zoneingress-1
networking:
  address: 192.168.0.1
  port: 10001
  advertisedAddress: 10.0.0.1 # Adapt to the address of the Load Balancer in front of your ZoneIngresses
  advertisedPort: 10001 # Adapt to the port of the Load Balancer in front of you ZoneIngresses
```

Apply the ingress configuration, passing the IP address of the control plane and your instance should start.

```bash
kuma-dp run \
--proxy-type=ingress \
--cp-address=https://<kuma-cp-address>:5678 \
--dataplane-token-file=/path/to/token \
--dataplane-file=/path/to/config
```

{% endtab %}
{% endtabs %}

A `ZoneIngress` deployment can be scaled horizontally. Many instances can have the same advertised address and advertised port because they can be put behind one load balancer.
