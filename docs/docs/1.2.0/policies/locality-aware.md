# Locality Aware Load Balancing

A [multi-zone deployment](/docs/1.2.0/documentation/deployments/) can enable locality aware load balancing in a particular [Mesh](/docs/1.2.0/policies/mesh/) to ensure optimal service backend routing. This feature relies on the following service tags to make decisions of selecting the destination service endpoint:

 * `kuma.io/region` - optional, denotes a wider region composed of several zones.
 * `kuma.io/zone` - automatically generate in every multi-zone deployment.
 * `kuma.io/subzone` - optional, denotes service grouping within a particular zone.

## Enabling the Locality Aware Load Balancing

A particular `Mesh` that spans several regions, zones or subzones, may choose to enable locality aware load balancing as follows:

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    localityAwareLoadBalancing: true
```

We will apply the configuration with `kubectl apply -f [..]`.
:::

::: tab "Universal"
```yaml
type: Mesh
name: default
routing:
  localityAwareLoadBalancing: true
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/1.2.0/documentation/http-api).
:::
::::
