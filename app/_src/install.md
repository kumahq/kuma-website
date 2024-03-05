---
title: Install
---

blocks to click

## Download

{% tabs download useUrlFragment=false %}
{% tab download Kubernetes %}
Download the {{site.mesh_product_name}} executable Docker images:
    * **kuma-cp**: `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
    * **kuma-dp**: `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
    * **kumactl**: `docker.io/kumahq/kumactl:{{ page.latest_version }}`

You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.
{% endtab %}
{% tab download Helm %}

> **Note:** You need Helm 3.8.0 or later to use the {{site.mesh_product_name}} Helm charts.

Add the {{site.mesh_product_name}} charts repository to your local Helm  deployment:

```sh
helm repo add kuma https://kumahq.github.io/charts
```

Once the repo is added, all following updates can be fetched with `helm repo update`.
{% endtab %}
{% tab download OpenShift %}
{% endtab %}
{% tab download Docker %}
Download the {{site.mesh_product_name}} executable Docker images:
    * **kuma-cp**: `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
    * **kuma-dp**: `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
    * **kumactl**: `docker.io/kumahq/kumactl:{{ page.latest_version }}`

You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.
{% endtab %}
{% tab download Amazon EKS %}
Download the {{site.mesh_product_name}} executable Docker images:
    * **kuma-cp**: `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
    * **kuma-dp**: `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
    * **kumactl**: `docker.io/kumahq/kumactl:{{ page.latest_version }}`

You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.
{% endtab %}
{% tab download CentOS %}
{% endtab %}
{% tab download RedHat %}
{% endtab %}
{% tab download Amazon Linux %}
{% endtab %}
{% tab download Debian %}
{% endtab %}
{% tab download Ubuntu %}
{% endtab %}
{% endtabs %}

## Run

{% tabs run useUrlFragment=false %}
{% tab run Kubernetes %}
{% endtab %}
{% tab run Helm %}
{% endtab %}
{% tab run OpenShift %}
{% endtab %}
{% tab run Docker %}
{% endtab %}
{% tab run Amazon EKS %}
{% endtab %}
{% tab run CentOS %}
{% endtab %}
{% tab run RedHat %}
{% endtab %}
{% tab run Amazon Linux %}
{% endtab %}
{% tab run Debian %}
{% endtab %}
{% tab run Ubuntu %}
{% endtab %}
{% endtabs %}

## Use

{% tabs use useUrlFragment=false %}
{% tab use Kubernetes %}
{% endtab %}
{% tab use Helm %}
{% endtab %}
{% tab use OpenShift %}
{% endtab %}
{% tab use Docker %}
{% endtab %}
{% tab use Amazon EKS %}
{% endtab %}
{% tab use CentOS %}
{% endtab %}
{% tab use RedHat %}
{% endtab %}
{% tab use Amazon Linux %}
{% endtab %}
{% tab use Debian %}
{% endtab %}
{% tab use Ubuntu %}
{% endtab %}
{% endtabs %}

## Kubernetes and Amazon EKS

### Download
1. Download the {{site.mesh_product_name}} executable Docker images:
    * **kuma-cp**: `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
    * **kuma-dp**: `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
    * **kumactl**: `docker.io/kumahq/kumactl:{{ page.latest_version }}`

    You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.

### Run
1. Run {{site.mesh_product_name}}:

    ```sh
    docker run -p 5681:5681 docker.io/kumahq/kuma-cp:{{ page.latest_version }} run
    ```
    This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".
    {% tip %}
    **Note**: By default this will run {{site.mesh_product_name}} with a `memory` [store](/docs/{{ page.version }}/documentation/configuration#store), but you can use a persistent storage like PostgreSQL by updating the `conf/kuma-cp.conf` file.
    {% endtip %}

### Optional: Authenticate
 
Running administrative tasks (like generating a dataplane token) requires {% if_version lte:2.1.x %}[authentication by token](/docs/{{ page.version }}/security/api-server-auth/#admin-user-token){% endif_version %}{% if_version gte:2.2.x %}[authentication by token](/docs/{{ page.version }}/production/secure-deployment/api-server-auth/#admin-user-token){% endif_version %} or a connection via localhost.

* **Localhost:** For `kuma-cp` to recognize requests issued to docker published port it needs to run the container in the host network. To do this, add `--network="host"` parameter to the `docker run` command from point 2.
* **Authenticating via token:** You can also configure `kumactl` to access `kuma-dp` from the container.
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

### Use {{site.mesh_product_name}}

{% include snippets/use_kuma_k8s.md %}

## Helm

### Prerequisites

* Helm 3.8.0 or later to use the {{site.mesh_product_name}} Helm charts

### Add the {{site.mesh_product_name}} charts repository

Add the {{site.mesh_product_name}} charts repository to your local Helm  deployment:

```sh
helm repo add kuma https://kumahq.github.io/charts
```

Once the repo is added, all following updates can be fetched with `helm repo update`.

### Run {{site.mesh_product_name}}

Run {{site.mesh_product_name}}:

```sh
helm install --create-namespace --namespace {{site.mesh_namespace}} kuma kuma/kuma
```

You can use any Kubernetes namespace to install {{site.mesh_product_name}}, by default we suggest using `{{site.mesh_namespace}}`. 
This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".

### Use {{site.mesh_product_name}}:

{% include snippets/use_kuma_k8s.md %}

## OpenShift

### Download {{site.mesh_product_name}}

{% include snippets/install_kumactl.md installer_version="preview" %}

### Run {{site.mesh_product_name}}

We can install and run {{site.mesh_product_name}}:

{% tabs openshift-run useUrlFragment=false %}
{% tab openshift-run OpenShift 4.x %}
```sh
./kumactl install control-plane --cni-enabled | oc apply -f -
```

Starting from version 4.1 OpenShift utilizes `nftables` instead of `iptables`. So using init container for redirecting traffic to the proxy no longer works. Instead, we use the `--cni-enabled` flag to install the {% if_version lte:2.1.x %}[`kuma-cni`](/docs/{{ page.version }}/networking/cni){% endif_version %}{% if_version gte:2.2.x %}[`kuma-cni`](/docs/{{ page.version }}/production/dp-config/cni/){% endif_version %}.
{% endtab %}

{% tab openshift-run OpenShift 3.11 %}

By default `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` are disabled on OpenShift 3.11.
In order to make it work add the following `pluginConfig` into `/etc/origin/master/master-config.yaml` on the master node:

```yaml
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
```

After updating `master-config.yaml` restart the cluster and install `control-plane`:

```sh
./kumactl install control-plane | oc apply -f -
```

{% endtab %}
{% endtabs %}

This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".

{% tip %}
It may take a while for OpenShift to start the {{site.mesh_product_name}} resources, you can check the status by executing:

```sh
oc get pod -n {{site.mesh_namespace}}
```

{% endtip %}

### Use {{site.mesh_product_name}}

{{site.mesh_product_name}} (`kuma-cp`) will be installed in the newly created `{{site.mesh_namespace}}` namespace! Now that {{site.mesh_product_name}} has been installed, you can access the control-plane via either the GUI, `oc`, the HTTP API, or the CLI:

{% tabs openshift-use useUrlFragment=false %}
{% tab openshift-use GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} we need to first port-forward the API service with:

```sh
oc port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

{% endtab %}
{% tab openshift-use oc (Read & Write) %}

You can use {{site.mesh_product_name}} with `oc` to perform **read and write** operations on {{site.mesh_product_name}} resources. For example:

```sh
oc get meshes
# NAME          AGE
# default       1m
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | oc apply -f -
```

{% endtab %}
{% tab openshift-use HTTP API (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** HTTP API that you can use to retrieve {{site.mesh_product_name}} resources.

By default the HTTP API listens on port `5681`. To access {{site.mesh_product_name}} we need to first port-forward the API service with:

```sh
oc port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

{% endtab %}
{% tab openshift-use kumactl (Read-Only) %}

You can use the `kumactl` CLI to perform **read-only** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API, you will need to first port-forward the API service with:

```sh
oc port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

and then run `kumactl`, for example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```

{% endtab %}
{% endtabs %}

You will notice that {{site.mesh_product_name}} automatically creates a {% if_version lte:2.1.x %}[`Mesh`](/docs/{{ page.version }}/policies/mesh){% endif_version %}{% if_version gte:2.2.x %}[`Mesh`](/docs/{{ page.version }}/production/mesh/){% endif_version %} entity with name `default`.

{% tip %}
{{site.mesh_product_name}} explicitly specifies UID for `kuma-dp` sidecar to avoid capturing traffic from `kuma-dp` itself. For that reason, `nonroot` [Security Context Constraint](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html) has to be granted to the application namespace:

```sh
oc adm policy add-scc-to-group nonroot system:serviceaccounts:<app-namespace>
```

If namespace is not configured properly, we will see following error on the `Deployment` or `DeploymentConfig`

```
'pods "kuma-demo-backend-v0-cd6b68b54-" is forbidden: unable to validate against any security context constraint: [spec.containers[1].securityContext.securityContext.runAsUser: Invalid value: 5678: must be in the ranges: [1000540000, 1000549999]]'
```

{% endtip %}

## Docker

### Download
1. Download the {{site.mesh_product_name}} executable Docker images:
    * **kuma-cp**: `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
    * **kuma-dp**: `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
    * **kumactl**: `docker.io/kumahq/kumactl:{{ page.latest_version }}`

    You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.

### 2. Run {{site.mesh_product_name}}

We can run {{site.mesh_product_name}}:

`docker run -p 5681:5681 docker.io/kumahq/kuma-cp:{{ page.latest_version }} run`

This example will run {{site.mesh_product_name}} in {% if_version lte:2.5.x %}`standalone`{% endif_version %}{% if_version gte:2.6.x %}`single-zone`{% endif_version %} mode for a "flat" deployment, but there are more advanced {% if_version lte:2.1.x %}[deployment modes](/docs/{{ page.version }}/introduction/deployments){% endif_version %}{% if_version gte:2.2.x %}[deployment modes](/docs/{{ page.version }}/production/deployment/){% endif_version %} like "multi-zone".

{% tip %}
**Note**: By default this will run {{site.mesh_product_name}} with a `memory` [store](/docs/{{ page.version }}/documentation/configuration#store), but you can use a persistent storage like PostgreSQL by updating the `conf/kuma-cp.conf` file.
{% endtip %}

#### 2.1 Authentication (optional)

Running administrative tasks (like generating a dataplane token) requires {% if_version lte:2.1.x %}[authentication by token](/docs/{{ page.version }}/security/api-server-auth/#admin-user-token){% endif_version %}{% if_version gte:2.2.x %}[authentication by token](/docs/{{ page.version }}/production/secure-deployment/api-server-auth/#admin-user-token){% endif_version %} or a connection via localhost.

##### 2.1.1 Localhost

For `kuma-cp` to recognize requests issued to docker published port it needs to run the container in the host network.
To do this, add `--network="host"` parameter to the `docker run` command from point 2.

##### 2.1.2 Authenticating via token

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

### 3. Use {{site.mesh_product_name}}

{{site.mesh_product_name}} (`kuma-cp`) is now running! Now that {{site.mesh_product_name}} has been installed you can access the control-plane via either the GUI, the HTTP API, or the CLI:

{% tabs docker-use useUrlFragment=false %}
{% tab docker-use GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

{% endtab %}
{% tab docker-use HTTP API (Read & Write) %}

{{site.mesh_product_name}} ships with a **read and write** HTTP API that you can use to perform operations on {{site.mesh_product_name}} resources. By default the HTTP API listens on port `5681`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

{% endtab %}
{% tab docker-use kumactl (Read & Write) %}

You can use the `kumactl` CLI to perform **read and write** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. For example:

```sh
docker run --net="host" kumahq/kumactl:<version> kumactl get meshes
NAME          mTLS      METRICS      LOGGING   TRACING
default       off       off          off       off
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | docker run -i --net="host" \
  docker.io/kumahq/kumactl:<version> kumactl apply -f -
```

**Note**: we are running `kumactl` from the Docker container on the same network as the `host`, but most likely you want to download a compatible version of {{site.mesh_product_name}} for the machine where you will be executing the commands.

You can run the following script to automatically detect the operating system and download {{site.mesh_product_name}}:

<div class="language-sh">
<pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
</div>

or you can download the distribution manually:

- <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-centos-amd64/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-centos-amd64.tar.gz">CentOS</a>
- <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-rhel-amd64/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-rhel-amd64.tar.gz">RedHat</a>
- <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-debian-amd64/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-debian-amd64.tar.gz">Debian</a>
- <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-ubuntu-amd64/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-ubuntu-amd64.tar.gz">Ubuntu</a>
- <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-darwin-amd64/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-darwin-amd64.tar.gz">macOS</a> or run `brew install kumactl`

and extract the archive with:

```sh
tar xvzf kuma-*.tar.gz
```

You will then find the `kumactl` executable in the `kuma-{{ page.latest_version }}/bin` folder.

{% endtab %}
{% endtabs %}

You will notice that {{site.mesh_product_name}} automatically creates a {% if_version lte:2.1.x %}[`Mesh`](/docs/{{ page.version }}/policies/mesh){% endif_version %}{% if_version gte:2.2.x %}[`Mesh`](/docs/{{ page.version }}/production/mesh/){% endif_version %} entity with name `default`.

## Operating Systems (CentOS, RedHat, Amazon Linux, Debian, and Ubuntu)

{% include snippets/install_os.md %}
