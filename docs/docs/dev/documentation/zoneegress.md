# Zone Egress

When Kuma is deployed as [standalone](../deployments/stand-alone.md) or in [multi-zone](../deployments/multi-zone.md),
and you want to achieve isolation of outgoing traffic (to services in other 
zones or [external services](../policies/external-services.md) in the local zone),
you can use `ZoneEgress` proxy.

This proxy is not attached to any particular workload. Instead, it's bound to
that particular zone. In the case of standalone mode, there is only the default zone that Kuma is running in.

When Zone Egress is present in the zone:
* All requests that are sent from local data plane proxies to the ones in other
  zones will be directed through the local Zone Egress instance, which then will
  direct the traffic to the proper instance of the Zone Ingress.
* All requests that are sent from local data plane proxies to [external services](../policies/external-services.md)
  available within the Zone will be directed through the local Zone Egress
  instance.

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

**Standalone**:

```shell
kumactl install control-plane \
  --egress-enabled \
  [...] | kubectl apply -f -
```

**Multi-zone**:

```shell
kumactl install control-plane \
  --mode=zone \
  --egress-enabled \
  [...] | kubectl apply -f -
```

:::
::: tab "Universal"

**Standalone**

In Universal mode, the token is required to authenticate `ZoneEgress` instance. Create the token by using `kumactl` binary:

```bash
kumactl generate zone-token --valid-for --scope egress > /path/to/token
```

Create a `ZoneEgress` data plane proxy configuration to allow `kuma-cp` services to be configured to proxy traffic to other zones or external services through zone egress:

```yaml
type: ZoneEgress
name: zoneegress-1
networking:
  address: 192.168.0.1
  port: 10002
```

Apply the egress configuration, passing the IP address of the control plane and your instance should start.

```bash
kuma-dp run \
--proxy-type=egress \
--cp-address=https://<kuma-cp-address>:5678 \
--dataplane-token-file=/path/to/token \
--dataplane-file=/path/to/config
```

**Multi-zone**

Multi-zone deployment is similar and for deployment, you should follow [multi-zone deployment instruction](../deployments/multi-zone.md).

:::
::::

A `ZoneEgress` deployment can be scaled horizontally.

## Configuration

`ZoneEgress` won't work if there is no [mTLS enabled](../policies/mutual-tls.md). In this case it is necessary to enable secured communication.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

**Standalone**:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

**Multi-zone**:

In multi-zone deployment, the same configuration as for standalone needs to be applied to the global control plane.
:::
::: tab "Universal"

```shell
cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin
EOF
```
:::
::::


After configuration change you should be able to communicate with services in other zone or external services and traffic should be routed through `ZoneEgress`. 



