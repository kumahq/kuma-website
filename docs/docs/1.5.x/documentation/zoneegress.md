# Zone Egress

When Kuma is deployed in [multi-zone](../deployments/multi-zone.md),
and you want to achieve isolation of outgoing traffic (to services in other 
zones or [external services](../policies/external-services.md) in the local zone),
you can use `ZoneEgress` proxy.

This proxy is not attached to any particular workload. Instead, it's bound to
that particular zone.

When Zone Egress is present in the zone:
* All requests that are sent from local data plane proxies to the ones in other
  zones will be directed through the local Zone Egress instance, which then will
  direct the traffic to the proper instance of the Zone Ingress.
* All requests that are sent from local data plane proxies to [external services](../policies/external-services.md)
  available within the Zone will be directed through the local Zone Egress
  instance.

:::tip
Currently `ZoneEgress` is a purely optional component.
In the future it will become compulsory for using external services.
:::

The `ZoneEgress` entity includes a few sections:

* `type`: must be `ZoneEgress`.
* `name`: this is the name of the `ZoneEgress` instance, and it must be **unique**
   for any given `zone`.
* `networking`: contains networking parameters of the Zone Egress
    * `address`: the address of the network interface Zone Egress is listening on.
    * `port`: is a port that Zone Egress is listening on
    * `admin`: determines parameters related to Envoy Admin API
      * `port`: the port that Envoy Admin API will listen to
* `zone` **[auto-generated on Kuma CP]** : zone where Zone Egress belongs to

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
The recommended way to deploy a `ZoneEgress` proxy in Kubernetes is to use
`kumactl`, or the Helm charts as specified in [multi-zone](../deployments/multi-zone.md).
It works as a separate deployment of a single-container pod.

```shell
kumactl install control-plane \
  --mode=zone \
  --egress-enabled \
  [...] | kubectl apply -f -
```

:::
::: tab "Universal"

In Universal mode the dataplane resource should be deployed as follows:

```yaml
type: ZoneEgress
name: zoneegress-1
networking:
  address: 192.168.0.1
  port: 10002
```
:::
::::

A `ZoneEgress` deployment can be scaled horizontally.
