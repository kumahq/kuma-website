# Locality Aware Load Balancing

A mutli-zone Kuma deployment can enable locality aware load balancing in a particular mesh to ensure optimal service backend routing. This feature relies on the following service tags to make decisions of selecting the destination service endpoint:

 * `kuma.io/region` - optional, denotes a wider region composed of several zones
 * `kuma.io/zone` - automatically set in multi-zone deployments
 * `kuma.io/subzone` - optional, denotes service grouping within a particular zone

## Enabling the Locality Aware Load Balancing

A particular mesh that spans several regions, zones or subzones, may choose to enable locality aware load balancing as follows:

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

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/0.7.2/documentation/http-api).
:::
::::
