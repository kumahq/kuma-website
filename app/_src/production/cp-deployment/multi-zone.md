---
title: Deploy a multi-zone global control plane
content_type: how-to
---

## Prerequisites

To set up a multi-zone deployment we will need to:

- [Set up the global control plane](#set-up-the-global-control-plane)
- [Set up the zone control planes](#set-up-the-zone-control-planes)
- [Verify control plane connectivity](#verify-control-plane-connectivity)
- [Ensure mTLS is enabled for the multi-zone meshes](#ensure-mtls-is-enabled-on-the-multi-zone-meshes)

## Usage
### Set up the global control plane

{% if_version gte:2.2.x %}
The global control plane must run on a dedicated cluster (unless using "Universal on Kubernetes" mode), and cannot be assigned to a zone.
{% endif_version %}

{% if_version lte:2.1.x %}
The global control plane must run on a dedicated cluster, and cannot be assigned to a zone.
{% endif_version %}

{% tabs global-control-plane useUrlFragment=false %}
{% tab global-control-plane Kubernetes %}

The global control plane on Kubernetes must reside on its own Kubernetes cluster, to keep its resources separate from the resources the zone control planes create during synchronization.

1.  Run:

    ```sh
    kumactl install control-plane --mode=global | kubectl apply -f -
    ```

1.  Find the external IP and port of the `global-remote-sync` service in the `{{site.mesh_namespace}}` namespace:

    ```sh
    kubectl get services -n {{site.mesh_namespace}}
    NAMESPACE     NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                  AGE
    {{site.mesh_namespace}}   global-remote-sync     LoadBalancer   10.105.9.10     35.226.196.103   5685:30685/TCP                                                           89s
    {{site.mesh_namespace}}   {{site.mesh_cp_name}}     ClusterIP      10.105.12.133   <none>           5681/TCP,443/TCP,5676/TCP,5677/TCP,5678/TCP,5679/TCP,5682/TCP,5653/UDP   90s
    ```

    In this example the value is `35.226.196.103:5685`. You pass this as the value of `<global-kds-address>` when you set up the zone control planes.

{% endtab %}
{% tab global-control-plane Helm %}

1.  Set the `controlPlane.mode` value to `global` in the chart (`values.yaml`), then install. On the command line, run:

    ```sh
    helm install {{ site.mesh_helm_install_name }} --create-namespace --namespace {{site.mesh_namespace}} --set controlPlane.mode=global {{ site.mesh_helm_repo }}
    ```

    Or you can edit the chart and pass the file to the `helm install {{ site.mesh_helm_install_name }}` command. To get the default values, run:

    ```sh
    helm show values kuma/kuma
    ```

1.  Find the external IP and port of the `global-remote-sync` service in the `{{site.mesh_namespace}}` namespace:

    ```sh
    kubectl get services -n {{site.mesh_namespace}}
    NAMESPACE     NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                  AGE
    {{site.mesh_namespace}}   global-remote-sync     LoadBalancer   10.105.9.10     35.226.196.103   5685:30685/TCP                                                           89s
    {{site.mesh_namespace}}   {{site.mesh_cp_name}}     ClusterIP      10.105.12.133   <none>           5681/TCP,443/TCP,5676/TCP,5677/TCP,5678/TCP,5679/TCP,5682/TCP,5653/UDP   90s
    ```

    By default, it's exposed on [port 5685]({% if_version lte:2.1.x %}/docs/{{ page.version }}/networking/networking{% endif_version %}{% if_version gte:2.2.x %}/docs/{{ page.version }}/production/use-kuma#control-plane-ports{% endif_version %}). In this example the value is `35.226.196.103:5685`. You pass this as the value of `<global-kds-address>` when you set up the zone control planes.

{% endtab %}

{% if_version gte:2.2.x %}
{% tab global-control-plane Universal on Kubernetes using Helm %}

{% tip %}

Running global control plane in "Universal on Kubernetes" mode means using PostgreSQL as storage instead of Kubernetes.
It means that failover / HA / reliability characteristics will change.
Please read [Kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/) and
[PostgreSQL](https://www.postgresql.org/docs/current/high-availability.html) docs for more details.

{% endtip %}

1. Set `controlPlane.environment=universal` and `controlPlane.mode=global` in the chart (`values.yaml`).

1. Define Kubernetes secrets with database sensitive information

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: your-secret-name
   type: Opaque
   data:
     POSTGRES_DB: ...
     POSTGRES_HOST_RW: ...
     POSTGRES_USER: ...
     POSTGRES_PASSWORD: ...
   ```

1. Set `controlPlane.secrets` with database sensitive information

   ```yaml
   # ...
       secrets:
         postgresDb:
           Secret: your-secret-name
           Key: POSTGRES_DB
           Env: KUMA_STORE_POSTGRES_DB_NAME
         postgresHost:
           Secret: your-secret-name
           Key: POSTGRES_HOST_RW
           Env: KUMA_STORE_POSTGRES_HOST
         postgrestUser:
           Secret: your-secret-name
           Key: POSTGRES_USER
           Env: KUMA_STORE_POSTGRES_USER
         postgresPassword:
           Secret: your-secret-name
           Key: POSTGRES_PASSWORD
           Env: KUMA_STORE_POSTGRES_PASSWORD
   ```

1. Optionally set `postgres` with TLS settings

   ```yaml
     # Postgres' settings for universal control plane on k8s
     postgres:
       # -- Postgres port, password should be provided as a secret reference in "controlPlane.secrets"
       # with the Env value "KUMA_STORE_POSTGRES_PASSWORD".
       # Example:
       # controlPlane:
       #   secrets:
       #     - Secret: postgres-postgresql
       #       Key: postgresql-password
       #       Env: KUMA_STORE_POSTGRES_PASSWORD
       port: "5432"
       # TLS settings
       tls:
         # -- Mode of TLS connection. Available values are: "disable", "verifyNone", "verifyCa", "verifyFull"
         mode: disable # ENV: KUMA_STORE_POSTGRES_TLS_MODE
         # -- Whether to disable SNI the postgres `sslsni` option.
         disableSSLSNI: false # ENV: KUMA_STORE_POSTGRES_TLS_DISABLE_SSLSNI
         # -- Secret name that contains the ca.crt
         caSecretName:
         # -- Secret name that contains the client tls.crt, tls.key
         secretName:
   ```

1. Run helm install

    ```sh
    helm install {{ site.mesh_helm_install_name }} -f values.yaml --skip-crds --create-namespace --namespace {{site.mesh_namespace}} {{ site.mesh_helm_repo }}
    ```

1. Find the external IP and port of the `global-remote-sync` service in the `{{site.mesh_namespace}}` namespace:

    ```sh
    kubectl get services -n {{site.mesh_namespace}}
    NAMESPACE     NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                  AGE
    {{site.mesh_namespace}}   global-remote-sync     LoadBalancer   10.105.9.10     35.226.196.103   5685:30685/TCP                                                           89s
    {{site.mesh_namespace}}   {{site.mesh_cp_name}}     ClusterIP      10.105.12.133   <none>           5681/TCP,443/TCP,5676/TCP,5677/TCP,5678/TCP,5679/TCP,5682/TCP,5653/UDP   90s
    ```

    In this example the value is `35.226.196.103:5685`. You pass this as the value of `<global-kds-address>` when you set up the zone control planes.

{% endtab %}
{% endif_version %}

{% tab global-control-plane Universal %}

1.  Set up the global control plane, and add the `global` environment variable:

    ```sh
    KUMA_MODE=global kuma-cp run
    ```

{% endtab %}
{% endtabs %}

### Set up the zone control planes

You need the following values to pass to each zone control plane setup:

- `zone` -- the zone name. An arbitrary string. This value registers the zone control plane with the global control plane.
- `kds-global-address` -- the external IP and port of the global control plane.

{% tabs zone-control-planes useUrlFragment=false %}
{% tab zone-control-planes Kubernetes %}

**Without zone egress**:

1.  On each zone control plane, run:

    ```sh
    kumactl install control-plane \
    --mode=zone \
    --zone=<zone name> \
    --ingress-enabled \
    --kds-global-address grpcs://<global-kds-address>:5685 | kubectl apply -f -
    ```

    where `zone` is the same value for all zone control planes in the same zone.

**With zone egress**:

1.  On each zone control plane, run:

    ```sh
    kumactl install control-plane \
    --mode=zone \
    --zone=<zone-name> \
    --ingress-enabled \
    --egress-enabled \
    --kds-global-address grpcs://<global-kds-address>:5685 | kubectl apply -f -
    ```

    where `zone` is the same value for all zone control planes in the same zone.

{% endtab %}
{% tab zone-control-planes Helm %}

**Without zone egress**:

1.  On each zone control plane, run:

    ```sh
    helm install {{ site.mesh_helm_install_name }} \
    --create-namespace \
    --namespace {{site.mesh_namespace}} \
    --set controlPlane.mode=zone \
    --set controlPlane.zone=<zone-name> \
    --set ingress.enabled=true \
    --set controlPlane.kdsGlobalAddress=grpcs://<global-kds-address>:5685 {{ site.mesh_helm_repo }}
    ```

    where `controlPlane.zone` is the same value for all zone control planes in the same zone.

**With zone egress**:

1.  On each zone control plane, run:

    ```sh
    helm install {{ site.mesh_helm_install_name }} \
    --create-namespace \
    --namespace {{site.mesh_namespace}} \
    --set controlPlane.mode=zone \
    --set controlPlane.zone=<zone-name> \
    --set ingress.enabled=true \
    --set egress.enabled=true \
    --set controlPlane.kdsGlobalAddress=grpcs://<global-kds-address>:5685 {{ site.mesh_helm_repo }}
    ```

    where `controlPlane.zone` is the same value for all zone control planes in the same zone.

{% endtab %}
{% tab zone-control-planes Universal %}

1. On each zone control plane, run:

   ```sh
   KUMA_MODE=zone \
   KUMA_MULTIZONE_ZONE_NAME=<zone-name> \
   KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS=grpcs://<global-kds-address>:5685 \
   ./kuma-cp run
   ```

   where `KUMA_MULTIZONE_ZONE_NAME` is the same value for all zone control planes in the same zone.

2. Generate the zone proxy token:

   To register the zone ingress and zone egress with the zone control plane, we need to generate a token first

   ```sh
   kumactl generate zone-token --zone=<zone-name> --scope egress --scope ingress > /tmp/zone-token
   ```

   You can also generate the token {% if_version lte:2.1.x %}[with the REST API](/docs/{{ page.version }}/security/zoneproxy-auth){% endif_version%}{% if_version gte:2.2.x %}[with the REST API](/docs/{{ page.version }}/production/cp-deployment/zoneproxy-auth/){% endif_version%}.
   Alternatively, you could generate separate tokens for ingress and egress.

3. Create an `ingress` data plane proxy configuration to allow `kuma-cp` services to be exposed for cross-zone communication:

   ```sh
   echo "type: ZoneIngress
   name: ingress-01
   networking:
     address: 127.0.0.1 # address that is routable within the zone
     port: 10000
     advertisedAddress: 10.0.0.1 # an address which other zones can use to consume this zone-ingress
     advertisedPort: 10000 # a port which other zones can use to consume this zone-ingress" > ingress-dp.yaml
   ```

4. Apply the ingress config, passing the IP address of the zone control plane to `cp-address`:

   ```sh
   kuma-dp run \
   --proxy-type=ingress \
   --cp-address=https://<kuma-cp-address>:5678 \
   --dataplane-token-file=/tmp/zone-token \
   --dataplane-file=ingress-dp.yaml
   ```

   If zone-ingress is running on a different machine than zone-cp you need to
   copy CA cert file from zone-cp (located in `~/.kuma/kuma-cp.crt`) to somewhere accessible by zone-ingress (e.g. `/tmp/kuma-cp.crt`).
   Modify the above command and provide the certificate path in `--ca-cert-file` argument.

   ```sh
   kuma-dp run \
   --proxy-type=ingress \
   --cp-address=https://<kuma-cp-address>:5678 \
   --dataplane-token-file=/tmp/zone-token \
   --ca-cert-file=/tmp/kuma-cp.crt \
   --dataplane-file=ingress-dp.yaml
   ```

5.  Optional: if you want to deploy zone egress

    Create a `ZoneEgress` data plane proxy configuration to allow `kuma-cp` services
    to be configured to proxy traffic to other zones or external services through
    zone egress:

    ```sh
    echo "type: ZoneEgress
    name: zoneegress-01
    networking:
      address: 127.0.0.1 # address that is routable within the zone
      port: 10002" > zoneegress-dataplane.yaml
    ```

6. Apply the egress config, passing the IP address of the zone control plane to `cp-address`:

    ```sh
    kuma-dp run \
    --proxy-type=egress \
    --cp-address=https://<kuma-cp-address>:5678 \
    --dataplane-token-file=/tmp/zone-token \
    --dataplane-file=zoneegress-dataplane.yaml
    ```

    {% endtab %}
    {% endtabs %}

### Verify control plane connectivity

You can run `kumactl get zones`, or check the list of zones in the web UI for the global control plane, to verify zone control plane connections.

When a zone control plane connects to the global control plane, the `Zone` resource is created automatically in the global control plane.

The Zone Ingress tab of the web UI also lists zone control planes that you
deployed with zone ingress.

### Ensure mTLS is enabled on the multi-zone meshes

MTLS is mandatory to enable cross-zone service communication.
mTLS can be configured in your mesh configuration as indicated in the [mTLS section](/docs/{{ page.version }}/policies/mutual-tls).
This is required because {{site.mesh_product_name}} uses the [Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication) field, part of the TLS protocol, as a way to pass routing information cross zones.

### Cross-zone communication details

For this example we will assume we have a service running in a Kubernetes zone exposing a `kuma.io/service` with value `echo-server_echo-example_svc_1010`.
The following examples are running in the remote zone trying to access the previously mentioned service.

{% tabs cross-zone-communication-details useUrlFragment=false %}
{% tab cross-zone-communication-details Kubernetes %}

To view the list of service names available, run:

```sh
kubectl get serviceinsight all-services-default -oyaml
apiVersion: kuma.io/v1alpha1
kind: ServiceInsight
mesh: default
metadata:
  name: all-services-default
spec:
  services:
    echo-server_echo-example_svc_1010:
      dataplanes:
        online: 1
        total: 1
      issuedBackends:
        ca-1: 1
      status: online
```

The following are some examples of different ways to address `echo-server` in the
`echo-example` `Namespace` in a multi-zone mesh.

To send a request in the same zone, you can rely on Kubernetes DNS and use the usual Kubernetes hostnames and ports:

```sh
curl http://echo-server:1010
```

Requests are distributed round robin between zones.
You can use [locality-aware load balancing](/docs/{{ page.version }}/policies/locality-aware) to keep requests in the same zone.

To send a request to any zone, you can {% if_version lte:2.1.x %}[use the generated `kuma.io/service`](/docs/{{ page.version }}/explore/dpp-on-kubernetes#tag-generation){% endif_version %}{% if_version gte:2.2.x %}[use the generated `kuma.io/service`](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/#tag-generation){% endif_version %} and [{{site.mesh_product_name}} DNS](/docs/{{ page.version }}/networking/dns#dns):

```sh
curl http://echo-server_echo-example_svc_1010.mesh:80
```

{{site.mesh_product_name}} DNS also supports [RFC 1123](https://datatracker.ietf.org/doc/html/rfc1123) compatible names, where underscores are replaced with dots:

```sh
curl http://echo-server.echo-example.svc.1010.mesh:80
```

{% endtab %}
{% tab cross-zone-communication-details Universal %}

```sh
kumactl inspect services
SERVICE                                  STATUS               DATAPLANES
echo-service_echo-example_svc_1010       Online               1/1

```

To consume the service in a Universal deployment without transparent proxy add the following outbound to your {% if_version lte:2.1.x %}[dataplane configuration](/docs/{{ page.version }}/explore/dpp-on-universal){% endif_version %}{% if_version gte:2.2.x %}[dataplane configuration](/docs/{{ page.version }}/production/dp-config/dpp-on-universal/){% endif_version %}:

```yaml
outbound:
  - port: 20012
    tags:
      kuma.io/service: echo-server_echo-example_svc_1010
```

From the data plane running you will now be able to reach the service using `localhost:20012`.

Alternatively, if you configure {% if_version lte:2.1.x %}[transparent proxy](/docs/{{ page.version }}/networking/transparent-proxying){% endif_version %}{% if_version gte:2.2.x %}[transparent proxy](/docs/{{ page.version }}/production/dp-config/transparent-proxying/){% endif_version %} you can just call `echo-server_echo-example_svc_1010.mesh` without defining an `outbound` section.

{% endtab %}
{% endtabs %}

{% tip %}
For security reasons it's not possible to customize the `kuma.io/service` in Kubernetes.

If you want to have the same service running on both Universal and Kubernetes make sure to align the Universal's data plane inbound to have the same `kuma.io/service` as the one in Kubernetes or leverage [TrafficRoute](/docs/{{ page.version }}/policies/traffic-route).
{% endtip %}

## Delete a zone

To delete a `Zone` we must first shut down the corresponding {{site.mesh_product_name}} zone control plane instances. As long as the Zone CP is running this will not be possible, and {{site.mesh_product_name}} returns a validation error like:

```
zone: unable to delete Zone, Zone CP is still connected, please shut it down first
```

When the Zone CP is fully disconnected and shut down, then the `Zone` can be deleted. All corresponding resources (like `Dataplane` and `DataplaneInsight`) will be deleted automatically as well.

{% tabs delete-zone useUrlFragment=false %}
{% tab delete-zone Kubernetes %}

```sh
kubectl delete zone zone-1
```

{% endtab %}
{% tab delete-zone Universal %}

```sh
kumactl delete zone zone-1
```

{% endtab %}
{% endtabs %}

## Disable a zone

Change the `enabled` property value to `false` in the global control plane:

{% tabs disable-zone useUrlFragment=false %}
{% tab disable-zone Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Zone
metadata:
  name: zone-1
spec:
  enabled: false
```

{% endtab %}
{% tab disable-zone Universal %}

```yaml
type: Zone
name: zone-1
spec:
  enabled: false
```

{% endtab %}
{% endtabs %}

With this setting, the global control plane will stop exchanging configuration with this zone.
As a result, the zone's ingress from zone-1 will be deleted from other zone and traffic won't be routed to it anymore.
The zone will show as **Offline** in the GUI and CLI.
