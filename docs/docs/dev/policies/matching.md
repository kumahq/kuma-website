# Policy Matching
## Matrix
| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ✅   | ❌    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ❌   | ✅    |
| MeshServiceSubset | ✅         | ❌   | ❌    |
| MeshGatewayRoute  | ❌         | ❌   | ❌    |
| MeshHTTPRoute     | ❌         | ❌   | ❌    |

The above matrix indicates which entity types (`Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset`, `MeshGatewayRoute`, `MeshHTTPRoute`) a policy supports
and where they can be placed (top level, to level, from level).

Looking at the structure of the `spec` field of a policy, `targetRef` can be used in multiple places:

```yaml
apiVersion: kuma.io/v1alpha1
kind: PolicyType
...
spec:
  targetRef: # top level
    kind: Mesh | MeshSubset | MeshService | MeshServiceSubset
    # ...
  to:
    - targetRef: # "to"
        kind: Mesh
      # ...
  from:
    - targetRef: # "from"
        kind: MeshService
      # ...
```

and the table defines which type is available in each place.

In this example:
- top level can be one of `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset`
- to level can only be `Mesh`
- from level can only be `MeshService`

A policy might not support every level
(e.g. `MeshTrace` only allows top level `targetRef`).

A combination of a policy and the top level `targetRef` can influence which types are available in `to` and `from` levels
(e.g. `MeshAccessLog` with a top level `targetRef` of `MeshGatewayRoute` can only have `from` level because there is no outbound listener).

If a policy does not support a level then every type will be marked with ❌ in that level
and the YAML configuration must omit that field from the definition.

# targetRef levels

Top level `targetRef` defines which set of proxies a policy will affect.
`Top` level `targetRef` defines which set of proxies a policy will affect (.i.e: the set of proxies whose configuration is getting modified).
`To` level `targetRef` defines rules that applies to outgoing traffic of proxies selected by the `Top` level `targetRef`.
`From` level `targetRef` defines rules that applies to incoming traffic of proxies selected by the `Top` level `targetRef`.
`From` level `targetRef` defines rules for incoming traffic relative to the top level.

Consider the example below:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: example
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef: # top level targetRef
    kind: MeshService
    name: web-frontend
  to:
    - targetRef: # to level targetRef
        kind: MeshService
        name: web-backend
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: '/tmp/logs.txt'
  from:
    - targetRef: # from level targetRef
        kind: Mesh
        name: default
      default:
        backends:
          - file:
              format:
                plain: '{"start_time": "%START_TIME%"}'
              path: '/tmp/logs.txt'
```

This policy will target all proxies that implement the service `web-frontend`.
It logs traffic **coming** from `web-backend` to `web-frontend`.
It also logs traffic going out of proxies that implement `web-frontend` to **anything** in the `Mesh`.
