# Traffic Permissions

This policy provides access control rules to define the traffic that is allowed within the [Mesh](../mesh). To allow traffic from the mesh to an external service, you configure a [TrafficRoute policy](../traffic-route).

Traffic permissions requires [Mutual TLS](../mutual-tls) enabled on the [`Mesh`](../mesh). 

If Mutual TLS is disabled, Kuma allows all service traffic. Mutual TLS is required for Kume to validate the service identity with data plane proxy certificates.

Kuma creates a default `TrafficPermission` policy that allows all communication between all services in a new `Mesh`.

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
Apply the configuration with `kubectl apply -f [..]`.
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
Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/1.1.6/documentation/http-api).
:::
::::

You can use any [Tag](/docs/1.1.6/documentation/dps-and-data-model/#tags) with the `sources` and `destinations` selectors. This approach supports fine-grained access control that lets you define the right levels of security for your services.

## Traffic Permission with External Services

The `TrafficPermission` policy can also be used to restrict traffic to [services outside the mesh](external-services).

### Prerequisites

* Kuma deployed with [transparent proxying](../networking/transparent-proxying)
* `Mesh` configured to [disable passthrough mode](docs/1.2.0/policies/mesh/#usage)

These settings lock down traffic to and from the mesh, so requests to any unknown destination are not allowed. The mesh can't rely on mTLS, because there is no data plane proxy on the destination side.

### Usage

First, define the `ExternalService` for a service that is not in the mesh.

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

Then apply the `TrafficPermission` policy. In the destination section, specify all the tags defined in `ExternalService`.

For example, to enable the traffic from the data plane proxies of service `web` or `backend` to the new `ExternalService`, apply:

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

Remember, the `ExternalService` follows [the same rules](how-kuma-chooses-the-right-policy-to-apply.md) for matching policies as any other service in the mesh -- Kuma selects the most specific `TrafficPermission` for every `ExternalService`.

