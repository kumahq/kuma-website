---
title: Configure a built-in gateway
description: Deploy and configure built-in gateways using MeshGateway, MeshHTTPRoute, and MeshTCPRoute for ingress traffic.
keywords:
  - builtin gateway
  - ingress
  - MeshGateway
---

The built-in gateway is configured using a combination of [`MeshGateway`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners), [`MeshHTTPRoute`](/docs/{{ page.release }}/policies/meshhttproute) and [`MeshTCPRoute`](/docs/{{ page.release }}/policies/meshtcproute),
and served by Envoy instances represented by `Dataplanes` configured as built-in
gateways. {{ site.mesh_product_name }} policies are then used to configure
built-in gateways.

{% tip %}
**New to {{site.mesh_product_name}}?**
Checkout our [guide](/docs/{{ page.release }}/guides/gateway-builtin/) to get quickly started with builtin gateways.
{% endtip %}

### Deploying gateways

The process for deploying built-in gateways is different depending on whether
you're running in Kubernetes or Universal mode.

{% tabs %}
{% tab Kubernetes %}

For managing gateway instances on Kubernetes, {{site.mesh_product_name}} provides a
[`MeshGatewayInstance`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-k8s) CRD.

{% tip %}
This resource launches `kuma-dp` in your cluster.
If you are running a multi-zone {{ site.mesh_product_name }}, `MeshGatewayInstance` needs to be created in a specific zone, not the global cluster.
See the [dedicated section](#multi-zone) for using built-in gateways on
multi-zone.
{% endtip %}

This resource manages a Kubernetes `Deployment` and `Service`
suitable for providing service capacity for the `MeshGateway`{% if_version lte:2.6.x inline:true %} with the matching `kuma.io/service` tag{% endif_version %}.

{% if_version lte:2.6.x %}
The `kuma.io/service` value you select will be used in `MeshGateway` to [configure listeners](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners).

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
```
{% endif_version %}
{% if_version gte:2.7.x %}

[//]: # (This is change in behavior, let's assume that users will get used to it, so we won't have to show this warning after 2.9.x)
{% if_version lte:2.9.x %}

{% warning %}
**Heads up!**
In previous versions of {{site.mesh_product_name}}, setting the `kuma.io/service` tag directly within a `MeshGatewayInstance` resource was used to identify the service. However, this practice is deprecated and no longer recommended for security reasons since {{site.mesh_product_name}} version 2.7.0.

We've automatically switched to generating the service name for you based on your `MeshGatewayInstance` resource name and namespace (format: `{name}_{namespace}_svc`).
{% endwarning %}

{% endif_version %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
```
{% endif_version %}

See [the `MeshGatewayInstance` docs](/docs/{{ page.release }}//using-mesh/managing-ingress-traffic/builtin-k8s) for more options.
{% endtab %}
{% tab Universal %}

You'll need to create a `Dataplane` object for your gateway:

```yaml
type: Dataplane
mesh: default
name: gateway-instance-1
networking:
  address: 127.0.0.1
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

Note that this gateway has an identifying `kuma.io/service` tag.

Now you need to explicitly run `kuma-dp`:

```shell
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-gateway \ # this needs to be generated like for regular Dataplane
  --dataplane-file=my-gateway.yaml # the Dataplane resource described above
```

{% endtab %}
{% tab setup Kubernetes without MeshGatewayInstance %}

Using `MeshGatewayInstance` is highly recommended. If for any reason you are
unable to use `MeshGatewayInstance` to deploy builtin gateways, you can manually create a `Deployment` and `Service`
to manage `kuma-dp` instances and forward traffic to them.
Keep in mind however, that you'll need to keep the listeners of your
`MeshGateway` in sync with your `Service`.

{% tip %}
These instructions will use the resources created by `MeshGatewayInstance` with
version 2.6.2 as a
guide but remember to create a `MeshGatewayInstance` _for your version_ to configure as
much as you can and use it as a basis for these self-managed resources.
{% endtip %}

Given a `MeshGateway` spec:

```yaml
spec:
  conf:
    listeners:
    - port: 80
      protocol: HTTP
  selectors:
  - match:
      kuma.io/service: demo-app_gateway
```

#### `Service`

The `Service` will forward traffic to the `kuma-dp` we'll configure in the next
section. Its `ports` need to be in sync with the `MeshGateway` `listeners`.

```yaml
metadata:
  annotations:
    kuma.io/gateway: builtin
  name: demo-app-gateway
  namespace: kuma-demo
spec:
  ports:
  - name: "80"
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: demo-app-gateway
```

The `selector` should match the `Pod` template created in the next section.

#### `Deployment`

The `Deployment` we'll create will manage running some number of `kuma-dp`
instances that are configured to serve traffic for your `MeshGateway`.

We'll cover just `spec.selector` and `spec.template` here because
other parts of the `Deployment` can be configured arbitrarily.
Most importantly you'll need to change:

* `kuma.io/tags` annotation - must match the `MeshGateway` `selectors`
* `KUMA_CONTROL_PLANE_CA_CERT` environment variable - can be retrieved with `kubectl get secret {{site.mesh_product_name_path}}-tls-cert -n {{site.mesh_namespace}} -o=jsonpath='{.data.ca\.crt}' | base64 -d`
* `containers[0].image` field - should be the version of {{site.mesh_product_name}} you're using

Make sure `containers[0].resources` is appropriate for your use case.

```yaml
  selector:
    matchLabels:
      app: demo-app-gateway
  template:
    metadata:
      annotations:
        kuma.io/gateway: builtin
        kuma.io/mesh: default
        kuma.io/tags: '{"kuma.io/service":"demo-app_gateway"}'
      creationTimestamp: null
      labels:
        app: demo-app-gateway
        kuma.io/sidecar-injection: disabled
    spec:
      containers:
      - args:
        - run
        - --log-level=info
        - --concurrency=2
        env:
        - name: INSTANCE_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: KUMA_CONTROL_PLANE_CA_CERT
          value: |
            -----BEGIN CERTIFICATE-----
            MIIDDzCCAfegAwIBAgIQJlMQnmK1ZfnjhDt1KvTvQTANBgkqhkiG9w0BAQsFADAS
            MRAwDgYDVQQDEwdrdW1hLWNhMB4XDTI0MDQxNTEyMzkxNFoXDTM0MDQxMzEyMzkx
            NFowEjEQMA4GA1UEAxMHa3VtYS1jYTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
            AQoCggEBALp6skN+nPPRQQ7Z2ZH4eDjcTtKnO/9n/ExM99tRuMgZCdaZe7zp5g6L
            1wvdgi3mtOlplplFaYvLlC9QPn6A7TQSCOPd28vhTIqoUhZ4V7yjr54h0bn6wmH+
            BdVXgnalXDb+mQtyDF4dvAY3f0QyOQAK3TjRp32OX+dYKsGGWtch1yiIPf7VnWPx
            4/K2v4DTjRuDcXg6S0x4GskGZ9zAhR1WJYEa/2uM+XBmy0GmF9INn0WOeje7Jf3c
            G5tCd+fPP6qEk5Q+tBVHd7Pz3xfD9TZjIfY1+h00UkpC50n/yE5FDK8aUpR17SUc
            QKJUskOivKAqRD1pI9zfhnHBJ2URfbcCAwEAAaNhMF8wDgYDVR0PAQH/BAQDAgKk
            MB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAPBgNVHRMBAf8EBTADAQH/
            MB0GA1UdDgQWBBQRT2hdjPpIt/FzcLJo/EWPFafCQzANBgkqhkiG9w0BAQsFAAOC
            AQEAO0Gfe750KCk+gMtBQHfHzEyQocO2qg2JXfZrBP/+rqeozbjXQj0BLYR9NXnp
            tLrxJHoBHdeE+TOnTFsxB7IRIkF1njEElKX4DVx7MjZCL1qLeWDuaXQmEgtFoWDM
            o4NqPZ4BIyuZZ9IVtYdeod5g5ucRopOP66zWr/RuwKFzdzni79BGaWuA3dNmLWcn
            MdsbZ165hdXstF6b48yPFKFrOdGgLpJheSCLlR/6vp5a+pA03fQZ6qV2j2uSqvAm
            XYl8Q3CdoI/yAX9p4mxkcYK7xaz0fQTrD/UyGD6l2cXgY90NP6LDAW1oYKHSD7Qc
            Y8vutIcexOtJfAdTZ3/GxBxH1Q==
            -----END CERTIFICATE-----
        - name: KUMA_CONTROL_PLANE_URL
          value: https://{{site.mesh_cp_name}}.{{site.mesh_namespace}}:5678
        - name: KUMA_DATAPLANE_DRAIN_TIME
          value: 30s
        - name: KUMA_DATAPLANE_MESH
          value: default
        - name: KUMA_DATAPLANE_RUNTIME_TOKEN_PATH
          value: /var/run/secrets/kubernetes.io/serviceaccount/token
        - name: KUMA_DNS_CORE_DNS_BINARY_PATH
          value: coredns
        - name: KUMA_DNS_CORE_DNS_EMPTY_PORT
          value: "15054"
        - name: KUMA_DNS_CORE_DNS_PORT
          value: "15053"
        - name: KUMA_DNS_ENABLED
          value: "true"
        - name: KUMA_DNS_ENABLE_LOGGING
          value: "false"
        - name: KUMA_DNS_ENVOY_DNS_PORT
          value: "15055"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: KUMA_DATAPLANE_RESOURCES_MAX_MEMORY_BYTES
          valueFrom:
            resourceFieldRef:
              containerName: kuma-gateway
              divisor: "0"
              resource: limits.memory
        image: docker.io/{{ site.mesh_docker_org }}/kuma-dp:2.6.2
        livenessProbe:
          failureThreshold: 12
          httpGet:
            path: /ready
            port: 9901
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        name: kuma-gateway
        readinessProbe:
          failureThreshold: 12
          httpGet:
            path: /ready
            port: 9901
            scheme: HTTP
          initialDelaySeconds: 1
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: "1"
            ephemeral-storage: 1G
            memory: 512Mi
          requests:
            cpu: 50m
            ephemeral-storage: 50M
            memory: 64Mi
        securityContext:
          allowPrivilegeEscalation: false
          runAsGroup: 5678
          runAsUser: 5678
        volumeMounts:
        - mountPath: /tmp
          name: tmp
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "0"
      volumes:
      - emptyDir: {}
        name: tmp
```

{% endtab %}
{% endtabs %}

{% tip %}
{{site.mesh_product_name}} gateways are configured with the [Envoy best practices for edge proxies](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge).
{% endtip %}

### Multi-zone

The {{site.mesh_product_name}} Gateway resource types, `MeshGateway`, [`MeshHTTPRoute`](/docs/{{ page.release }}/policies/meshhttproute) and [`MeshTCPRoute`](/docs/{{ page.release }}/policies/meshtcproute), are synced across zones by the {{site.mesh_product_name}} control plane.
If you have a multi-zone deployment, follow existing {{site.mesh_product_name}} practice and create any {{site.mesh_product_name}} Gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it is needed by deploying built-in gateway `Dataplanes` (in Universal zones) or `MeshGatewayInstances` (Kubernetes zones).

See the [multi-zone docs](/docs/{{ page.release }}/production/deployment/multi-zone/) for a
refresher.
