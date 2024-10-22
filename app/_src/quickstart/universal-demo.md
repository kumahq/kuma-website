---
title: Deploy Kuma on Universal
---

This demo shows how to run {{site.mesh_product_name}} in Universal mode on a single machine.

To start learning how {{site.mesh_product_name}} works, you will run and secure a simple demo application that consists of two services:

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

## Install {{site.mesh_product_name}}

To download {{site.mesh_product_name}} we will use official installer, it will automatically detect the operating system (Amazon Linux, CentOS, RedHat, Debian, Ubuntu, and macOS) and download {{site.mesh_product_name}}:

```shell
curl -L {{site.links.web}}{% if page.edition %}/{{page.edition}}{% endif %}/installer.sh | VERSION={{ page.version_data.version }} sh -
```

To finish installation we need to add {{site.mesh_product_name}} binaries to path: 

```shell
export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{ page.version_data.version }}/bin
```

## Start control plane

Now we need to start control plane in background by running command:

```shell
kuma-cp run > cp-logs.txt 2>&1 &
```

To check if control plane started without issues you can check logs:

```shell
tail cp-logs.txt
```

## Deploy demo application

### Generate token for data planes

On Universal we need to manually create token for data planes. To do this need to run this commands (these tokens will be valid
for 30 days):

```sh
kumactl generate dataplane-token --tag kuma.io/service=redis --valid-for=720h > /tmp/kuma-token-redis
kumactl generate dataplane-token --tag kuma.io/service=demo-app --valid-for=720h > /tmp/kuma-token-demo-app
```

After generating tokens we can data planes that will be used for proxying traffic between `demo-app` and `redis`.

### Start data planes

{% warning %}
Because this is a quickstart, we don't setup [certificates for communication
between the data plane proxies and the control plane](/docs/{{ page.version }}/production/secure-deployment/certificates/#encrypted-communication).
You'll see a warning like the following in the `kuma-dp` logs:

```
2024-07-25T20:06:36.082Z	INFO	dataplane	[WARNING] The data plane proxy cannot verify the identity of the control plane because you are not setting the "--ca-cert-file" argument or setting the KUMA_CONTROL_PLANE_CA_CERT environment variable.
```

This isn't related to mTLS between services.
{% endwarning %}

First we can start `redis` dataplane. On universal we need to manually create Dataplane object for our data plane, and 
run kuma-dp manually, to do this run:

```shell
KUMA_READINESS_PORT=9901{% if_version gte:2.9.x %}KUMA_APPLICATION_PROBE_PROXY_PORT=9902{% endif_version %} kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=/tmp/kuma-token-redis \
  --dataplane="
  type: Dataplane
  mesh: default
  name: redis
  networking: 
    address: 127.0.0.1
    inbound: 
      - port: 16379
        servicePort: 26379
        serviceAddress: 127.0.0.1
        tags: 
          kuma.io/service: redis
          kuma.io/protocol: tcp
    admin:
      port: 9903"
```

You can notice that we manually specify readiness port with environment variable `KUMA_READINESS_PORT` when every data plane is 
running on separate machines this is obsolete. 

[//]: # (TODO should we tell users explicitely to open another terminal window or should we just run kuma-dp in background?)

Now we need to start data plane for our demo-app, we can do this by running:

```shell
KUMA_READINESS_PORT=9904{% if_version gte:2.9.x %}KUMA_APPLICATION_PROBE_PROXY_PORT=9905{% endif_version %} kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=/tmp/kuma-token-demo-app \
  --dataplane="
  type: Dataplane
  mesh: default
  name: demo-app
  networking: 
    address: 127.0.0.1
    outbound:
      - port: 6379
        tags:
          kuma.io/service: redis
    inbound: 
      - port: 15000
        servicePort: 5000
        serviceAddress: 127.0.0.1
        tags: 
          kuma.io/service: demo-app
          kuma.io/protocol: http
    admin:
      port: 9906"
```

### Run kuma-counter-demo app

1. With data planes running we can start our apps, first we will start and configure `Redis`:
```shell
redis-server --port 26379 --daemonize yes && redis-cli -p 26379 set zone local
```
You should see message `OK` from `Redis` if this operation was successful.

2. Now we can start our `demo-app`. To do this we need to download repository with its source code:
```shell
git clone https://github.com/kumahq/kuma-counter-demo.git && cd kuma-counter-demo
```

3. No we need to run:
```shell
npm install --prefix=app/ && npm start --prefix=app/
```
If `demo-app` was started correctly you will see message:
```
Server running on port 5000
```

In a browser, go to [127.0.0.1:5000](http://127.0.0.1:5000) and increment the counter. `demo-app` GUI should work without issues now.

## Explore {{site.mesh_product_name}} GUI

You can view the sidecar proxies that are connected to the {{site.mesh_product_name}} control plane.

{{site.mesh_product_name}} ships with a **read-only** [GUI](/docs/{{ page.version }}/production/gui) that you can use to retrieve {{site.mesh_product_name}} resources. 
By default, the GUI listens on the API port which defaults to `5681`.

To access {{site.mesh_product_name}} we need to navigate to [127.0.0.1:5681/gui](http://127.0.0.1:5681/gui) in your browser.

To learn more, read the [documentation about the user interface](/docs/{{ page.version}}/production/gui).

## Introduction to zero-trust security

By default, the network is insecure and not encrypted. We can change this with {{site.mesh_product_name}} by enabling 
the [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) policy to provision a Certificate Authority (CA) that 
will automatically assign TLS certificates to our services (more specifically to the injected data plane proxies running 
alongside the services).

{% if_version gte:2.6.x %}
Before enabling [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) (mTLS) in your mesh, you need to create a
`MeshTrafficPermission` policy that allows traffic between your applications.

{% warning %}
If you enable [mTLS](/docs/{{ page.version }}/policies/mutual-tls/) without a `MeshTrafficPermission` policy, all traffic between your applications will be blocked. 
{% endwarning %}

To create a `MeshTrafficPermission` policy, you can use the following command:

```shell
echo 'type: MeshTrafficPermission 
name: mtp
mesh: default 
spec: 
  targetRef: 
    kind: Mesh 
  from: 
    - targetRef: 
        kind: Mesh 
      default: 
        action: Allow' | kumactl apply -f -
```

This command will create a policy that allows all traffic between applications within your mesh. If you need to create 
more specific rules, you can do so by editing the policy manifest.
{% endif_version %}

We can enable Mutual TLS with a `builtin` CA backend by executing:

```shell
echo 'type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin' | kumactl apply -f -
```

The traffic is now encrypted with mTLS and each service can reach any other service.

We can then restrict the traffic by default by executing:

```shell
echo 'type: MeshTrafficPermission 
name: mtp
mesh: default 
spec: 
  targetRef: 
    kind: Mesh 
  from: 
    - targetRef: 
        kind: Mesh 
      default: 
        action: Deny' | kumactl apply -f -
```

At this point, the demo application should not function, because we blocked the traffic.
You can verify this by clicking the increment button again and seeing the error message in the browser.
We can allow the traffic from the `demo-app` to `redis` by applying the following `MeshTrafficPermission`:

```shell
echo 'type: MeshTrafficPermission 
name: allow-from-demo-app
mesh: default 
spec: 
  targetRef: 
    kind: MeshSubset
    tags:
      kuma.io/service: redis
  from: 
    - targetRef: 
        kind: MeshSubset 
        tags:
          kuma.io/service: demo-app
      default: 
        action: Allow' | kumactl apply -f -
```

You can click the increment button, the application should function once again.
However, the traffic to `redis` from any other service than `demo-app` is not allowed.

## Next steps

* Explore the [Features](/features) available to govern and orchestrate your service traffic.
* Learn more about what you can do with the [GUI](/docs/{{ page.version }}/production/gui).
* Read the [full documentation](/docs/{{ page.version }}/) to learn about all the capabilities of {{site.mesh_product_name}}.
{% if site.mesh_product_name == "Kuma" %}* Chat with us at the official [Kuma Slack](/community) for questions or feedback.{% endif %}
