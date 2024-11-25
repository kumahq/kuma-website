---
title: Deploy Kuma on Docker
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% assign KUMA = Kuma | upcase | replace: " ", "_" %}
{% assign KUMA_PREVIEW_VERSION = KUMA | append: "_PREVIEW_VERSION" %}
{% assign KUMA_DEMO_TMP = KUMA | append: "_DEMO_TMP" %}
{% assign KUMA_DEMO_ADMIN_TOKEN = KUMA | append: "_DEMO_ADMIN_TOKEN" %}
{% assign version = page.version %}
{% capture version_full %}{% if version == "preview" %}${{ KUMA_PREVIEW_VERSION }}{% else %}{{ version }}{% endif %}{% endcapture %}
{% assign ip_ab = "172.56" %}
{% assign ip_abc = ip_ab | append: ".78" %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-demo = kuma | append: "-demo" %}
{% assign docker_org = site.mesh_docker_org | default: "kumahq" %}
{% assign kuma-dp = kuma | append: "-data-plane-proxy" %}

{% capture edition %}{% if page.edition and page.edition != "kuma" %}/{{ page.edition }}{% endif %}{% endcapture %}
{% assign url_installer = site.links.web | default: "https://kuma.io" | append: edition | append: "/installer.sh" %}
{% assign url_installer_external = site.links.share | default: "https://kuma.io" | append: edition | append: "/installer.sh" %}


{%- comment -%} local docs links {%- endcomment -%}

{% capture MeshTrafficPermission %}[MeshTrafficPermission]({{ docs }}/policies/meshtrafficpermission/){% endcapture %}
{% capture MeshGateway %}[MeshGateway]({{ docs }}//using-mesh/managing-ingress-traffic/builtin-listeners/){% endcapture %}
{% capture MeshHTTPRoute %}[MeshHTTPRoute]({{ docs }}/policies/meshhttproute/){% endcapture %}
{% capture MeshTCPRoute %}[MeshTCPRoute]({{ docs }}/policies/meshtcproute/){% endcapture %}
{% capture kumactl %}[kumactl]({{ docs }}/explore/cli/#kumactl){% endcapture %}
{% capture Dataplane %}[Dataplane]({{ docs }}/production/dp-config/dpp/#dataplane-entity){% endcapture %}
{% capture Dataplanes %}[Dataplanes]({{ docs }}/production/dp-config/dpp/#dataplane-entity){% endcapture %}
{% capture MeshServices %}[MeshServices]({{ docs }}/networking/meshservice/){% endcapture %}

This quick start guide demonstrates how to run {{ Kuma }} in Universal mode using Docker containers.

You'll set up and secure a simple demo application to explore how {{ Kuma }} works. The application consists of two services:

- `demo-app`: A web application that lets you increment a numeric counter.
- `redis`: A data store that keeps the counter's value.

## Prerequisites

{% capture note-docker-engine %}
{% tip %}
**Note:** This guide has been tested with [Docker Engine](https://docs.docker.com/engine/), [Docker Desktop](https://docs.docker.com/desktop/), [OrbStack](https://orbstack.dev/), and [Colima](https://github.com/abiosoft/colima). For Colima, a small adjustment is required (explained later).
{% endtip %}
{% endcapture %}

1. Make sure the following tools are installed and ready to use:

   - `docker`
   - `curl`
   - `jq`
   - `base64`

   {{ note-docker-engine | indent }}

2. If you previously followed the [Deploy {{ Kuma }} on Universal quickstart]({{ docs }}/quickstart/universal-demo/) on the same machine, we recommend cleaning up your environment to ensure no control plane, Redis, demo-app, or their data plane proxies are still running.

   This isn’t mandatory, but it’s easy to accidentally mix up ports when typing commands manually, leading to unexpected results. If you copy the commands from this guide exactly or know what you’re doing and want to compare results between guides, you can skip this step.

## Prepare the environment

{% if version == "preview" %}
1. **Retrieve the latest preview version of {{ Kuma }}**

   To use the latest preview version of {{ Kuma }}, retrieve it and export it as an environment variable for later steps:
   
   ```sh
   export {{ KUMA_PREVIEW_VERSION }}="$(
     curl --silent --location {{ url_installer }} \
       | VERSION="preview" sh -s - --print-version 2> /dev/null
   )"
   
   echo "${{ KUMA_PREVIEW_VERSION }}"
   ```
   
   You should see output similar to this:
   
   ```
   0.0.0-preview.vabc123def
   ```
   {:.no-line-numbers}
   
   {% capture warning-env-var %}
   {% danger %}
   **Warning:** If no output is shown or it looks incorrect, set the `{{ KUMA_PREVIEW_VERSION }}` variable to the correct version manually. Do not continue without this value, as it is needed for later steps. Using the wrong version may cause errors or unexpected problems.  
   {% enddanger %}
   {% endcapture %}
   {{ warning-env-var | indent }}
{% endif %}

2. **Install {{ Kuma }}**

   You can download and install {{ Kuma }} using the official installer. The installer automatically detects your operating system (Amazon Linux, CentOS, RedHat, Debian, Ubuntu, macOS) and downloads the appropriate binaries:

   ```sh
   curl --location {{ url_installer }} {% if version == "preview" or page.edition and page.edition != "kuma" -%}\
     {% endif %}| VERSION="{{ version_full }}" sh -
   ```

   To finalize the installation add the {{ Kuma }} binaries to your system’s [PATH](https://en.wikipedia.org/wiki/PATH_(variable)) so the commands are easily accessible:

   ```sh
   export PATH="$(pwd)/{{ kuma }}-{{ version_full }}/bin:$PATH"
   ```

3. **Prepare a temporary directory**

   Set up a temporary directory to store resources like data plane tokens, {{ Dataplane }} templates, and logs. Export its path to the `{{ KUMA_DEMO_TMP }}` environment variable for use in later steps. Ensure the path does not end with a trailing `/`.

   {% capture warning-colima-adjust-path %}
   {% warning %}
   **Important:** If you are using **Colima**, you need to adjust the path. Colima only allows sharing paths from the `HOME` directory or `/tmp/colima/`. Instead of `/tmp/{{ kuma-demo }}`, you can use `/tmp/colima/{{ kuma-demo }}`.
   {% endwarning %}
   {% endcapture %}
   {{ warning-colima-adjust-path | indent }}

   ```sh
   export {{ KUMA_DEMO_TMP }}="/tmp/{{ kuma-demo }}"
   ```

   Check if the directory exists and is empty, and create it if necessary:

   ```sh
   mkdir -p "${{ KUMA_DEMO_TMP }}"
   ```

4. **Prepare a Dataplane resource template**

   Create a reusable {{ Dataplane }} resource template for services:
   
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
       redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}' > ${{ KUMA_DEMO_TMP }}/dataplane.yaml
   ```
   
   This template simplifies creating Dataplane configurations for different services by replacing dynamic values during deployment.

5. **Prepare a transparent proxy configuration file**

   ```sh
   echo 'kumaDPUser: {{ kuma-dp }}
   redirect:
     dns:
       enabled: true
   verbose: true' > ${{ KUMA_DEMO_TMP }}/config-transparent-proxy.yaml
   ```

6. **Create a Docker network**

   Set up a separate Docker network for the containers. Use IP addresses in the `{{ ip_abc }}.0/24` range or customize as needed:
   
   ```sh
   docker network create \
     --subnet {{ ip_ab }}.0.0/16 \
     --ip-range {{ ip_abc }}.0/24 \
     --gateway {{ ip_abc }}.254 \
     {{ kuma-demo }}
   ```

## Set up the control plane

1. **Start the control plane**

   Run the Kuma control plane in a Docker container:
   
   ```sh
   docker run \
     --detach \
     --name {{ kuma-demo }}-control-plane \
     --hostname control-plane \
     --network {{ kuma-demo }} \
     --ip {{ ip_abc }}.1 \
     --publish 25681:5681 \
     --volume ${{ KUMA_DEMO_TMP }}:/demo \
     {{ docker_org }}/kuma-cp:{{ version_full }} run
   ```
   
   You can now access the [{{ Kuma }} user interface (GUI)]({{ docs }}/production/gui/) at <http://localhost:25681/gui>

2. **Configure kumactl**

   To use {{ kumactl }} with our {{ Kuma }} deployment, we need to connect it to the control plane we set up earlier.

   1. **Retrieve the admin token**

      Run the following command to get the admin token from the control plane:

      ```sh
      export {{ KUMA_DEMO_ADMIN_TOKEN }}="$( 
        docker exec --tty --interactive {{ kuma-demo }}-control-plane \
          wget --quiet --output-document - \
          http://localhost:5681/global-secrets/admin-user-token \
          | jq --raw-output .data \
          | base64 --decode
      )"
      ```

   2. **Connect to the control plane**

      Use the retrieved token to link {{ kumactl }} to the control plane:

      ```sh
      kumactl config control-planes add \
        --name {{ kuma-demo }} \
        --address http://localhost:25681 \
        --auth-type tokens \
        --auth-conf "token=${{ KUMA_DEMO_ADMIN_TOKEN }}" \
        --skip-verify
      ```

   3. **Verify the connection**

      Run this command to check if the connection is working:

      ```sh
      kumactl get meshes
      ```

      You should see a list of meshes with one entry: `default`. This confirms the configuration is successful.

3. **Configure the default mesh**

   Set the default mesh to use {{ MeshServices }} in [exclusive mode]({{ docs }}/networking/meshservice/#options). MeshServices are explicit resources that represent destinations for traffic in the mesh. They define which {{ Dataplanes }} serve the traffic, as well as the available ports, IPs, and hostnames. This configuration ensures a clearer and more precise way to manage services and traffic routing in the mesh.

   ```sh
   echo 'type: Mesh
   name: default
   meshServices:
     mode: Exclusive' | kumactl apply --file -
   ```

## Set up services

{% capture code-block-install-required-tools %}
```sh
apt-get update && \
  apt-get install --yes curl iptables
```
{% endcapture %}
{% capture code-block-install-kuma %}
```sh
curl --location {{ url_installer_external }} {% if version == "preview" or page.edition and page.edition != "kuma" %}\
  {% endif %}| VERSION="{{ version_full }}" sh -

mv {{ kuma }}-{{ version_full }}/bin/* /usr/local/bin/
```
{% endcapture %}
{% capture code-block-add-kuma-dp-user %}
```sh
useradd --uid {{ tproxy.defaults.kuma-dp.uid }} --user-group {{ kuma-dp }}
```
{% endcapture %}
{% capture warning-run-inside-container %}
{%- capture warning-run-inside-container-msg -%}
**Important:** The following steps must be executed inside the container.
{%- endcapture -%}
{% if page.edition and page.edition != "kuma" %}
{:.important.no-icon}
> {{ warning-run-inside-container-msg }}

{% else %}
{% warning %}{{ warning-run-inside-container-msg }}{% endwarning %}
{% endif %}
{% endcapture %}
{% capture warning-tproxy-command-run-inside-container %}
{% warning %}
**Important:** Make sure this command is executed **inside the container**. It changes iptables rules to redirect all traffic to the data plane proxy. Running it on your computer or a virtual machine without the data plane proxy can disrupt network connectivity. On a virtual machine, this might lock you out until you restart it.
{% endwarning %}
{% endcapture %}

### Redis

1. **Generate a data plane token**

   Generate a token that the Redis data plane proxy will use to authenticate with the control plane.
   
   ```sh
   kumactl generate dataplane-token \
     --tag "kuma.io/service=redis" \
     --valid-for 720h \
     > ${{ KUMA_DEMO_TMP }}/token-redis
   ```

2. **Start the Redis container**

   ```sh
   docker run \
     --detach \
     --name {{ kuma-demo }}-redis \
     --hostname redis \
     --network {{ kuma-demo }} \
     --ip {{ ip_abc }}.2 \
     --volume ${{ KUMA_DEMO_TMP }}:/demo \
     redis:7.4.1 redis-server --protected-mode no
   ```

3. **Prepare the Redis container**

   Enter the container to run further commands.

   {% if version != "preview" %}
   ```sh
   docker exec --tty --interactive --privileged {{ kuma-demo }}-redis bash
   ```
   {% else %}
   ```sh
   docker exec \
     --tty \
     --interactive \
     --privileged \
     --env {{ KUMA_PREVIEW_VERSION }} \
     {{ kuma-demo }}-redis bash
   ```
   {% endif %}

   {{ warning-run-inside-container | indent }}

   1. **Set a zone name**

      Give the Redis instance a zone name. The demo application will use this name to show which Redis instance is being accessed.

      ```sh
      redis-cli set zone local-demo-zone
      ```

   2. **Install required tools**

      Install the necessary tools for downloading {{ Kuma }} binaries and setting up the [transparent proxy]({{ docs }}/networking/transparent-proxy/introduction/):

      - `curl`: Needed to download the {{ Kuma }} binaries.
      - `iptables`: Required to configure the transparent proxy.

      Run the following command:

      {{ code-block-install-required-tools | indent | indent }}

   3. **Install {{ Kuma }}**

      Now, install {{ Kuma }} and move its binaries to `/usr/local/bin/` so they are accessible to all users:

      {{ code-block-install-kuma | indent | indent }}

   4. **Create a separate user for the data plane proxy**

      {{ code-block-add-kuma-dp-user | indent | indent }}

   5. **Start the data plane proxy**

      ```sh
      runuser --user {{ kuma-dp }} -- \
        /usr/local/bin/kuma-dp run \
        --cp-address https://control-plane:5678 \
        --dataplane-token-file /demo/token-redis \
        --dataplane-file /demo/dataplane.yaml \
        --dataplane-var "name=redis" \
        --dataplane-var "address={{ ip_abc }}.2" \
        --dataplane-var "port=6379" \
        --dataplane-var "protocol=tcp" \
        > /demo/logs-data-plane-proxy-redis.log 2>&1 &
      ```

   6. **Install the transparent proxy**

      {{ warning-tproxy-command-run-inside-container | indent | indent }}

      ```sh
      kumactl install transparent-proxy \
        --config-file /demo/config-transparent-proxy.yaml \
        > /demo/logs-transparent-proxy-install-redis.log 2>&1
      ```

   7. **Exit the container**

      Redis is now set up and running. You can safely exit the container as the configuration is complete:

      ```sh
      exit
      ```

4. **Check if service is running**

   To confirm the service is set up correctly and running, use the {{ kumactl }} to inspect the services:
   
   ```sh
   kumactl inspect services
   ```
   
   The output should show a single service, `redis`, with the status `Online`.
   
   You can also open the [{{ Kuma }} GUI]({{ docs }}/production/gui/) at <http://localhost:25681/gui/meshes/default/services/mesh-services>. Look for the `redis` service, and verify that its state is `Available`.

### Demo Application

The steps are the same as those explained earlier, with only the names changed. We won’t repeat the explanations here, but you can refer to the [Redis service](#redis) instructions if needed.

1. **Generate a data plane token**

   ```sh
   kumactl generate dataplane-token \
     --tag "kuma.io/service=demo-app" \
     --valid-for 720h \
     > ${{ KUMA_DEMO_TMP }}/token-demo-app
   ```

2. **Start the application container**

   ```sh
   docker run \
     --detach \
     --name {{ kuma-demo }}-app \
     --hostname demo-app \
     --network {{ kuma-demo }} \
     --ip {{ ip_abc }}.3 \
     --publish 25000:5000 \
     --volume ${{ KUMA_DEMO_TMP }}:/demo \
     --env "REDIS_HOST=redis.svc.mesh.local" \
     kumahq/kuma-demo
   ```

3. **Prepare the application container**

   Enter the container to run further commands.

   ```sh
   docker exec \
     --tty \
     --interactive \
     --privileged \
     --workdir /root \{% if version == "preview" %}
     --env {{ KUMA_PREVIEW_VERSION }} \{% endif %}
     {{ kuma-demo }}-app bash
   ```

   {{ warning-run-inside-container | indent }}

   1. **Install required tools**

      {{ code-block-install-required-tools | indent | indent }}

   2. **Install {{ Kuma }}**

      {{ code-block-install-kuma | indent | indent }}

   3. **Create a separate user for the data plane proxy**

      {{ code-block-add-kuma-dp-user | indent | indent }}

   4. **Start the data plane proxy**

      ```sh
      runuser --user {{ kuma-dp }} -- \
        /usr/local/bin/kuma-dp run \
        --cp-address https://control-plane:5678 \
        --dataplane-token-file /demo/token-demo-app \
        --dataplane-file /demo/dataplane.yaml \
        --dataplane-var "name=demo-app" \
        --dataplane-var "address={{ ip_abc }}.3" \
        --dataplane-var "port=5000" \
        --dataplane-var "protocol=http" \
        > /demo/logs-data-plane-proxy-demo-app.log 2>&1 &     
      ```

   5. **Install the transparent proxy**

      {{ warning-tproxy-command-run-inside-container | indent | indent }}

      ```sh
      kumactl install transparent-proxy \
        --config-file /demo/config-transparent-proxy.yaml \
        > /demo/logs-transparent-proxy-install-demo-app.log 2>&1
      ```

   6. **Exit the container**

      Demo application is now set up and running. You can safely exit the container as the configuration is complete:

      ```sh
      exit
      ```

## Introduction to zero-trust security

By default, the network is **insecure and unencrypted**. With {{ Kuma }}, you can enable the [Mutual TLS (mTLS)]({{ docs }}/policies/mutual-tls/) policy to secure the network. This works by setting up a Certificate Authority (CA) that automatically provides TLS certificates to your services (specifically to the data plane proxies running next to each service).

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
    type: builtin' | kumactl apply --file -
```

After enabling mTLS, all traffic is **encrypted and secure**. However, you can no longer access the `demo-app` directly, meaning <http://localhost:25000> will no longer work. This happens for two reasons:

1. When mTLS is enabled, {{ Kuma }} doesn’t create traffic permissions by default. This means no traffic will flow until you define a {{ MeshTrafficPermission }} policy to allow `demo-app` to communicate with `redis`.

2. When you try to call `demo-app` using a browser or other HTTP client, you are essentially acting as an external client without a valid TLS certificate. Since all services are now required to present a certificate signed by the `ca-1` Certificate Authority, the connection is rejected. Only services within the `default` mesh, which are assigned valid certificates, can communicate with each other.

To address the first issue, you need to apply an appropriate {{ MeshTrafficPermission }} policy:

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
      action: Allow' | kumactl apply --file -
```

The second issue is a bit more challenging. You can’t just get the necessary certificate and set up your web browser to act as part of the mesh. To handle traffic from outside the mesh, you need a _gateway proxy_. You can use tools like [Kong](https://github.com/Kong/kong), or you can use the [Built-in Gateway]({{ docs }}/using-mesh/managing-ingress-traffic/builtin/) that {{ Kuma }} provides.

{% tip %}
**Note:** For more information, see the [Managing incoming traffic with gateways]({{ docs }}/using-mesh/managing-ingress-traffic/overview/) section in the documentation.
{% endtip %}

In this guide, we’ll use the built-in gateway. It allows you to configure a data plane proxy to act as a gateway and manage external traffic securely.

### Setting up the built-in gateway

The built-in gateway works like the data plane proxy for a regular service, but it requires its own configuration. Here’s how to set it up step by step.

1. **Create a Dataplane resource**

   For regular services, we reused a single {{ Dataplane }} configuration file and provided dynamic values (like names and addresses) when starting the data plane proxy. This made it easier to scale or deploy multiple instances. However, since we’re deploying only one instance of the gateway, we can simplify things by hardcoding all the values directly into the file, as shown below:
   
   ```sh
   echo 'type: Dataplane
   mesh: default
   name: gateway-instance-1
   networking:
     address: {{ ip_abc }}.4
     gateway:
       type: BUILTIN
       tags:
         kuma.io/service: gateway' > ${{ KUMA_DEMO_TMP }}/dataplane-gateway.yaml
   ```
   
   If you prefer to keep the flexibility of dynamic values, you can use the same template mechanisms for the gateway's {{ Dataplane }} configuration as you did for regular services.

2. **Generate a data plane token**

   The gateway proxy requires a data plane token to securely register with the control plane. You can generate the token using the following command:
   
   ```sh
   kumactl generate dataplane-token \
     --tag "kuma.io/service=gateway" \
     --valid-for 720h \
     > ${{ KUMA_DEMO_TMP }}/token-gateway
   ```

3. **Start the gateway container**

   With the configuration and token in place, you can start the gateway proxy as a container:
   
   ```sh
   docker run \
     --detach \
     --name {{ kuma-demo }}-gateway \
     --hostname gateway \
     --network {{ kuma-demo }} \
     --ip {{ ip_abc }}.4 \
     --publish 25001:5000 \
     --volume ${{ KUMA_DEMO_TMP }}:/demo \
     {{ docker_org }}/kuma-dp:{{ version_full }} run \
       --cp-address https://control-plane:5678 \
       --dataplane-token-file /demo/token-gateway \
       --dataplane-file /demo/dataplane-gateway.yaml \
       --dns-enabled="false"
   ```
   
   This command starts the gateway proxy and registers it with the control plane. However, the gateway is not yet ready to route traffic.

4. **Configure the gateway with {{ MeshGateway }}**

   To enable the gateway to accept external traffic, configure it with a {{ MeshGateway }}. This setup defines listeners that specify the port, protocol, and tags for incoming traffic, allowing policies like {{ MeshHTTPRoute }} or {{ MeshTCPRoute }} to route traffic to services.
   
   Apply the configuration:
   
   ```sh
   echo 'type: MeshGateway
   mesh: default
   name: gateway
   selectors:
   - match:
       kuma.io/service: gateway
   conf:
     listeners:
     - port: 5000
       protocol: HTTP
       tags:
         port: http-5000' | kumactl apply --file -
   ```

   This sets up the gateway to listen on port `5000` using the HTTP protocol and adds a tag (`port: http-5000`) to identify this listener in routing policies.

   You can test the gateway by visiting <http://localhost:25001/>. You should see a message saying no routes match this {{ MeshGateway }}. This means the gateway is running, but no routes are set up yet to handle traffic.

5. **Create a route to connect the gateway to `demo-app`**

   To route traffic from the gateway to the service, create a {{ MeshHTTPRoute }} policy:
   
   ```sh
   echo 'type: MeshHTTPRoute
   name: gateway-demo-app-route
   mesh: default
   spec:
     targetRef:
       kind: MeshGateway
       name: gateway
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
             name: demo-app' | kumactl apply --file -
   ```

   This route connects the gateway and its listener (`port: http-5000`) to the `demo-app` service. It forwards any requests with the path prefix `/` to `demo-app`.

   After setting up this route, the gateway will try to send traffic to `demo-app`. However, if you test it by visiting <http://localhost:25001>, you’ll see:

   ```
   RBAC: access denied
   ```
   {:.no-line-numbers}

   This happens because there is no {{ MeshTrafficPermission }} policy allowing traffic from the gateway to `demo-app`. You’ll need to create one in the next step.

6. **Allow traffic from the gateway to `demo-app`**

   To fix the `RBAC: access denied` error, create a {{ MeshTrafficPermission }} policy to allow the gateway to send traffic to `demo-app`:
   
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
           kuma.io/service: gateway
       default:
         action: Allow' | kumactl apply --file -
   ```
   
   This policy allows traffic from the gateway to `demo-app`. After applying it, you can access <http://localhost:25001>, and the traffic will reach the `demo-app` service successfully.

## Cleanup

To clean up your environment, remove the Docker containers, network, temporary directory, and the control plane configuration from {{ kumactl }}. Run the following commands:

```sh
kumactl config control-planes remove --name {{ kuma-demo }}

docker rm --force \
   {{ kuma-demo }}-control-plane \
   {{ kuma-demo }}-redis \
   {{ kuma-demo }}-app \
   {{ kuma-demo }}-gateway

docker network rm {{ kuma-demo }}

rm -rf "${{ KUMA_DEMO_TMP }}"
```