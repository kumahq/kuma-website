---
title: Deploy a single-zone control plane
content_type: how-to
---

In order to deploy {{site.mesh_product_name}} in a single-zone deployment, the `kuma-cp` control plane must be started in `zone` mode:

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}
This is the standard installation method. After the installation, make sure to restart application pods that are  running such that the data plane objects can be generated and the proxies can be connected.
{% cpinstall cpsinglezone %}
controlPlane.mode=zone
{% endcpinstall %}

**With zone egress**:

It's possible to run [`ZoneEgress`](/docs/{{ page.release }}/production/cp-deployment/zoneegress/) for single-zone deployment. In order to deploy {{site.mesh_product_name}} with `ZoneEgress` run the install command with an additional parameter.
{% cpinstall cpsinglezone-egress %}
controlPlane.mode=zone
egress.enabled=true
{% endcpinstall %}

{% endtab %}
{% tab usage Universal %}

{% tip %}
When running a control plane in Universal mode, a database must be used to persist state for production deployments.
Ensure that migrations have been run against the database prior to running the control plane.
{% endtip %}

This is the standard installation method. 
```sh
KUMA_STORE_TYPE=postgres \
KUMA_STORE_POSTGRES_HOST=<postgres-host> \
KUMA_STORE_POSTGRES_PORT=<postgres-port> \
KUMA_STORE_POSTGRES_USER=<postgres-user> \
KUMA_STORE_POSTGRES_PASSWORD=<postgres-password> \
KUMA_STORE_POSTGRES_DB_NAME=<postgres-db-name> \
kuma-cp run
```

**With zone egress**:

`ZoneEgress` works for Universal deployment as well. In order to deploy `ZoneEgress` for Universal deployment [follow the instruction](/docs/{{ page.release }}/production/cp-deployment/zoneegress).

{% endtab %}
{% endtabs %}

Once {{site.mesh_product_name}} is up and running, data plane proxies can now [connect](/docs/{{ page.release }}/production/dp-config/dpp/) directly to it.

{% tip %}
When the mode is not specified, {{site.mesh_product_name}} will always start in `zone` mode by default.
{% endtip %}

### Optional: control plane authentication

Running administrative tasks (like generating auth tokens) requires [authentication by token](/docs/{{ page.release }}/production/secure-deployment/api-server-auth/#admin-user-token) or a connection via localhost when interacting with the control plane.

{% tabs auth useUrlFragment=false %}
{% tab auth Kubernetes %}
You can authenticate by port-forwarding API service and extracting admin user token.

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681

export ADMIN_TOKEN=$(kubectl get secrets -n {{site.mesh_namespace}} admin-user-token -ojson | jq -r .data.value | base64 -d)

kumactl config control-planes add \
--address http://localhost:5681 \
--headers "authorization=Bearer $ADMIN_TOKEN" \
--name "zone-cp" \
--overwrite
```
{% endtab %}
{% tab auth Universal on Docker %}
##### Localhost authentication

For `kuma-cp` to recognize requests issued to docker published port it needs to run the container in the host network.
To do this, add `--network="host"` parameter to the `docker run` command.

##### Authenticate via token

You can also configure `kumactl` to access `kuma-dp` from the container.
Get the `kuma-cp` container id:

```sh
docker ps # copy kuma-cp container id

export KUMA_CP_CONTAINER_ID='...'
```

Configure `kumactl`:

```sh
TOKEN=$(bash -c "docker exec -it $KUMA_CP_CONTAINER_ID wget -q -O - http://localhost:5681/global-secrets/admin-user-token" | jq -r .data | base64 -d)

kumactl config control-planes add \
 --name my-control-plane \
 --address http://localhost:5681 \
 --auth-type=tokens \
 --auth-conf token=$TOKEN \
 --skip-verify
```
{% endtab %}
{% endtabs %}

## Moving to a multi-zone deployment

You can transform a single-zone deployment into a multi-zone deployment by doing [federation](/docs/{{ page.release }}/guides/federate). 
