---
title: Deploy a standalone control plane
content_type: how-to
description: Deploy a standalone control plane for simple service mesh deployments in a single cluster or environment.
keywords:
  - standalone
  - deployment
  - control plane
---

In order to deploy {{site.mesh_product_name}} in a standalone deployment, the `kuma-cp` control plane must be started in `standalone` mode:

{% tabs %}
{% tab Kubernetes %}
This is the standard installation method. 
{% cpinstall cpstandalone %}
controlPlane.mode=standalone
{% endcpinstall %}

**With zone egress**:

It's possible to run [`ZoneEgress`](/docs/{{ page.release }}/production/cp-deployment/zoneegress/) for standalone deployment. In order to deploy {{site.mesh_product_name}} with `ZoneEgress` run the install command with an additional parameter.
{% cpinstall cpstandalone-egress %}
controlPlane.mode=standalone
egress.enabled=true
{% endcpinstall %}

{% endtab %}
{% tab Universal %}

{% tip %}
When running the standalone control plane in Universal mode, a database must be used to persist state for production deployments.
Ensure that migrations have been run against the database prior to running the standalone control plane.
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
When the mode is not specified, {{site.mesh_product_name}} will always start in `standalone` mode by default.
{% endtip %}

#### Optional: control plane authentication

Running administrative tasks (like generating a dataplane token) requires [authentication by token](/docs/{{ page.release }}/production/secure-deployment/api-server-auth/#admin-user-token) or a connection via localhost when interacting with the control plane.

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
