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

## Matching

`TrafficPermission` is an [Inbound Connection Policy](how-kuma-chooses-the-right-policy-to-apply.md#inbound-connection-policy).
You can use all the tags in both `sources` and `destinations` sections.
