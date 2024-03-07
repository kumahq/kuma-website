---
title: Deploy Kuma on Universal
---

To start learning how {{site.mesh_product_name}} works, you run and secure a simple demo application that consists of two services:

- `demo-app`: a web application that lets you increment a numeric counter. It listens on port 5000
- `redis`: data store for the counter


{% mermaid %}
---
title: service graph of the demo app
---
flowchart LR
demo-app(demo-app :5000)
redis(redis :6379)
demo-app --> redis
{% endmermaid %}

## Prerequisites

* [Redis installed](https://redis.io/docs/getting-started/)
* Optional: To explore traffic metrics with the demo app, you also need to [set up Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/). See the [traffic metrics policy documentation](/docs/{{ page.version }}/policies/traffic-metrics).

## Install {{site.mesh_product_name}}

{% tabs install useUrlFragment=false %}
{% tab install Docker %}
Install a {{site.mesh_product_name}} control plane using the Docker images:

* **kuma-cp**: at `docker.io/kumahq/kuma-cp:{{ page.latest_version }}`
* **kuma-dp**: at `docker.io/kumahq/kuma-dp:{{ page.latest_version }}`
* **kumactl**: at `docker.io/kumahq/kumactl:{{ page.latest_version }}`

You can freely `docker pull` these images to start using {{site.mesh_product_name}}, as we will demonstrate in the following steps.
{% endtab %}
{% tab install Operating Systems %}
Do one of the following to download {{site.mesh_product_name}}:

* Run the following script to automatically detect the operating system (Amazon Linux, CentOS, RedHat, Debian, Ubuntu, and macOS) and download {{site.mesh_product_name}}:
    <div class="language-sh">
    <pre class="no-line-numbers"><code>curl -L https://kuma.io/installer.sh | VERSION={{ page.latest_version }} sh -</code></pre>
    </div>
* <a href="{{ site.links.direct }}/kuma-legacy/raw/names/kuma-{{ page.os }}-{{ page.arch }}/versions/{{ page.latest_version }}/kuma-{{ page.latest_version }}-{{ page.os }}-{{ page.arch }}.tar.gz">Download</a> the distribution manually. Then, extract the archive with: `tar xvzf kuma-{{ page.latest_version }}`.
{% endtab %}
{% endtabs %}

## Deploy the demo application

1. Deploy the demo app:
    ```sh
    kumactl apply https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
    ```

1. Port forward?
1. In a browser, go to [127.0.0.1:5000](http://127.0.0.1:5000) and increment the counter.

The demo app includes the `kuma.io/sidecar-injection` label enabled on the `kuma-demo` namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-demo
  labels:
    kuma.io/sidecar-injection: enabled
```

## Explore the GUI

You can view the sidecar proxies that are connected to the {{site.mesh_product_name}} control plane:

{% tabs usage useUrlFragment=false %}
{% tab usage GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`. 

You can navigate to [`127.0.0.1:5681/meshes/default/dataplanes`](http://127.0.0.1:5681/meshes/default/dataplanes) to see the connected dataplanes.

{% endtab %}
{% tab usage HTTP API (Read/Write) %}

{{site.mesh_product_name}} ships with a **read-only** HTTP API that you can use to retrieve {{site.mesh_product_name}} resources. 

By default the HTTP API listens on port `5681`. 

Navigate to [`127.0.0.1:5681/meshes/default/dataplanes`](http://127.0.0.1:5681/meshes/default/dataplanes) to see the connected dataplanes.

{% endtab %}
{% tab usage kumactl (Read/Write) %}

You can use the `kumactl` CLI to perform **read-only** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API, you will need to first port-forward the API service with:

Run `kumactl`, for example:

```sh
kumactl get dataplanes
# MESH      NAME                                              TAGS
# default   kuma-demo-app-68758d8d5d-dddvg.kuma-demo          app=kuma-demo-demo-app env=prod pod-template-hash=68758d8d5d protocol=http service=demo-app_kuma-demo_svc_5000 version=v8
# default   redis-master-657c58c859-5wkb4.kuma-demo           app=redis pod-template-hash=657c58c859 protocol=tcp role=master service=redis_kuma-demo_svc_6379 tier=backend
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```
{% endtab %}
{% endtabs %}

## Introduction to zero-trust security

By default, the network is insecure and not encrypted. We can change this with {{site.mesh_product_name}} by enabling the [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) policy to provision a Certificate Authority (CA) that will automatically assign TLS certificates to our services (more specifically to the injected data plane proxies running alongside the services).

{% if_version gte:2.6.x %}
Before enabling [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) (mTLS) in your mesh, you need to create a `MeshTrafficPermission` policy that allows traffic between your applications.

{% warning %}
If you enable [mTLS](/docs/{{ page.version }}/policies/mutual-tls/) without a `MeshTrafficPermission` policy, all traffic between your applications will be blocked. 
{% endwarning %}

To create a `MeshTrafficPermission` policy with a builtin CA backend, do the following:

```sh
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

Once Mutual TLS has been enabled, {{site.mesh_product_name}} will **not allow** traffic to flow freely across our services unless we explicitly have a [Traffic Permission](/docs/{{ page.version }}/policies/traffic-permissions/) policy that describes what services can be consumed by other services.
By default, a very permissive traffic permission is created.

For the sake of this demo, we will delete it:

```sh
kumactl delete traffic-permission allow-all-default
```

You can try to make requests to the demo application at [`127.0.0.1:5000/`](http://127.0.0.1:5000/) and you will notice that they will **not** work.

Now, let's add back the default traffic permission:
```sh
cat <<EOF | kumactl apply -f -
type: TrafficPermission
name: allow-all-default
mesh: default
sources:
  - match:
      kuma.io/service: '*'
destinations:
  - match:
      kuma.io/service: '*'
EOF
```

By doing so every request, we now make sure our demo application at [`127.0.0.1:5000/`](http://127.0.0.1:5000/) is not only working again, but it's automatically encrypted and secure.

{% tip %}
As usual, you can visualize the Mutual TLS configuration and the Traffic Permission policies we have just applied via the GUI, the HTTP API or `kumactl`.
{% endtip %}

## Next steps

* Explore the [Features](/features) available to govern and orchestrate your service traffic.
* Add a gateway to access the demo from the outside by following the [builtin gateway guide](/docs/{{ page.version }}/guides/gateway-builtin/).
* Add Kong as gateway to access the demo from the outside by following the [delegated gateway guide](/docs/{{ page.version }}/guides/gateway-delegated/).
* [Federate](/docs/{{ page.version }}/guides/federate) zone into a multizone deployment.
* Read the [full documentation](/docs/{{ page.version }}/) to learn about all the capabilities of {{site.mesh_product_name}}.
{% if site.mesh_product_name == "Kuma" %}
* Chat with us at the official [Kuma Slack](/community) for questions or feedback.
{% endif %}