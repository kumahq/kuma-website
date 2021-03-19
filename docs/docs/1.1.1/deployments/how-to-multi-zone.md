# Set up a multi-zone deployment

For a description of how multi-zone deployments work in Kuma, see [about multi-zone deployments](../how-multi-zone-works). This page explains how to configure and deploy Kuma in a multi-zone environment:

- Set up the global control plane
- Set up the remote control planes
- Verify control plane connectivity
- Set up cross-zone communication between data plane proxies

Before you start you should determine the zone names to use. You must assign the same `zone` value to every remote control plane you want to run in the same zone. This value is an arbitrary string.

## Set up the global control plane

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

The global control plane on Kubernetes must reside on its own Kubernetes cluster, to keep its CRDs separate from the CRDs the remote control planes create during synchronization.

Run:

```bash
$ kumactl install control-plane --mode=global | kubectl apply -f -
```

Find the external IP and port of the `global-remote-sync` service in the `kuma-system` namespace:

```bash
$ kubectl get services -n kuma-system
NAMESPACE     NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                  AGE
kuma-system   global-remote-sync     LoadBalancer   10.105.9.10     35.226.196.103   5685:30685/TCP                                                           89s
kuma-system   kuma-control-plane     ClusterIP      10.105.12.133   <none>           5681/TCP,443/TCP,5676/TCP,5677/TCP,5678/TCP,5679/TCP,5682/TCP,5653/UDP   90s
```

In this example the value is `35.226.196.103:5685`. You pass this as the value of `global-kds-address` when you set up the remote control planes.

:::
::: tab "Helm"

Set the `controlPlane.mode` value to `global` in the chart, then install. On the command line, run:

```sh
$ helm install kuma --namespace kuma-system --set controlPlane.mode=global kuma/kuma
```

Or you can edit the chart and pass the file to the `helm install kuma` command.

REVIEWER: IS THIS CLEARER? OR HAVE I GOTTEN THINGS WRONG/MORE OBSCURE?

:::
::: tab "Universal"

Set up the global control plane, and add the `global` environment variable:

```sh
$ KUMA_MODE=global kuma-cp run
```

:::
::::

## Set up the remote control planes

You need the following values to pass to each remote control plane setup:

- `zone` -- the zone name. An arbitrary string. This value registers the remote control plane with the global control plane.
- `kds-global-address` -- the external IP and port of the global control plane.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

On each remote control plane, run:

```sh
$ kumactl install control-plane \
  --mode=remote \
  --zone=<zone name> \
  --ingress-enabled \
  --kds-global-address grpcs://`<global-kds-address>` | kubectl apply -f -
```

where `zone` is the same value for all remote control planes in the same zone.

Then install Kuma DNS:

```sh
$ kumactl install dns | kubectl apply -f -
```

Kuma supports CoreDNS and kube-dns. Make sure to check your cluster configuration for expected behavior after you deploy the remote control plane.

:::
::: tab "Helm"

On each remote control plane, run:

```bash
$ helm install kuma \
  --namespace kuma-system \
  --set controlPlane.mode=remote \
  controlPlane.zone=<zone-name> \
  ingress.enabled=true \
  controlPlane.kdsGlobalAddress=grpcs://<global-kds-address> kuma/kuma
```

where `controlPlane.zone` is the same value for all remote control planes in the same zone.

Then install Kuma DNS:

```sh
$ kumactl install dns | kubectl apply -f -
```

Kuma supports CoreDNS and kube-dns. Make sure to check your cluster configuration for expected behavior after you deploy the remote control plane.

You must install DNS with `kumactl` because it reads the state of the control plane, which Helm does not support. You can [check out the issue to include it](https://github.com/kumahq/kuma/issues/1124).

:::
::: tab "Universal"

1.  On each remote control plane, run:

    ```sh
    $ KUMA_MODE=remote \
      KUMA_MULTIZONE_REMOTE_ZONE=<zone-name> \
      KUMA_MULTIZONE_REMOTE_GLOBAL_ADDRESS=grpcs://<global-kds-address> \
      ./kuma-cp run
    ```

    where `KUMA_MULTIZONE_REMOTE_ZONE` is the same value for all remote control planes in the same zone.

1.  Generate the data plane proxy token:

    ```sh
    $ kumactl generate dataplane-token --type=ingress > /tmp/ingress-token
    ```

    You can also generate the token [with the REST API](../security/certificates/#data-plane-proxy-to-control-plane-communication). 

1.  Create an `ingress` data plane proxy configuration to allow `kuma-cp` services to be exposed for cross-zone communication: 

    ```bash
    $ echo "type: Dataplane
    mesh: default
    name: ingress-01
    networking:
      address: 127.0.0.1 # address that is routable within the zone
      ingress:
        publicAddress: 10.0.0.1 # an address which other zones can use to consume this ingress
        publicPort: 10000 # a port which other zones can use to consume this ingress
      inbound:
      - port: 10000
        tags:
          kuma.io/service: ingress" > ingress-dp.yaml
    ```

1.  And run the following to apply the ingress config, passing the IP address of the remote control plane to `cp-address`:

    ```
    $ kuma-dp run \
      --cp-address=https://<kuma-cp-address>:5678 \
      --dataplane-token-file=/tmp/ingress-token \
      --dataplane-file=ingress-dp.yaml 
    ```
:::
::::

## Verify control plane connectivity

You can run `kumactl get zones`, or check the list of zones in the web UI for the global control plane, to verify remote control plane connections.

When a remote control plane connects to the global control plane, the `Zone` resource is created automatically in the global control plane.

The Ingress tab of the web UI also lists remote control planes that you deployed with Ingress. 

## Set up cross-zone communication

### Enable mTLS

You must [enable mTLS](../policies/mutual-tls.md) for cross-zone communication between services.

Cross-zone communication between services rqeuires mTLS because Ingress routes connections with SNI.

### Apply TrafficPermission policy

You must also apply a [TrafficPermission policy](../policies/traffic-permissions.md). Traffic permissions also require enabling mTLS. Kuma creates a default `TrafficPermission` policy that allows all the communication between all the services when a new `Mesh` is created. You should take care to create appropriate policies to restrict traffic between services. 

### Ingress requirements

Cross-zone communication between services is available only if Ingress has a public address and public port.

On Kubernetes, Kuma automatically tries to pick up the public address and port. Depending your load balancing implementation, you might need to wait a couple of minutes for Kuma to get the address. 

### Cross-communication details

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

To view the list of service names available for cross-zone communication, run:

```bash
$ kubectl get dataplanes -n echo-example -o yaml | grep service
           service: echo-server_echo-example_svc_1010
```

To consume the example service only within the same Kuma zone, you can run:

```bash
<kuma-enabled-pod>$ curl http://echo-server:1010
```

To consume the example service across all zones in your Kuma deployment (that is, from endpoints ultimately connecting to the same global control plane), you can run either of:

```bash
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh:80
<kuma-enabled-pod>$ curl http://echo-server.echo-example.svc.1010.mesh:80
```

And if your HTTP clients take the standard default port 80, you can skip that value and run either of:

```bash
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh
<kuma-enabled-pod>$ curl http://echo-server.echo-example.svc.1010.mesh
```

Because Kuma on Kubernetes relies on transparent proxy, `kuma-dp` listens on port 80 for all virtual IPs thet are assigned to services in the `.mesh` DNS zone. The DNS names are rendered RFC compatible by replacing underscores with dots.

:::
::: tab "Universal"

With a hybrid deployment, running in both Kubernetes and Universal mode, the service tag should be the same in both environments (e.g `echo-server_echo-example_svc_1010`):

```yaml
type: Dataplane
mesh: default
name: backend-02 
networking:
  address: 127.0.0.1
  inbound:
  - port: 2010
    servicePort: 1010
    tags:
      kuma.io/service: echo-server_echo-example_svc_1010
```

With a Universal control plane, the service tag has no such limitation.

REVIEWER: DOES THIS ^ APPLY TO A HYBRID ENVIRONMENT WHERE THE CONTROL PLANE RUNS IN UNIVERSAL MODE? DOES THIS REFER TO THE GLOBAL CONTROL PLANE? CAN WE CLARIFY THE DISTINCTION BETWEEN THESE TWO CASES (THAT IS, THE HYBRID AND THIS SECOND CASE WHICH MIGHT OR MIGHT NOT BE RELEVANT TO THE FIRST ONE)?

To consume a distributed service in a Universal deployment, where the application address is `http://localhost:20012`:

```yaml
type: Dataplane
mesh: default
name: web-02 
networking:
  address: 127.0.0.1
  inbound:
  - port: 10000
    servicePort: 10001
    tags:
      kuma.io/service: web
  outbound:
  - port: 20012
    tags:
      kuma.io/service: echo-server_echo-example_svc_1010
```

:::
::::

The Kuma DNS service format (e.g. `echo-server_kuma-test_svc_1010.mesh`) is a composition of Kubernetes Service Name (`echo-server`),
Namespace (`kuma-test`), a fixed string (`svc`), the service port (`1010`). The service is resolvable in the DNS zone `.mesh` where
the Kuma DNS service is hooked.

### Deleting a Zone

REVIEWER: CANNOT TELL WHAT THE COMMANDS ARE THAT YOU RUN, AND IN WHAT ORDER. THIS SECTION NEEDS MUCH HELP, PLEASE!

To delete a `Zone` we must first shut down the corresponding Kuma remote control plane instances. As long as the Remote CP is running this will not be possible, and Kuma returns a validation error like:

```
zone: unable to delete Zone, Remote CP is still connected, please shut it down first
```

When the Remote CP is fully disconnected and shut down, then the `Zone` can be deleted. All corresponding resources (like `Dataplane` and `DataplaneInsight`) will be deleted automatically as well.

### Disabling zone

In order to disable routing traffic to a specific `Zone`, we can disable the `Zone` via the `enabled` field:

```yaml
type: Zone
name: zone-1
spec:
  enabled: true
```

Changing this value to `enabled: false` will allow the user to exclude the zone's `Ingress` from all other zones - and by doing so - preventing traffic from being able to enter the `zone`. 

:::tip
A `Zone` that has been disabled will show up as "Offline" in the GUI and CLI
:::
