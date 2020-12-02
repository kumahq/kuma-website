# External Service

This policy enables consuming services that are not part of the mesh from services running inside it. The default [passthrough](/docs//policies/mesh/#controlling-the-passthrough-mode) cluster will allow for accessing any non-mesh host by its domain name or IP address. As the name of the feature suggests, this pattern leaves the mesh administrator with no tools to aply any policies for such traffic. Therefore, ExternalService resource allows for declaring the desired external resource as a named service within the mesh and enabling the observability, security and traffic manipulation similar to any other service in the mesh.

## The ExternalService resource

A simple HTTP service can be defined as follows

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: ExternalService
mesh: default
metadata:
  namespace: default
  name: httpbin
spec:
  tags:
    kuma.io/service: httpbin
    kuma.io/protocol: http
  networking:
    address: httpbin.org:80
    tls:
      enabled: false
```

We will apply the configuration with `kubectl apply -f [..]`.

Consuming an external service in from within the mesh can be done using the standard `.mesh` name resolving, for example `httpbin.mesh`. 
:::

::: tab "Universal"
```yaml
type: ExternalService
mesh: default
name: httpbin
tags:
  kuma.io/service: httpbin
  kuma.io/protocol: http
networking:
  address: httpbin.org:80
  tls:
    enabled: false
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/0.7.2/documentation/http-api).

Consuming an external service in from within the mesh can be done by filling the proper `outbound` section of the relevant dataplane resource:

```yaml
type: Dataplane
mesh: default
name: redis-dp
networking:
  address: 127.0.0.1
  inbound:
  - port: 9000
    tags:
      kuma.io/service: redis
  outbound:
  - port: 10000
    tags:
      kuma.io/service: httpbin
```

Then `httpbin.org` will be accessible at `127.0.0.1:10000`.

:::
:::: 

 * `tags` the external service can include an arbitrary number of tags, where `kuma.io/service` is a mandatory one. The special `kuma.io/protocol` tag is also taken into account and supports the standard Kuma protocol values. It designates the specific protocol being used by that service.
 * ` networking` describes the networking configuration of the external service 
   * `address` is the address where the external service can be reached.
   * `tls` is the section to configure the TLS originator when consuming the external service
     * `enabled` turns on and off the TLS origination. Defaults to `true`
     * `caCert` the CA certificate for the external service TLS verification
     * `clientCert` the client certificate for mTLS
     * `clientKey` the client key for mTLS
 
::: tip
As with other services, avoid overlapping of service names under `kuma.io/service` with already existing ones. A good practice would be to derive the tag value from the domain name or IP of the actual external service.
:::

