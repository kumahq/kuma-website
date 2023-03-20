---
title: Deploy a standalone control plane
content_type: how-to
---

In order to deploy {{site.mesh_product_name}} in a standalone deployment, the `kuma-cp` control plane must be started in `standalone` mode:

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}
This is the standard installation method as described in the [installation page](/install).
```sh
kumactl install control-plane | kubectl apply -f -
```

**With zone egress**:

It's possible to run {% if_version lte:2.1.x %}[`ZoneEgress`](/docs/{{ page.version }}/explore/zoneegress){% endif_version %}{% if_version gte:2.2.x %}[`ZoneEgress`](/docs/{{ page.version }}/production/cp-deployment/zoneegress/){% endif_version %} for standalone deployment. In order to deploy {{site.mesh_product_name}} with `ZoneEgress` run the install command with an additional parameter.
```sh
kumactl install control-plane --egress-enabled | kubectl apply -f -
```
{% endtab %}
{% tab usage Universal %}
This is the standard installation method as described in the [installation page](/install).
```sh
kuma-cp run
```

**With zone egress**:

`ZoneEgress` works for Universal deployment as well. In order to deploy `ZoneEgress` for Universal deployment {% if_version lte:2.1.x %}[follow the instruction](/docs/{{ page.version }}/explore/zoneegress#zone-egress){% endif_version %}{% if_version gte:2.2.x %}[follow the instruction](/docs/{{ page.version }}/production/cp-deployment/zoneegress/#zone-egress){% endif_version %}.

{% endtab %}
{% endtabs %}

Once {{site.mesh_product_name}} is up and running, data plane proxies can now {% if_version lte:2.1.x %}[connect](/docs/{{ page.version }}/explore/dpp){% endif_version %}{% if_version gte:2.2.x %}[connect](/docs/{{ page.version }}/production/dp-config/dpp/){% endif_version %} directly to it.

{% tip %}
When the mode is not specified, {{site.mesh_product_name}} will always start in `standalone` mode by default.
{% endtip %}

#### Optional: Docker authentication

Running administrative tasks (like generating a dataplane token) requires {% if_version lte:2.1.x %}[authentication by token](/docs/{{ page.version }}/security/api-server-auth/#admin-user-token){% endif_version %}{% if_version gte:2.2.x %}(/docs/{{ page.version }}/production/secure-deployment/api-server-auth/#admin-user-token){% endif_version %} or a connection via localhost.

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

## Failure modes

#### Control plane offline

* New data planes proxis won't be able to join the mesh.
* Data-plane proxy configuration will not be updated.
* Communication between data planes proxies will still work.

{% tip %}
You can think of this failure case as *"Freezing"* the zone mesh configuration.
Communication will still work but changes will not be reflected on existing data plane proxies.
{% endtip %}
