# Traffic Permissions

This policy provides access control rules that can be applied on our service traffic to determine what traffic is allowed across the [Mesh](../mesh) via configurable sources and destinations.

The `TrafficPermission` policy **only works** when [Mutual TLS](../mutual-tls) is enabled on the [`Mesh`](../mesh). 

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
We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/0.7.3/documentation/http-api).
:::
::::

You can use any [Tag](/docs/0.7.3/documentation/dps-and-data-model/#tags) in the `destinations` selector, which makes `TrafficPermissions` quite powerful when it comes to creating a secure environment for our services.

::: warning
For the time being the `sources` field only allows the `service` tag. This limitation will be removed in the future.
:::
