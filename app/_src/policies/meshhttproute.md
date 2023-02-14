---
title: Mesh HTTP Route (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [TrafficRoute](../traffic-route).
{% endwarning %}

The `MeshHTTPRoute` policy allows altering and redirecting HTTP requests
depending on where the request coming from and where it's going to.

{% if_version lte:2.1.x %}
{% warning %}
`MeshHTTPRoute` does not route cross-zone traffic yet!
{% endwarning %}
{% endif_version %}

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅        | ❌  | ❌   |
| MeshSubset        | ✅        | ❌  | ❌   |
| MeshService       | ✅        | ✅  | ❌   |
| MeshServiceSubset | ✅        | ❌  | ❌   |

If you don't understand this table you should read [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

Unlike others outbound policies `MeshHTTPRoute` doesn't contain `default` directly in the `to` array.
The `default` section is nested inside `rules`, so the policy structure looks like this:

```yaml
spec:
  targetRef: # top-level targetRef selects a group of proxies to configure
    kind: Mesh|MeshSubset|MeshService|MeshServiceSubset
  to:
    - targetRef: # targetRef selects a destination (outbound listener)
        kind: MeshService
        name: backend
      rules:
        - matches: [...] # various ways to match an HTTP request (path, method, query)
          default: # configuration applied for the matched HTTP request
            filters: [...]
            backendRefs: [...]
```

### Matches

Only one entry in `matches` must match for the rule to be applied.
Each entry must have one or more match types set. Every set field must match for the entry
to match.

- **`path`** - (optional) - HTTP path to match the request on
{% if_version gte:2.3.x %}
  - **`type`** - one of `Exact`, `PathPrefix`, `RegularExpression`
{% endif_version %}
{% if_version lte:2.2.x %}
  - **`type`** - one of `Exact`, `Prefix`, `RegularExpression`
{% endif_version %}
  - **`value`** - actual value that's going to be matched depending on the `type`
- **`method`** - (optional) - HTTP2 method, available values are 
  `CONNECT`, `DELETE`, `GET`, `HEAD`, `OPTIONS`, `PATCH`, `POST`, `PUT`, `TRACE`
- **`queryParams`** list of HTTP URL query parameters. Every entry must match
  for `queryParams` to match.
  - **`type`** one of `Exact` or `RegularExpression`
  - **`name`**
  - **`value`**
- **`headers`** list of header matches. Every entry must match for `headers` to
  match.
  - **`type`** one of `Exact`,`Present`,`RegularExpression`,`Absent`,`Prefix`
  - **`name`**
  - **`value`** should be unset if `type` is `Present` or `Absent`

### Default conf

- **`filters`** a list of modifications applied to the matched request
  - **`type`** available values are `RequestHeaderModifier`, `ResponseHeaderModifier`,
    `RequestRedirect`, `URLRewrite`. The filter field corresponding to the type must
    then be set.
  - **`requestHeaderModifier`** [HeaderModifier](#headermodifier)
  - **`responseHeaderModifier`** [HeaderModifier](#headermodifier)
  - **`requestRedirect`**
    - **`scheme`** (optional) one of `http` or `http2`
    - **`hostname`** (optional) is the fully qualified domain name of a network host. This
      matches the RFC 1123 definition of a hostname with 1 notable exception that
      numeric IP addresses are not allowed.
    - **`port`** (optional) is the port to be used in the value of the `Location` header in
      the response. When empty, port (if specified) of the request is used.
    - **`statusCode`** (optional) is the HTTP status code to be used in response. Available values are
      `301`, `302`, `303`, `307`, `308`.
    - **`path`** (optional)
      - **`type`** is one of `ReplaceFullPath`, `ReplacePrefixMatch`
      - **`replaceFullPath`**
      - **`replacePrefixMatch`** requires using a path prefix match.
  - **`urlRewrite`** must be set if the `type` is `URLRewrite`
    - **`hostname`** (optional) is the fully qualified domain name of a network host. This
      matches the RFC 1123 definition of a hostname with 1 notable exception that
      numeric IP addresses are not allowed.
    - **`path`** (optional)
      - **`type`** is one of `ReplaceFullPath`, `ReplacePrefixMatch`
      - **`replaceFullPath`**
      - **`replacePrefixMatch`** requires using a path prefix match.
- **`backendRefs`** (optional) list of destination for request to be redirected to
  - **`kind`** one of `MeshService`, `MeshServiceSubset`
  - **`name`** service name
  - **`tags`** (optional) service tags, must be specified if the `kind` is `MeshServiceSubset`
  - **`weight`** when a request matches the route, the choice of an upstream cluster
    is determined by its weight. Total weight is a sum of all weights in `backendRefs` list.

### HeaderModifier

- **`set`** list of headers to set. Overrides value if the header exists.
  - **`name`** header's name
  - **`value`** header's value
- **`add`** list of headers to add. Appends value if the header exists.
  - **`name`** header's name
  - **`value`** header's value
- **`remove`** list of header names to remove

## Examples

### Traffic split

We can use `MeshHTTPRoute` to split an HTTP traffic between services with different tags
implementing A/B testing or canary deployments.

Here is an example of a `MeshHTTPRoute` that splits the traffic from
`frontend_kuma-demo_svc_8080` to `backend_kuma-demo_svc_3001` between versions,
but only on endpoints starting with `/api`. All other endpoints will go to version: `1.0`.

{% tabs split useUrlFragment=false %}
{% tab split Kubernetes %}

{% if_version gte:2.3.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: http-route-1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```
{% endif_version %}
{% if_version lte:2.2.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: http-route-1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: Prefix
                value: /api
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```
{% endif_version %}

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab split Universal %}

{% if_version gte:2.3.x %}
```yaml
type: MeshHTTPRoute
name: http-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```
{% endif_version %}
{% if_version lte:2.2.x %}
```yaml
type: MeshHTTPRoute
name: http-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api
          default:
            backendRefs:
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "1.0"
                weight: 90
              - kind: MeshServiceSubset
                name: backend_kuma-demo_svc_3001
                tags:
                  version: "2.0"
                weight: 10
```
{% endif_version %}

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

### Traffic modifications

We can use `MeshHTTPRoute` to modify outgoing requests, by setting new path
or changing request and response headers.

Here is an example of a `MeshHTTPRoute` that adds `x-custom-header` with value `xyz`
when `frontend_kuma-demo_svc_8080` tries to consume `backend_kuma-demo_svc_3001`.

{% tabs modifications useUrlFragment=false %}
{% tab modifications Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: http-route-1
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: Exact
                value: /
          default:
            filters:
              - type: RequestHeaderModifier
                requestHeaderModifier:
                  set:
                    - name: x-custom-header
                      value: xyz
```
We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab modifications Universal %}

```yaml
type: MeshHTTPRoute
name: http-route-1
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend_kuma-demo_svc_8080
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_3001
      rules:
        - matches:
            - path:
                type: Exact
                value: /
          default:
            filters:
              - type: RequestHeaderModifier
                requestHeaderModifier:
                  set:
                    - name: x-custom-header
                      value: xyz
```
We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

## Merging

When several `MeshHTTPRoute` policies target the same data plane proxy they're merged.
Similar to the new policies the merging order is determined by
[the top level targetRef](/docs/{{ page.version }}/policies/targetref#merging-configuration).
The difference is in `spec.to[].rules`.
{{site.mesh_product_name}} treats `rules` as a key-value map
where `matches` is a key and `default` is a value. For example MeshHTTPRoute policies:

```yaml
# MeshHTTPRoute-1
rules:
  - matches: # key-1
      - path:
          type: Exact
          name: /orders
        method: GET
    default: CONF_1 # value
  - matches: # key-2
      - path:
          type: Exact
          name: /payments
        method: POST
    default: CONF_2 # value
---
# MeshHTTPRoute-2
rules:
  - matches: # key-3
      - path:
          type: Exact
          name: /orders
        method: GET
    default: CONF_3 # value
  - matches: # key-4
      - path:
          type: Exact
          name: /payments
        method: POST
    default: CONF_4 # value
```

merged in the following list of rules:

```yaml
rules:
  - matches:
      - path:
          type: Exact
          name: /orders
        method: GET
    default: merge(CONF_1, CONF_3) # because 'key-1' == 'key-3'
  - matches:
      - path:
          type: Exact
          name: /payments
        method: POST
    default: merge(CONF_2, CONF_4) # because 'key-2' == 'key-4'
```

## All policy options

{% policy_schema MeshHTTPRoute %}
