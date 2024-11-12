---
title: Installing Transparent Proxy
---

{% assign docs = "/docs/" | append: page.release %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

Here are the steps to set up a transparent proxy for your service. Once set up, your service will run with a transparent proxy, giving you access to {{ Kuma }}'s features like traffic control, observability, and security.

## Prerequisites

{% assign version = page.latest_version.version %}
{% assign ip_ab = "172.56" %}
{% assign ip_abc = ip_ab | append: ".78" %}
{% assign prefix = "kuma-demo" %}
{% assign tmp = "/tmp/" | append: prefix %}

## Step 1: Prepare the environment

1. Prepare temporary directories where we'll store resources like data plane tokens or our Dataplane resource template and where our containers will put logs

   ```sh
   mkdir --parents {{ tmp }}/logs
   ```

   Control plane, data planes and application will use `{{ tmp }}/logs` directory to log, so whenever you'll like to see the logs, go to this directory and look at appropriate file

2. Prepare the `Dataplane` resource which our services data plane proxies will later use and put it in our temporary directory created earlier

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
       redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}' > {{ tmp }}/dataplane.yaml
   ```

3. Create separate docker network for our containers

   We picked addresses in the `{{ ip_abc }}.0/24` range, but you can use whatever ones you want, just remember to update addresses for following steps if you decide to use different one
   
   ```sh
   docker network create \
     --subnet "{{ ip_ab }}.0.0/16" \
     --ip-range "{{ ip_abc }}.0/24" \
     --gateway "{{ ip_abc }}.254" \
     {{ prefix }}
   ```

## Step 2: Prepare the control plane

1. Start control plane

   ```sh
   docker run \
     --detach \
     --name {{ prefix }}-cp \
     --hostname kuma-cp \
     --volume {{ tmp }}:/kuma \
     --network {{ prefix }} \
     --publish "25681:5681" \
     --ip "{{ ip_abc }}.1" \
     kumahq/kuma-cp:{{ version }} run --log-output-path "/kuma/logs/kuma-cp.log"
   ```
   
   You should be able to access GUI on address `https://localhost:25681/gui`

2. Configure `kumactl` to use created earlier control plane

   ```sh
   TOKEN=$(docker exec --tty --interactive {{ prefix }}-cp wget --quiet --output-document - http://localhost:5681/global-secrets/admin-user-token | jq --raw-output .data | base64 --decode) \
   kumactl config control-planes add \
     --name {{ prefix }}-cp \
     --address http://localhost:25681 \
     --auth-type tokens \
     --auth-conf "token=$TOKEN" \
     --skip-verify
   ```

3. Configure our default mesh to use exclusively `MeshServices` to which later allow us to benefit from all benefits it brings

   ```sh
   echo "type: Mesh
   name: default
   meshServices:
     mode: Exclusive" | kumactl apply -f-
   ```

## Step 3: Services

### Redis

1. Generate data plane token

   ```sh
   kumactl generate dataplane-token \
     --tag "kuma.io/service=redis" \
     --valid-for "720h" \
     > {{ tmp }}/token-redis
   ```

2. Start docker container

   ```sh
   docker run \
     --detach \
     --name {{ prefix }}-redis \
     --hostname redis \
     --volume {{ tmp }}:/kuma \
     --network {{ prefix }} \
     --ip "{{ ip_abc }}.2" \
     redis:7.4.1 redis-server --protected-mode no --loglevel verbose
   ```

3. Connect to the container

   ```sh
   docker exec --tty --interactive --privileged {{ prefix }}-redis bash
   ```

4. Prepare the environment

   ```sh
   apt update && apt install -y curl iptables
   curl --location https://kuma.io/installer.sh | VERSION="{{ version }}" sh -
   mv kuma-{{ version }}/bin/* /usr/local/bin/
   useradd --uid {{ tproxy.defaults.kuma-dp.uid }} --user-group {{ tproxy.defaults.kuma-dp.username }}
   ```

5. set zone

   ```sh
   redis-cli set zone local
   ``` 
   
6. Start data plane proxy

   ```sh
   runuser --user kuma-dp -- \
     kuma-dp run \
       --cp-address="https://kuma-cp:5678" \
       --dataplane-token-file="/kuma/token-redis" \
       --dataplane-file="/kuma/dataplane.yaml" \
       --dataplane-var="name=redis" \
       --dataplane-var="address={{ ip_abc }}.2" \
       --dataplane-var="port=6379" \
       --dataplane-var="protocol=tcp" \
       > /kuma/logs/kuma-dp-redis.log 2>&1 &
   ```
   
7. Install transparent proxy

   ```sh
   kumactl install transparent-proxy \
     --verbose \
     --redirect-dns \
     2>&1 | tee /kuma/logs/transparent-proxy-redis.log
   ```

### Demo Application

1. Generate data plane token

   ```sh
   kumactl generate dataplane-token \
     --tag "kuma.io/service=demo-app" \
     --valid-for "720h" \
     > {{ tmp }}/token-demo-app
   ```

2. Start docker container

   ```sh
   docker run \
     --detach \
     --name {{ prefix }}-app \
     --hostname demo-app \
     --volume {{ tmp }}:/kuma \
     --network {{ prefix }} \
     --publish "25000:5000" \
     --ip "{{ ip_abc }}.3" \
     --env "REDIS_HOST=redis.svc.mesh.local" \
     kumahq/kuma-demo
   ```
   
   ```sh
   docker exec --tty --interactive --privileged --workdir /root {{ prefix }}-app bash
   ```

3. Prepare the environment

   ```sh
   apt-get update && apt-get install -y iptables curl
   curl --location https://kuma.io/installer.sh | VERSION="{{ version }}" sh -
   mv kuma-{{ version }}/bin/* /usr/local/bin/
   useradd --uid {{ tproxy.defaults.kuma-dp.uid }} --user-group {{ tproxy.defaults.kuma-dp.username }}
   ```
   
4. Start data plane proxy

   ```sh
   runuser --user kuma-dp -- \
     kuma-dp run \
       --cp-address="https://kuma-cp:5678" \
       --dataplane-token-file="/kuma/token-demo-app" \
       --dataplane-file="/kuma/dataplane.yaml" \
       --dataplane-var="name=demo-app" \
       --dataplane-var="address={{ ip_abc }}.3" \
       --dataplane-var="port=5000" \
       --dataplane-var="protocol=http" \
       > /kuma/logs/kuma-dp-demo-app.log 2>&1 &     
   ```
   
5. Install transparent proxy

   ```sh
   kumactl install transparent-proxy \
     --verbose \
     --redirect-dns \
     2>&1 | tee /kuma/logs/transparent-proxy-demo-app.log
   ```

### Cleanup

```sh
docker rm -f kuma-demo-cp kuma-demo-redis kuma-demo-app
docker network rm kuma-demo
kumactl config control-planes remove --name kuma-demo-cp
rm -rf /tmp/kuma-demo/{logs,dataplane.yaml,token*}
```
