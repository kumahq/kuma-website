---
title: MeshLoadBalancingStrategy
---

{% warning %}
This policy uses new policy matching algorithm.
{% endwarning %}

This policy enables {{site.mesh_product_name}} to configure the load balancing strategy for traffic between services in the mesh.
When using this policy, the [localityAwareLoadBalancing](/docs/{{ page.version }}/policies/locality-aware) flag is ignored.

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endtab %}

{% tab targetRef Delegated Gateway %}
| `targetRef`           | Allowed kinds                                            |
| --------------------- | -------------------------------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`                                    |
{% endtab %}

{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ✅  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/introduction).

## Configuration

{% if_version lte:2.4.x %}
### LocalityAwareness

Locality-aware load balancing is enabled by default unlike its predecessor [localityAwareLoadBalancing](/docs/{{ page.version }}/policies/locality-aware).

- **`disabled`** – (optional) allows to disable locality-aware load balancing. When disabled requests are distributed 
across all endpoints regardless of locality.

{% endif_version %}
{% if_version gte:2.5.x %}
### LocalityAwareness
Locality-aware load balancing provides robust and straightforward method for balancing traffic within and across zones. This not only allows you to route traffic across zones when the local zone service is unhealthy but also enables you to define traffic prioritization within the local zone and set cross-zone fallback priorities.

#### Default behaviour
Locality-aware load balancing is enabled by default, unlike its predecessor [localityAwareLoadBalancing](/docs/{{ page.version }}/policies/locality-aware). Requests are distributed across all endpoints within the local zone first unless there are not enough healthy endpoints.

#### Disabling locality aware routing
If you do so, all endpoints regardless of their zone will be treated equally. To do this do:

```yaml
localityAwareness:
  disabled: true
```

#### Configuring LocalityAware Load Balancing for traffic within the same zone
{% warning %}
If `crossZone` and/or `localZone` is defined, they take precedence over `disabled` and apply more specific configuration.
{% endwarning %}

Local zone routing allows you to define traffic routing rules within a local zone, prioritizing data planes based on tags and their associated weights. This enables you to allocate specific traffic percentages to data planes with particular tags within the local zone. If there are no healthy endpoints within the highest priority group, the next priority group takes precedence. Locality awareness within the local zone relies on tags within inbounds, so it's crucial to ensure that the tags used in the policy are defined for the service (Dataplane object on Universal, PodTemplate labels on Kubernetes).

- **`localZone`** - (optional) allows to define load balancing priorities between dataplanes in the local zone. When not defined, traffic is distributed equally to all endpoints within the local zone.
  - **`affinityTags`** - list of tags and their weights based on which traffic is load balanced
    - **`key`** - defines tag for which affinity is configured. The tag needs to be configured on the inbound of the service. In case of Kubernetes, pod needs to have a label. On Universal user needs to define it on the inbound of the service. If the tag is absent this entry is skipped.
    - **`weight`** - (optional) weight of the tag used for load balancing. The bigger the weight the higher number of requests is routed to dataplanes with specific tag. By default we will adjust them so that 90% traffic goes to first tag, 9% to next, and 1% to third and so on.

#### Configuring LocalityAware Load Balancing for traffic across zones
{% warning %}
Remember that cross-zone traffic requires [mTLS to be enabled](/docs/{{ page.version}}/policies/mutual-tls).
{% endwarning %}
Advanced locality-aware load balancing provides a powerful means of defining how your service should behave when there is no instances of your service available or they are in a degraded state in your local zone. With this feature, you have the flexibility to configure the fallback behavior of your service, specifying the order in which it should attempt fallback options and defining different behaviors for instances located in various zones.

- **`crossZone`** - (optional) allows to define behaviour when there is no healthy instances of the service. When not defined, cross zone traffic is disabled.
  - **`failover`** - defines a list of load balancing rules in order of priority. If a zone is not specified explicitly by name or implicitly using the type `Any`/`AnyExcept` it is excluded from receiving traffic. By default, the last rule is always `None` which means, that there is no traffic to other zones after specified rules.
    - **`from`** - (optional) defines the list of zones to which the rule applies. If not specified, rule is applied to all zones.
      - **`zones`** - list of zone names.
    - **`to`** - defines to which zones the traffic should be load balanced.
      - **`type`** - defines how target zones will be picked from available zones. Available options:
        - **`Any`** - traffic will be load balanced to every available zone.
        - **`Only`** - traffic will be load balanced only to zones specified in zones list.
        - **`AnyExcept`** - traffic will be load balanced to every available zone except those specified in zones list.
        - **`None`** - traffic will not be load balanced to any zone.
      - **`zones`** - list of zone names
  - **`failoverThreshold.percentage`** - (optional) defines the percentage of live destination data plane proxies below which load balancing to the next priority starts. .e.g: If you have this set to 70 and you have 10 data plane proxies it will start load balancing to the next priority when the number of healthy destinations falls under 7. The value to be in (0.0 - 100.0] range (Default 50). If the value is a double number, put it in quotes.

#### Zone Egress support

Using Zone Egress Proxy in multizone deployment poses certain limitations for this feature. When configuring `MeshLoadbalancingStrategy` with Zone Egress you can only use `Mesh` as a top level targetRef. This is because we don't differentiate requests that come to Zone Egress from different clients, yet. 

Moreover, Zone Egress is a simple proxy that uses long-lived L4 connection with each Zone Ingresses. Consequently, when a new `MeshLoadbalancingStrategy` with locality awareness is configured, connections won’t be refreshed, and locality awareness will apply only to new connections.

Another thing you need to be aware of is how outbound traffic behaves when you use the `MeshCircuitBreaker`'s outlier detection to keep track of healthy endpoints. Normally, you would use `MeshCircuitBreaker` to act on failures and trigger traffic redirect to the next priority level if the number of healthy endpoints fall below `crossZone.failoverThreshold`. When you have a single instance of Zone Egress, all remote zones will be behind a single endpoint. Since `MeshCircuitBreaker` is configured on Data Plane Proxy, when one of the zones start responding with errors it will mark the whole Zone Egress as not healthy and won’t send traffic there even though there could be multiple zones with live endpoints. This will be changed in the future with overall improvements to the Zone Egress proxy.


{% endif_version %}

### LoadBalancer

- **`type`** - available values are `RoundRobin`, `LeastRequest`, `RingHash`, `Random`, `Maglev`.

#### RoundRobin

RoundRobin is a load balancing algorithm that distributes requests across available upstream hosts in round-robin order.

#### LeastRequest

`LeastRequest` selects N random available hosts as specified in `choiceCount` (2 by default) and picks the host which has 
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
    - **`ttl`** - (optional) if specified, a cookie with this _time to live_ will be generated if the cookie is not present.
    - **`path`** - (optional) the name of the path for the cookie.
  - **`connection`**:
    - **`sourceIP`** - if true, then hashing is based on a source IP address.
  - **`queryParameter`**:
    - **`name`** - the name of the URL query parameter that will be used to obtain the hash key. If the parameter is not 
    present, no hash will be produced. Query parameter names are case-sensitive.
  - **`filterState`**:
    - **`key`** the name of the Object in the per-request `filterState`, which is an `Envoy::Hashable` object. If there is 
    no data associated with the key, or the stored object is not `Envoy::Hashable`, no hash will be produced.

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
    - **`ttl`** - (optional) if specified, a cookie with this _time to live_ will be generated if the cookie is not present.
    - **`path`** - (optional) the name of the path for the cookie.
  - **`connection`**:
    - **`sourceIP`** - if true, then hashing is based on a source IP address.
  - **`queryParameter`**:
    - **`name`** - the name of the URL query parameter that will be used to obtain the hash key. If the parameter is not
      present, no hash will be produced. Query parameter names are case-sensitive.
  - **`filterState`**:
    - **`key`** the name of the Object in the per-request `filterState`, which is an `Envoy::Hashable` object. If there is
      no data associated with the key, or the stored object is not `Envoy::Hashable`, no hash will be produced.

## Examples

### RingHash load balancing from web to backend

Load balance requests from `web` to `backend` based on the HTTP header `x-header`:

{% policy_yaml ring-hash use_meshservice=true %}
```yaml
type: MeshLoadBalancingStrategy
name: ring-hash
mesh: mesh-1
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 8080
        sectionName: http
      default:
        loadBalancer:
          type: RingHash
          ringHash:
            hashPolicies:
              - type: Header
                header:
                  name: x-header
```
{% endpolicy_yaml %}

### Disable locality-aware load balancing for backend

Requests to `backend` will be spread evenly across all zones where `backend` is deployed.

{% policy_yaml disable-la-to-backend use_meshservice=true %}
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
        namespace: kuma-demo
        _port: 8080
        sectionName: http
      default:
        localityAwareness:
          disabled: true
```
{% endpolicy_yaml %}

{% if_version gte:2.5.x %}
### Disable cross zone traffic and prioritize traffic the dataplanes on the same node and availability zone

In this example, whenever a user sends a request to the `backend` service, 90% of the requests will arrive at the instance with the same value of the `k8s.io/node` tag, 9% of the requests will go to the instance with the same value as the caller of the `k8s.io/az` tag, and 1% will go to the rest of the instances.

{% policy_yaml local-zone-affinity-backend use_meshservice=true %}
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
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: k8s.io/node
              - key: k8s.io/az
```
{% endpolicy_yaml %}

### Disable cross zone traffic and route to the local zone instances equally

In this example, when a user sends a request to the backend service, the request is routed equally to all instances in the local zone. If there are no instances in the local zone, the request will fail because there is no cross zone traffic.

{% policy_yaml local-zone-affinity-backend-2 use_meshservice=true %}
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
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        localityAwareness:
          localZone:
            affinityTags: []
```
{% endpolicy_yaml %}

or 

{% policy_yaml local-zone-affinity-backend-3 use_meshservice=true %}
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
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        localityAwareness:
          localZone: {}
```
{% endpolicy_yaml %}

### Route within the local zone equally, but specify cross zone order

Requests to the backend service will be evenly distributed among all endpoints within the local zone. If there are fewer than 25% healthy hosts in the local zone, traffic will be redirected to other zones. Initially, traffic will be sent to the `us-1` zone. In the event that the `us-1` zone becomes unavailable, traffic will then be directed to all zones, except for `us-2` and `us-3`. If these zones are also found to have unhealthy hosts, the traffic will be rerouted to `us-2` and `us-3`.

{% policy_yaml cross-zone-backend use_meshservice=true %}
```yaml
type: MeshLoadBalancingStrategy
name: cross-zone-backend
mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        localityAwareness:
          crossZone:
            failover:
              - to:
                  type: Only
                  zones: ["us-1"]
              - to:
                  type: AnyExcept
                  zones: ["us-2", "us-3"]
              - to:
                  type: Any
            failoverThreshold:
              percentage: 25
```
{% endpolicy_yaml %}

### Prioritize traffic to data planes within the same data center and fallback cross zone in specific order

Requests to backend will be distributed based on weights, with 99.9% of requests routed to data planes in the same data center, 0.099% to data planes in the same region, and the remainder to other local instances.

When no healthy backends are available within the local zone, traffic from data planes in zones `us-1`, `us-2`, and `us-3` will only fall back to zones `us-1`, `us-2`, and `us-3`, while in zones `eu-1`, `eu-2`, and `eu-3` will only fall back to zones `eu-1`, `eu-2`, and `eu-3`. If there are no healthy instances in all zones `eu-[1-3]` or `us-[1-3]`, requests from any instance will then fall back to `us-4`. If there are no healthy instances in `us-4`, the request will fail, as the last rule, by default, has a type of `None`, meaning no fallback is allowed.

{% policy_yaml local-zone-affinity-cross-backend %}
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
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        localityAwareness:
          localZone:
            affinityTags:
              - key: kubernetes.io/hostname
                weight: 9000
              - key: topology.kubernetes.io/zone
                weight: 9
          crossZone:
            failover:
              - from: 
                  zones: ["us-1", "us-2", "us-3"]
                to:
                  type: Only
                  zones: ["us-1", "us-2", "us-3"]
              - from:
                  zones: ["eu-1", "eu-2", "eu-3"]
                to:
                  type: Only
                  zones: ["eu-1", "eu-2", "eu-3"]
              - to:
                  type: Only
                  zones: ["us-4"]
```
{% endpolicy_yaml %}
{% endif_version %}

## Load balancing HTTP traffic through zone proxies

If you proxy HTTP traffic through zone proxies (zone ingress/egress), you may notice that the traffic does not reach every instance of the destination service.
In the case of in-zone traffic (without zone proxies on a request path), the client is aware of all server endpoints, so if you have 10 server endpoints the traffic goes to all of them.
In the case of cross-zone traffic, the client is only aware of zone ingress endpoints, so if you have 10 server endpoints and 1 zone ingress, the client only sees one zone ingress endpoint.
Because zone ingress is just a TCP passthrough proxy (it does not terminate TLS), it only load balances TCP connections over server endpoints.

HTTP traffic between Envoys is upgraded to HTTP/2 automatically for performance benefits. The client's Envoy leverages HTTP/2 multiplexing therefore it opens only a few TCP connections.

You can mitigate this problem by adjusting `max_requests_per_connection` setting on Envoy Cluster. For example

{% policy_yaml local-zone-affinity-backend-4 %}
```yaml
type: MeshProxyPatch
name: max-requests-per-conn
mesh: mesh-1
spec:
  targetRef:
    kind: Mesh
  default:
    appendModifications:
      - cluster:
          operation: Patch
          match:
            name: demo-app_kuma-demo_svc_5000
            origin: outbound
          value: |
            max_requests_per_connection: 1
```
{% endpolicy_yaml %}

This way, we allow only one in-flight request on a TCP connection. Consequently, the client will open more TCP connections, leading to fairer load balancing.
The downside is that we now have to establish and maintain more TCP connections. Keep this in mind as you adjust the value to suit your needs.

## All policy options

{% json_schema MeshLoadBalancingStrategies %}
