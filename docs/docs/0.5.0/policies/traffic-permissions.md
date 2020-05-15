# Traffic Permissions

This policy provides access control rules that can be applied on our service traffic to determine what traffic is allowed across the [Mesh](../mesh) via configurable sources and destinations.

The `TrafficPermission` policy **only works** when [Mutual TLS](../mutual-tls) is enabled on the [`Mesh`](../mesh). 

When Mutual TLS is disabled, Kuma **will not** enforce any `TrafficPermission` and by default it will allow all service traffic to work. Even if [Mutual TLS](../mutual-tls) is disabled, we can still create and edit `TrafficPermission` resources that will go into effect once Mutual TLS is enabled on the Mesh.

:::tip
This policy only works when [Mutual TLS](../mutual-tls) is enabled in the Mesh because only in this scenario Kuma can validate the identity of the service traffic via the usage of data plane proxy certificates. 

On the other end when Mutual TLS is disabled, Kuma cannot extract the service identity from the request and therefore cannot perform any validation.
:::

By default when a new [Mesh](../mesh) resource is being provisioned, Kuma also creates a default `allow-all-traffic` Traffic Permission resource that allows all traffic in the Mesh. By doing so we reduce the risk of unexpectedly interrupting service traffic when Mutual TLS is being enabled on the Mesh.

Although Kuma by default allows all traffic via the `allow-all-traffic` Traffic Permission, we can still create, edit and delete `TrafficPermission` resources to change the default behavior before enabling [Mutual TLS](../mutual-tls) on the Mesh.

The default `TrafficPermission` policy looks like:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  namespace: default
  name: allow-all-traffic
spec:
  sources:
    - match:
        service: '*'
  destinations:
    - match:
        service: '*'
```

The values of `mesh` and `namespace` can vary depending on our environment.
:::
::: tab "Universal"
```yaml
type: TrafficPermission
name: allow-all-traffic
mesh: default
sources:
  - match:
      service: '*'
destinations:
  - match:
      service: '*'
```

The value of `mesh` can vary depending on our environment.
:::
::::



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
  namespace: default
  name: allow-all-traffic
spec:
  sources:
    - match:
        service: 'backend.default.svc:8000'
  destinations:
    - match:
        service: 'redis.default.svc:6379'
        version: '6.0'
```
:::
::: tab "Universal"
```yaml
type: TrafficPermission
name: allow-all-traffic
mesh: default
sources:
  - match:
      service: 'backend'
destinations:
  - match:
      service: 'redis'
      version: '6.0'
```
:::
::::

You can use any [Tag](/docs/0.5.0/documentation/tags/) in the `destinations` object, which makes `TrafficPermissions` quite powerful when it comes to creating a secure environment for our services.

For the time being the `sources` field only allows the `service` tag. This limitation will be removed in the future.
