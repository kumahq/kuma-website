# Set up a multi-zone deployment

For a description of how multi-zone deployments work in Kuma, see [about multi-zone deployments](/how-multi-zone-works). This page explains how to configure and deploy Kuma in a multi-zone environment:

- Set up the global control plane
- Set up the remote control planes
- Verify control plane connectivity
- Enable mTLS and apply the appropriate Traffic Permission policy
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

    You can also generate the token [with the REST API](/security/certificates/#data-plane-proxy-to-control-plane-communication). 

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

When a remote control plane connects to the global control plane, the `Zone` resource is created automatically in the global control plane.
You can verify if a remote control plane is connected to the global control plane by inspecting the list of zones in the global control plane GUI (`:5681/gui/#/zones`) or by using `kumactl get zones`. 

Additionally, if you deployed remote control plane with Ingress, it should be visible in the Ingress tab of the GUI.
Cross-zone communication between services is only available if Ingress has a public address and public port.
Note that on Kubernetes, Kuma automatically tries to pick up the public address and port. Depending on the LB implementation of your Kubernetes provider, you may need to wait a couple of minutes to receive the address. 

## Enable mTLS

Cross-zone communication between services is only possible when mTLS is enabled, because Ingress is routing connections using SNI.
Make sure you [enable mTLS](../policies/mutual-tls.md) and apply [Traffic Permission](../policies/traffic-permissions.md). 

## Set up cross-zone communication

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"

To figure out the service names that we can use in the applications for cross-zone communication, we can look at the 
service tag in the deployed data plane proxies: 

```bash
$ kubectl get dataplanes -n echo-example -o yaml | grep service
           service: echo-server_echo-example_svc_1010
```

On Kubernetes, Kuma uses transparent proxy. In this mode, `kuma-dp` is listening on port 80 for all the virtual IPs that 
Kuma DNS assigns to services in the `.mesh` DNS zone. It also provides an RFC compatible DNS name where the underscores in the
service are replaced by dots. Therefore, we have the following ways to consume a service from within the mesh:

```bash
<kuma-enabled-pod>$ curl http://echo-server:1010
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh:80
<kuma-enabled-pod>$ curl http://echo-server.echo-example.svc.1010.mesh:80
<kuma-enabled-pod>$ curl http://echo-server_echo-example_svc_1010.mesh
<kuma-enabled-pod>$ curl http://echo-server.echo-example.svc.1010.mesh
```
The first method still works, but is limited to endpoints implemented within the same Kuma zone (i.e. the same Kubernetes cluster).
The second and third options allow to consume a service that is distributed across the Kuma cluster (bound by the same `global` control plane). For
example there can be an endpoint running in another Kuma zone in a different data-center.

Since most HTTP clients (such as `curl`) will default to port 80, the port can be omitted, like in the fourth and fifth options above.
:::
::: tab "Universal"

In hybrid (Kubernetes and Universal) deployments, the service tag should be the same in both environments (e.g `echo-server_echo-example_svc_1010`)

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

If a multi-zone Universal control plane is used, the service tag has no such limitation.

And to consume the distributed service from a Universal deployment, where the application will use `http://localhost:20012`.

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

::: tip
The Kuma DNS service format (e.g. `echo-server_kuma-test_svc_1010.mesh`) is a composition of Kubernetes Service Name (`echo-server`),
Namespace (`kuma-test`), a fixed string (`svc`), the service port (`1010`). The service is resolvable in the DNS zone `.mesh` where
the Kuma DNS service is hooked.
:::

### Deleting a Zone

To delete a `Zone` we must first shut down the corresponding Kuma Remote CP instances. As long as the Remote CP is running this will not be possible, and Kuma will return a validation error like:

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
