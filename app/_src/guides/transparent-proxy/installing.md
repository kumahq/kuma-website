---
title: Installing Transparent Proxy
---

{% assign docs = "/docs/" | append: page.release %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% assign version = page.version %}
{% assign version = page.latest_version.version %}
{% capture version_image %}{% if version == "preview" %}0.0.0-preview.latest{% else %}{{ version }}{% endif %}{% endcapture %}
{% assign version_image = page.latest_version.version %}
{% assign ip_ab = "172.56" %}
{% assign ip_abc = ip_ab | append: ".78" %}
{% assign kuma = append: site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-demo = kuma | append: "-demo" %}
{% assign tmp-kuma-demo = "/tmp/" | append: kuma-demo %}
{% assign docker_org = site.mesh_docker_org | default: "kumahq" %}
{% assign gateway_name = kuma-demo | append: "-gateway" %}

{% assign url_root = site.links.web | default: "https://kuma.io" %}
{% capture edition %}{% if page.edition and page.edition != "kuma" %}/{{ page.edition }}{% endif %}{% endcapture %}
{% assign url_installer = url_root | append: edition | append: "/installer.sh" %}

Here are the steps to set up a transparent proxy for your service. Once set up, your service will run with a transparent proxy, giving you access to {{ Kuma }}'s features like traffic control, observability, and security.

## Prerequisites

Before starting, ensure you have the following tools installed:

1. **Docker**
2. [**jq**](https://jqlang.github.io/jq/download/)
3. [**kumactl**]({{ docs }}/introduction/install-kuma/)

## Step 1: Prepare the environment

### Install {{ Kuma }}

You can download and install {{ Kuma }} using the official installer. The installer automatically detects your operating system (Amazon Linux, CentOS, RedHat, Debian, Ubuntu, macOS) and downloads the appropriate binaries:

```sh
curl --location {{ url_installer }} | VERSION="{{ version }}" sh -
```

{% if version != "preview" %}
To finalize the installation add the {{ Kuma }} binaries to your system’s [$PATH](https://en.wikipedia.org/wiki/PATH_(variable)) so the commands are easily accessible:

```sh
export PATH=$PATH:$(pwd)/{{ kuma }}-{{ version }}/bin
```
{% else %}
To finalize the installation move the {{ Kuma }} binaries to a directory that is already in your system’s [$PATH](https://en.wikipedia.org/wiki/PATH_(variable)). In this case, use `/usr/local/bin/`:

```sh
mv {{ kuma }}-*/bin/* /usr/local/bin/
```
{% endif %}

### Create temporary directories

Set up a temporary directory to store resources like data plane tokens, `Dataplane` templates, and logs:

```sh
mkdir -p {{ tmp-kuma-demo }}/logs
```

### Prepare a `Dataplane` resource template

Create a reusable `Dataplane` resource template for services:

```sh
echo 'type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
    - port: {% raw %}{{ port }}{% endraw %}
      tags:
        kuma.io/service: {% raw %}{{ name }}{% endraw %}
        kuma.io/protocol: {% raw %}{{ protocol }}{% endraw %}
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}' > {{ tmp-kuma-demo }}/dataplane.yaml
```

This template simplifies creating Dataplane configurations for different services by replacing dynamic values during deployment.

### Create a Docker network

Set up a separate Docker network for the containers. Use IP addresses in the `{{ ip_abc }}.0/24` range or customize as needed:

```sh
docker network create \
  --subnet "{{ ip_ab }}.0.0/16" \
  --ip-range "{{ ip_abc }}.0/24" \
  --gateway "{{ ip_abc }}.254" \
  {{ kuma-demo }}
```

## Step 2: Set up the control plane

### Start the control plane

Run the Kuma control plane in a Docker container:

```sh
docker run \
  --detach \
  --name {{ kuma-demo }}-control-plane \
  --hostname {{ kuma }}-control-plane \
  --volume {{ tmp-kuma-demo }}:/{{ kuma }} \
  --network {{ kuma-demo }} \
  --publish "25681:5681" \
  --ip "{{ ip_abc }}.1" \
  {{ docker_org }}/kuma-cp:{{ version_image }} run
```

Access the GUI at `http://localhost:25681/gui`.

### Configure `kumactl`

Link `kumactl` to the control plane:

1. Retrieve the admin token:

   ```sh
   docker exec --tty --interactive {{ kuma-demo }}-control-plane \
     wget --quiet --output-document - http://localhost:5681/global-secrets/admin-user-token \
     | jq --raw-output .data \
     | base64 --decode \
     > {{ tmp-kuma-demo }}/user-token-admin
   ```

2. Configure `kumactl`:

   ```sh
   kumactl config control-planes add \
     --name {{ kuma-demo }}-control-plane \
     --address http://localhost:25681 \
     --auth-type tokens \
     --auth-conf "token=$(cat {{ tmp-kuma-demo }}/user-token-admin)" \
     --skip-verify
   ```

To test it you can run

```sh
kumactl get meshes
```

which should result in message similar to:

```
NAME      mTLS   METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   off    off       off       off       off        off          1m
```
{:.no-line-numbers}

### Configure the default mesh

Enable the exclusive use of `MeshServices` in the default mesh:

```sh
echo "type: Mesh
name: default
meshServices:
  mode: Exclusive" | kumactl apply -f-
```

## Step 3: Set up services

### Redis

#### Generate a data plane token

Generate a token that the Redis data plane proxy will use to authenticate with the control plane.

```sh
kumactl generate dataplane-token \
  --tag "kuma.io/service=redis" \
  --valid-for "720h" \
  > {{ tmp-kuma-demo }}/data-plane-token-redis
```

#### Start the Redis container

```sh
docker run \
  --detach \
  --name {{ kuma-demo }}-redis \
  --hostname redis \
  --volume {{ tmp-kuma-demo }}:/{{ kuma }} \
  --network {{ kuma-demo }} \
  --ip "{{ ip_abc }}.2" \
  redis:7.4.1 redis-server --protected-mode no
```

#### Prepare the Redis container

Enter the Redis container to run further commands.

```sh
docker exec --tty --interactive --privileged {{ kuma-demo }}-redis bash`
```

{% warning %}
The following steps must be executed inside the Redis containe`r.
{% endwarning %}

##### Install required tools

```sh
apt update && apt install -y curl iptables
curl --location {{ url_installer }} | VERSION="{{ version }}" sh -
mv {{ kuma }}-*/bin/* /usr/local/bin/
```

##### Set a zone name

Assign a zone name for Redis. This name will be displayed by the demo application to indicate the Redis instance being used.

```sh
redis-cli set zone local-{{ kuma-demo }}-zone
```

##### Create a separate user for the data plane proxy

```sh
useradd --uid {{ tproxy.defaults.kuma-dp.uid }} --user-group {{ tproxy.defaults.kuma-dp.username }}
```

##### Start the data plane proxy

```sh
runuser --user kuma-dp -- \
  /usr/local/bin/kuma-dp run \
  --cp-address="https://{{ kuma }}-control-plane:5678" \
  --dataplane-token-file="/{{ kuma }}/data-plane-token-redis" \
  --dataplane-file="/{{ kuma }}/dataplane.yaml" \
  --dataplane-var="name=redis" \
  --dataplane-var="address={{ ip_abc }}.2" \
  --dataplane-var="port=6379" \
  --dataplane-var="protocol=tcp" \
  >/{{ kuma }}/logs/data-plane-redis.log 2>&1 &
```

##### Install the transparent proxy

```sh
kumactl install transparent-proxy \
  --verbose \
  --redirect-dns \
  2>&1 | tee /{{ kuma }}/logs/transparent-proxy-redis.log
```

##### Exit the Redis container

```sh
exit
```

### Demo Application

#### Generate a data plane token

```sh
kumactl generate dataplane-token \
  --tag "kuma.io/service=demo-app" \
  --valid-for "720h" \
  > {{ tmp-kuma-demo }}/data-plane-token-demo-app
```

#### Start the application container

```sh
docker run \
  --detach \
  --name {{ kuma-demo }}-app \
  --hostname demo-app \
  --volume {{ tmp-kuma-demo }}:/{{ kuma }} \
  --network {{ kuma-demo }} \
  --publish "25000:5000" \
  --ip "{{ ip_abc }}.3" \
  --env "REDIS_HOST=redis.svc.mesh.local" \
  kumahq/kuma-demo
```

#### Prepare the application container

1. Access the container:

   ```sh
   docker exec --tty --interactive --privileged --workdir /root {{ kuma-demo }}-app bash
   ```

2. Install required tools:

   ```sh
   apt-get update && apt-get install -y iptables curl
   curl --location {{ url_installer }} | VERSION="{{ version }}" sh -
   mv {{ kuma }}-*/bin/* /usr/local/bin/
   useradd --uid {{ tproxy.defaults.kuma-dp.uid }} --user-group {{ tproxy.defaults.kuma-dp.username }}
   ```

#### Start the data plane proxy

```sh
runuser --user kuma-dp -- \
  /usr/local/bin/kuma-dp run \
    --cp-address="https://{{ kuma }}-control-plane:5678" \
    --dataplane-token-file="/{{ kuma }}/data-plane-token-demo-app" \
    --dataplane-file="/{{ kuma }}/dataplane.yaml" \
    --dataplane-var="name=demo-app" \
    --dataplane-var="address={{ ip_abc }}.3" \
    --dataplane-var="port=5000" \
    --dataplane-var="protocol=http" \
    > /{{ kuma }}/logs/data-plane-demo-app.log 2>&1 &     
```

#### Install the transparent proxy

```sh
kumactl install transparent-proxy \
  --verbose \
  --redirect-dns \
  2>&1 | tee /{{ kuma }}/logs/transparent-proxy-demo-app.log
```

## Introduction to zero-trust security

By default, the network is **insecure and unencrypted**. With {{ Kuma }}, you can enable the [Mutual TLS (mTLS)](/docs/{{ page.release }}/policies/mutual-tls/) policy to secure the network. This works by setting up a Certificate Authority (CA) that automatically provides TLS certificates to your services (specifically to the data plane proxies running next to each service).

To enable Mutual TLS using a `builtin` CA backend, run the following command:

```sh
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin' | kumactl apply -f -
```

After enabling mTLS, all traffic is **encrypted and secure**. However, you can no longer access the `demo-app` directly. This happens for two reasons:

1. When mTLS is enabled, {{ Kuma }} doesn’t create traffic permissions by default. This means no traffic will flow until you define a [MeshTrafficPermission]({{ docs }}/policies/meshtrafficpermission/) policy to allow `demo-app` to communicate with `redis`.

2. When you try to call `demo-app` using a browser or other HTTP client, you are essentially acting as an external client without a valid TLS certificate. Since all services are now required to present a certificate signed by the `ca-1` Certificate Authority, the connection is rejected. Only services within the `default` mesh, which are assigned valid certificates, can communicate with each other.

To address the first issue, you need to apply an appropriate `MeshTrafficPermission` policy:

```sh
echo 'type: MeshTrafficPermission 
name: allow-redis-from-demo-app
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

The second issue is a bit more challenging. You can’t just get the necessary certificate and set up your web browser to act as part of the mesh. To handle traffic from outside the mesh, you need a _gateway proxy_. You can use tools like [Kong](https://github.com/Kong/kong), or you can use the [Built-in Gateway]({{ docs }}/using-mesh/managing-ingress-traffic/builtin/) that {{ Kuma }} provides.

{% tip %}
For more information, see the [Managing incoming traffic with gateways]({{ docs }}/using-mesh/managing-ingress-traffic/overview/) section in the documentation.
{% endtip %}

In this guide, we’ll use the built-in gateway. It allows you to configure a data plane proxy to act as a gateway and manage external traffic securely.

### Setting up the built-in gateway

The built-in gateway works like the data plane proxy for a regular service, but it requires its own configuration. Here’s how to set it up step by step.

#### Step 1: Create a `Dataplane` resource

For regular services, we reused a single Dataplane configuration file and provided dynamic values (like names and addresses) when starting the data plane proxy. This made it easier to scale or deploy multiple instances. However, since we’re deploying only one instance of the gateway, we can simplify things by hardcoding all the values directly into the file, as shown below:

```sh
echo 'type: Dataplane
mesh: default
name: {{ gateway_name }}-instance-1
networking:
  address: {{ ip_abc }}.4
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: {{ gateway_name }}' > {{ tmp-kuma-demo }}/dataplane-gateway.yaml
```

If you prefer to keep the flexibility of dynamic values, you can use the same template mechanisms for the gateway's `Dataplane` configuration as you did for regular services.

#### Step 2: Generate a data plane token

The gateway proxy requires a data plane token to securely register with the control plane. You can generate the token using the following command:

```sh
kumactl generate dataplane-token \
  --tag "kuma.io/service={{ kuma-demo }}-gateway" \
  --valid-for "720h" \
  > {{ tmp-kuma-demo }}/data-plane-token-gateway
```

#### Step 3: Start the gateway container

With the configuration and token in place, you can start the gateway proxy as a container:

```sh
docker run \
  --detach \
  --name {{ gateway_name }} \
  --hostname gateway \
  --volume {{ tmp-kuma-demo }}:/{{ kuma }} \
  --network {{ kuma-demo }} \
  --publish "25001:5000" \
  --ip "{{ ip_abc }}.4" \
  {{ docker_org }}/kuma-dp:{{ version_image }} run \
    --dns-enabled="false" \
    --cp-address="https://{{ kuma }}-control-plane:5678/" \
    --dataplane-token-file="/{{ kuma }}/data-plane-token-gateway" \
    --dataplane-file="/{{ kuma }}/dataplane-gateway.yaml"
```

This command starts the gateway proxy and registers it with the control plane. However, the gateway is not yet ready to route traffic.

#### Step 4: Configure the gateway with `MeshGateway`

To enable the gateway to accept external traffic, configure it with a `MeshGateway`. This setup defines listeners that specify the port, protocol, and tags for incoming traffic, allowing policies like `MeshHTTPRoute` or `MeshTCPRoute` to route traffic to services.

Apply the configuration:

```sh
echo 'type: MeshGateway
mesh: default
name: {{ gateway_name }}
selectors:
- match:
    kuma.io/service: {{ gateway_name }}
conf:
  listeners:
  - port: 5000
    protocol: HTTP
    tags:
      port: http-5000' | kumactl apply -f-
```

This configures the gateway to listen on port `5000` with the HTTP protocol and adds a tag (`port: http-5000`) to target this listener in routing policies.

You can now test the gateway by sending a request to `http://localhost:25001/`. You should see a response like:

```
This is a {{ Kuma }} MeshGateway. No routes match this MeshGateway!
```
{:.no-line-numbers}

This confirms the gateway is running, but no routes have been configured yet to handle traffic.

#### Step 5: Create a route to connect the gateway to `demo-app`

To route traffic from the gateway to the `demo-app` service, create a `MeshHTTPRoute` policy:

```sh
echo 'type: MeshHTTPRoute
name: gateway-demo-app-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: {{ gateway_name }}
    tags:
      port: http-5000
  to:
  - targetRef:
      kind: Mesh
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: "/"
      default:
        backendRefs:
        - kind: MeshService
          name: demo-app' | kumactl apply -f-
```

This route links the gateway (`{{ gateway_name }}`) and its listener (`port: http-5000`) to the `demo-app` service. It forwards requests matching the path prefix `/` to `demo-app`.

After applying this route, the gateway will attempt to redirect traffic to `demo-app`. However, if you test it by accessing `http://localhost:25001`, you’ll see:

```
RBAC: access denied
```
{:.no-line-numbers}

This happens because no `MeshTrafficPermission` exists to allow traffic from the gateway to `demo-app`. You'll need to create one in the next step.

#### Step 6: Allow traffic from the gateway to `demo-app`

To fix the `RBAC: access denied` error, create a `MeshTrafficPermission` policy to allow the gateway to send traffic to `demo-app`:

```sh
echo 'type: MeshTrafficPermission
name: allow-demo-app-from-gateway
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: demo-app
  from:
  - targetRef:
      kind: MeshSubset
      tags:
        kuma.io/service: {{ gateway_name }}
    default:
      action: Allow' | kumactl apply -f -
```

This policy allows traffic from the gateway (`{{ gateway_name }}`) to `demo-app`. After applying it, you can access `http://localhost:25001`, and the traffic will reach the `demo-app` service successfully.

## Cleanup

To clean up your environment, remove the Docker containers, network, temporary directory, and the control plane configuration from `kumactl`. Run the following commands:

```sh
kumactl config control-planes remove --name {{ kuma-demo }}-control-plane

docker rm -f \
  {{ kuma-demo }}-control-plane \
  {{ kuma-demo }}-redis \
  {{ kuma-demo }}-app \
  {{ kuma-demo }}-gateway

docker network rm {{ kuma-demo }}

rm -rf {{ tmp-kuma-demo }}
```
