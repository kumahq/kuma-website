---
title: MeshLoadBalancingStrategy (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state.
{% endwarning %}

This policy enables {{site.mesh_product_name}} to configure the load balancing strategy 
for traffic between services in the mesh. Also, [localityAwareLoadBalancing](/docs/{{ page.version }}/policies/locality-aware) 
flag is going to be replaced by the current policy and will be deprecated in the future releases.  

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ✅  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

### LocalityAwareness

Locality-aware load balancing is enabled by default unlike its predecessor [localityAwareLoadBalancing](/docs/{{ page.version }}/policies/locality-aware).

- **`disabled`** – (optional) allows to disable locality-aware load balancing. When disabled requests are distributed 
across all endpoints regardless of locality.

{% if_version gte:2.5.x %}
### Advanced LocalityAwareness
Advanced locality-aware load balancing provides a more robust and straightforward method for balancing traffic within and across zones. This not only allows you to route traffic to a cross zone when the local zone service is unhealthy but also enables you to define traffic prioritization within the local zone and set cross-zone fallback priorities.

#### LocalZone
Local zone routing allows you to specify how traffic should be routed within a local zone, prioritizing certain data planes based on tags and their associated weights. This enables you to allocate specific percentages of traffic to data planes with particular tags within the local zone. If there are no healthy endpoints within the group with the highest priority, the next priority group becomes the highest group.

- **`localZone`** - (optional) allows to define load balancing priorities between dataplanes in the local zone. When not defined traffic is distributed equally to all endpoints within the local zone.
  - **`affinityTags`** - list of tags and their weights based on which traffic is loadbalanced
    - **`key`** - defines tag for which affinity is configured. The tag needs to be configured on the inbound of the service.
    - **`weight`** - (optional) weight of the tag used for load balancing. The bigger the weight the higher number of requests is routed to dataplanes with specific tag. By default we will adjust them so that 90% traffic goes to first tag, 9% to next, and 1% to third and so on.

#### CrossZone
Advanced locality-aware load balancing provides a powerful means of defining how your service should behave when there is no service available in your local zone. With this feature, you have the flexibility to configure the fallback behavior of your service, specifying the order in which it should attempt fallback options and defining different behaviors for instances located in various zones. 

- **`crossZone`** - (optional) allows to define behaviour when there is no healthy instances of the service. When not defined, cross zone traffic is disabled.
  - **`failover`** - defines list of load balancing rules in order of priority. If a zone is not specified explicitly or by type `Any`, by default zone is excluded from the traffic. 
    - **`from`** - (optional) defines the list of zones to which the rule applies. If not specified, rule is applied to all zones.
      - **`zones`** - list of zones.
    - **`to`** - defines to which zones the traffic should be load balanced.
      - **`type`** - defines how target zones will be picked from available zones. Available options:
        - **`Any`** - traffic will be load balanced to every available zone.
        - **`Only`** - traffic will be load balanced only to zones specified in zones list.
        - **`AnyExcept`** - traffic will be load balanced to every available zone except these specified in zones list.
        - **`None`** - traffic will not be load balanced to any zone.
      - **`zones`** - names of zones
  - **`failoverThreshold.percentage`** - (optional) defines the percentage of live destination dataplane proxies below which load balancing to the next priority starts. Default: 50%

{% endif_version %}

### LoadBalancer

- **`type`** - available values are `RoundRobin`, `LeastRequest`, `RingHash`, `Random`, `Maglev`.

#### RoundRobin

RoundRobin is a load balancing algorithm that distributes requests across available upstream hosts in round-robin order.

#### LeastRequest

LeastRequest selects N random available hosts as specified in 'choiceCount' (2 by default) and picks the host which has 
the fewest active requests.

- **`choiceCount`** - (optional) is the number of random healthy hosts from which the host with the fewest active requests will 
be chosen. Defaults to 2 so that Envoy performs two-choice selection if the field is not set.

#### RingHash

RingHash  implements consistent hashing to upstream hosts. Each host is mapped onto a circle (the “ring”) by hashing its 
address; each request is then routed to a host by hashing some property of the request, and finding the nearest 
corresponding host clockwise around the ring.

- **`hashFunction`** - (optional) available values are `XX_HASH`, `MURMUR_HASH_2`. Default is `XX_HASH`.
- **`minRingSize`** - (optional) minimum hash ring size. The larger the ring is (that is, the more hashes there are for 
each provided host) the better the request distribution will reflect the desired weights. Defaults to 1024 entries, and 
limited to 8M entries.
- **`maxRingSize`** - (optional) maximum hash ring size. Defaults to 8M entries, and limited to 8M entries, but can be 
lowered to further constrain resource use.
- **`hashPolicies`** - (optional) specify a list of request/connection properties that are used to calculate a hash.
These hash policies are executed in the specified order. If a hash policy has the “terminal” attribute set to true, and 
there is already a hash generated, the hash is returned immediately, ignoring the rest of the hash policy list.
  - **`type`** - available values are `Header`, `Cookie`, `Connection`, `QueryParameter`, `FilterState`
  - **`terminal`** - is a flag that short-circuits the hash computing. This field provides a ‘fallback’ style of 
  configuration: “if a terminal policy doesn’t work, fallback to rest of the policy list”, it saves time when the 
  terminal policy works. If true, and there is already a hash computed, ignore rest of the list of hash polices.
  - **`header`**: 
    - **`name`** - the name of the request header that will be used to obtain the hash key.
  - **`cookie`**:
    - **`name`** - the name of the cookie that will be used to obtain the hash key.
    - **`ttl`** - (optional) if specified, a cookie with the TTL will be generated if the cookie is not present.
    - **`path`** - (optional) the name of the path for the cookie.
  - **`connection`**:
    - **`sourceIP`** - if true, then hashing is based on a source IP address.
  - **`queryParameter`**:
    - **`name`** - the name of the URL query parameter that will be used to obtain the hash key. If the parameter is not 
    present, no hash will be produced. Query parameter names are case-sensitive.
  - **`filterState`**:
    - **`key`** – the name of the Object in the per-request filterState, which is an Envoy::Hashable object. If there is 
    no data associated with the key, or the stored object is not Envoy::Hashable, no hash will be produced.

#### Random

Random selects a random available host. The random load balancer generally performs better than round-robin if no health 
checking policy is configured. Random selection avoids bias towards the host in the set that comes after a failed host.

#### Maglev

Maglev implements consistent hashing to upstream hosts. Maglev can be used as a drop in replacement for the ring hash 
load balancer any place in which consistent hashing is desired.

- **`tableSize`** - (optional) the table size for Maglev hashing. Maglev aims for “minimal disruption” rather than an 
absolute guarantee. Minimal disruption means that when the set of upstream hosts change, a connection will likely be 
sent to the same upstream as it was before. Increasing the table size reduces the amount of disruption. The table size 
must be prime number limited to 5000011. If it is not specified, the default is 65537.
- **`hashPolicies`** - (optional) specify a list of request/connection properties that are used to calculate a hash.
  These hash policies are executed in the specified order. If a hash policy has the “terminal” attribute set to true, and
  there is already a hash generated, the hash is returned immediately, ignoring the rest of the hash policy list.
  - **`type`** - available values are `Header`, `Cookie`, `Connection`, `QueryParameter`, `FilterState`
  - **`terminal`** - is a flag that short-circuits the hash computing. This field provides a ‘fallback’ style of
    configuration: “if a terminal policy doesn’t work, fallback to rest of the policy list”, it saves time when the
    terminal policy works. If true, and there is already a hash computed, ignore rest of the list of hash polices.
  - **`header`**:
    - **`name`** - the name of the request header that will be used to obtain the hash key.
  - **`cookie`**:
    - **`name`** - the name of the cookie that will be used to obtain the hash key.
    - **`ttl`** - (optional) if specified, a cookie with the TTL will be generated if the cookie is not present.
    - **`path`** - (optional) the name of the path for the cookie.
  - **`connection`**:
    - **`sourceIP`** - if true, then hashing is based on a source IP address.
  - **`queryParameter`**:
    - **`name`** - the name of the URL query parameter that will be used to obtain the hash key. If the parameter is not
      present, no hash will be produced. Query parameter names are case-sensitive.
  - **`filterState`**:
    - **`key`** – the name of the Object in the per-request filterState, which is an Envoy::Hashable object. If there is
      no data associated with the key, or the stored object is not Envoy::Hashable, no hash will be produced.

## Examples

### RingHash load balancing from web to backend

Load balance requests from `web` to `backend` based on the HTTP header `x-header`:

{% tabs ring-hash useUrlFragment=false %}
{% tab ring-hash Kubernetes %}

```yaml
kind: MeshLoadBalancingStrategy
apiVersion: kuma.io/v1alpha1
metadata:
  name: ring-hash
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: mesh-1
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        loadBalancer:
          type: RingHash
          ringHash:
            hashPolicies:
              - type: Header
                header:
                  name: x-header
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab ring-hash Universal %}

```yaml
type: MeshLoadBalancingStrategy
name: ring-hash
mesh: mesh-1
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        loadBalancer:
          type: RingHash
          ringHash:
            hashPolicies:
              - type: Header
                header:
                  name: x-header
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

### Disable locality-aware load balancing for backend

Requests to `backend` will be spread evenly across all zones where `backend` is deployed.

{% tabs disable-la-to-backend useUrlFragment=false %}
{% tab disable-la-to-backend Kubernetes %}

```yaml
kind: MeshLoadBalancingStrategy
apiVersion: kuma.io/v1alpha1
metadata:
  name: disable-la-to-backend
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          disabled: true
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab disable-la-to-backend Universal %}

```yaml
type: MeshLoadBalancingStrategy
name: disable-la-to-backend
mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          disabled: true
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

{% if_version gte:2.5.x %}
### Disable cross zone traffic and prioritize traffic the dataplanes on the same node and availability zone

Requests to `backend` will be spread based on default weights and won't leave the local zone. 
In this example, whenever user sends a request to `backend` service 90% of requests will arrive to the instance with the same value of `k8s.io/node` tag, 9% of requests to the instance with the same value as caller of tag `k8s.io/az`, and 1% to rest of instances.

{% tabs local-zone-affinity-backend useUrlFragment=false %}
{% tab local-zone-affinity-backend Kubernetes %}

```yaml
kind: MeshLoadBalancingStrategy
apiVersion: kuma.io/v1alpha1
metadata:
  name: local-zone-affinity-backend
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: k8s.io/node
              - key: k8s.io/az
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab local-zone-affinity-backend Universal %}

```yaml
type: MeshLoadBalancingStrategy
name: local-zone-affinity-backend
mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: k8s.io/node
              - key: k8s.io/az
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

### Prioritize traffic to dataplanes within the same datacenter and fallback cross zone in specific order

Requests to backend will be distributed based on weights, with 99.9% of requests routed to data planes in the same datacenter, 0.001% to data planes in the same region, and the remainder to other local instances.

When there are no healthy backends within the local zone, traffic from data planes in zones `us-1`, `us-2`, and `us-3` will only fall back to zones `us-1`, `us-2`, and `us-3`. If there are no healthy instances in these zones, requests from any instance will then fall back to `us-4`. If there are no healthy instances in `us-4`, the request will fail, as the last rule, by default, has type: `None`, meaning no fallback is allowed.

{% tabs local-zone-affinity-cross-backend useUrlFragment=false %}
{% tab local-zone-affinity-cross-backend Kubernetes %}

```yaml
kind: MeshLoadBalancingStrategy
apiVersion: kuma.io/v1alpha1
metadata:
  name: local-zone-affinity-cross-backend
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: infra.io/datacenter
                weight: 9000
              - key: infra.io/region
                weight: 9
        crossZone:
          failover:
            - from: 
                zones: ["us-1", "us-2", "us-3"]
              to:
                type: Only
                zones: ["us-1", "us-2", "us-3"]
            - from:
                zones: ["eu-1", "eu-2", "eu-2"]
              to:
                type: Only
                zones: ["eu-1", "eu-2", "eu-2"]
            - to:
                type: Only
                zones: ["us-4"]
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab local-zone-affinity-cross-backend Universal %}

```yaml
type: MeshLoadBalancingStrategy
name: local-zone-affinity-cross-backend
mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: infra.io/datacenter
                weight: 9000
              - key: infra.io/region
                weight: 9
        crossZone:
          failover:
            - from: 
                zones: ["us-1", "us-2", "us-3"]
              to:
                type: Only
                zones: ["us-1", "us-2", "us-3"]
            - from:
                zones: ["eu-1", "eu-2", "eu-2"]
              to:
                type: Only
                zones: ["eu-1", "eu-2", "eu-2"]
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% endtab %}
{% endtabs %}

{% endif_version %}

## All policy options

{% json_schema MeshLoadBalancingStrategies %}
