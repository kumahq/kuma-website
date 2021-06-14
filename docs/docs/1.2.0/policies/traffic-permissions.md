# Traffic Permissions

This policy provides access control rules that determine the service traffic that's allowed across the [Mesh](../mesh).

Traffic permissions require you to enable [Mutual TLS](../mutual-tls) on the [`Mesh`](../mesh). If mTLS is not enabled, all service traffic is allowed. 

When Mutual TLS is disabled, Kuma **will not** enforce any `TrafficPermission` and by default it will allow all service traffic to work. Even if [Mutual TLS](../mutual-tls) is disabled, we can still create and edit `TrafficPermission` resources that will go into effect once Mutual TLS is enabled on the Mesh.

:::tip
The reason why this policy only works when [Mutual TLS](../mutual-tls) is enabled in the Mesh is because only in this scenario Kuma can validate the identity of the service traffic via the usage of data plane proxy certificates. 

On the other end when Mutual TLS is disabled, Kuma cannot extract the service identity from the request and therefore cannot perform any validation.
:::

Kuma creates a default `TrafficPermission` policy that allows all the communication between all the services when a new `Mesh` is created.

## Usage

You can determine what source services are allowed to consume specific destination services. The service field is mandatory in both sources and destinations.

::: tip
**Match-All**: You can match any value of a tag by using `*`, like `version: '*'`.
:::

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  name: allow-all-traffic
spec:
  sources:
    - match:
        kuma.io/service: '*'
  destinations:
    - match:
        kuma.io/service: '*'
```
We will apply the configuration with `kubectl apply -f [..]`.
:::
::: tab "Universal"
```yaml
type: TrafficPermission
name: allow-all-traffic
mesh: default
sources:
  - match:
      kuma.io/service: '*'
destinations:
  - match:
      kuma.io/service: '*'
```
We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/1.1.6/documentation/http-api).
:::
::::

You can use any [Tag](/docs/1.1.6/documentation/dps-and-data-model/#tags) in both `sources` and `destinations` selector, which makes `TrafficPermissions` quite powerful when it comes to creating a secure environment for our services.

## Traffic Permission with External Services

`TrafficPermission` policy can also be used to restrict the traffic to [services outside the mesh](external-services.md).

### Prerequisites

In this case, we cannot rely on mTLS, because there is no data plane proxy on the destination side.

The prerequisite to use `TrafficPermission` with `ExternalService` is to first lock the traffic in the mesh, so a request to an unknown destination is not allowed.
To lock the traffic, Kuma must be deployed with [Transparent Proxy](../networking/transparent-proxying.md) (it's the default setting on Kubernetes). Additionally, `Mesh` has to be configured to [disable the passthrough mode](http://localhost:8080/docs/1.1.6/policies/mesh/#usage).

### Usage

First, we define the `ExternalService` to a service which is not in the mesh.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: ExternalService
mesh: default
metadata:
  name: httpbin
spec:
  tags:
    kuma.io/service: httpbin
    kuma.io/protocol: http
  networking:
    address: httpbin.org:443
    tls:
      enabled: true
```
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
  address: httpbin.org:443
  tls:
    enabled: true
```
:::
::::

We can then apply the `TrafficPermission` policy. In the destination section, we can use all the tags defined in `ExternalService`.

For example, to enable the traffic from the data plane proxies of service `web` or `backend` to our new `ExternalService`, we can apply the following policy

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  name: backend-to-httpbin
spec:
  sources:
    - match:
        kuma.io/service: web
    - match:
        kuma.io/service: backend
  destinations:
    - match:
        kuma.io/service: httpbin
```
:::
::: tab "Universal"
```yaml
type: TrafficPermission
name: backend-to-httpbin
mesh: default
sources:
  - match:
    kuma.io/service: web
  - match:
      kuma.io/service: backend
destinations:
  - match:
      kuma.io/service: httpbin
```
:::
::::

Keep in mind that the `ExternalService` has [the same rules](how-kuma-chooses-the-right-policy-to-apply.md) for matching policies as any other service in the mesh.
Kuma will pick the most specific `TrafficPermission` for every `ExternalService`.

