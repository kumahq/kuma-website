---
title: MeshAccessLog (beta)
---

{% warning %}
This policy uses the new policy matching algorithm and is in beta state.
It should not be mixed with [`TrafficLog`](../traffic-log).
{% endwarning %}

`MeshAccessLog` can be used to configure traffic logging in the Envoy sidecar.

## Destination

Logs can be sent to either a file:

```yaml
spec:
  file:
    path: /tmp/accesslog
    format: ...
```

or over TCP:

```yaml
spec:
  tcp:
    address: 127.0.0.1:5000
    format: ...
```

## Format

Logs can be either plain text or JSON.
Both format types are supported with both destination types.

### Operators

In both cases, lines are formatted using special operators that inject information about
the request/traffic.
All [those provided by Envoy are](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)
supported. Kuma provides some additional operators:

| Command Operator                     | Description                                                      |
| ------------------------------------ | ---------------------------------------------------------------- |
| `%KUMA_MESH%`                        | name of the mesh in which traffic is flowing                     |
| `%KUMA_SOURCE_SERVICE%`              | name of a `service` that is the `source` of traffic              |
| `%KUMA_DESTINATION_SERVICE%`         | name of a `service` that is the `destination` of traffic         |
| `%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%` | address of a `Dataplane` that is the `source` of traffic         |
| `%KUMA_TRAFFIC_DIRECTION%`           | direction of the traffic, `INBOUND`, `OUTBOUND` or `UNSPECIFIED` |

#### External traffic

Any traffic that is sent out of the mesh is logged with
`%KUMA_DESTINATION_SERVICE%` `"external"` and `%UPSTREAM_HOST%` containing the
IP of the destination. In order to log external traffic, you must use `spec.to.targetRef.kind: Mesh`.

#### Builtin gateway

In order to log traffic from a builtin gateway, you must use `spec.to.targetRef.kind: Mesh`.

### Plain text

Plain text logs are configured using a format string:

```yaml
spec:
  file:
    format:
      plain: "[%START_TIME%] %KUMA_DESTINATION_SERVICE%"
```

### JSON

With JSON logging, you provide keys and corresponding values that
define the JSON object:

```yaml
spec:
  tcp:
    format:
      json:
        - key: time
          value: %START_TIME%
        - key: destination
          value: %KUMA_DESTINATION_SERVICE%
```

### Traffic protocol

All operators can be used regardless of the type of traffic. Be sure to
label your services with the correct `kuma.io/protocol`.

Operators that don't apply to the used protocol are replaced by `-`.

## `targetRef`

Top-level `spec.targetRef` selects which services log traffic.

Log outgoing traffic by adding an entry to `spec.to`. You can refine this by
destination service using `targetRef.kind: MeshService`.

Incoming traffic can be logged by adding an entry to `spec.from`
but it cannot be filtered based on source and thus only `targetRef.kind: Mesh`
is supported.

## Supported `targetRef` kinds

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ✅   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ✅  | ❌   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |

## Examples

This policy configures `kuma.io/service: demo-client` sidecars to log traffic the service
sends to `demo-backend` as JSON and forward the logs to `127.0.0.1:9999` over TCP:

```yaml
kind: MeshAccessLog
apiVersion: kuma.io/v1alpha1
name: client-out
spec:
  targetRef:
    kind: MeshService
    name: demo-client
  to:
    - targetRef:
        kind: MeshService
        name: demo-backend
      default:
        backends:
          - tcp:
              format:
                json:
                  - key: Source
                    value: "%KUMA_SOURCE_SERVICE%"
                  - key: Destination
                    value: "%KUMA_DESTINATION_SERVICE%"
                  - key: Start
                    value: "%START_TIME(%s)%"
              address: "127.0.0.1:9999"
```

An example log line might be:

```json
{
  "Source": "demo-client",
  "Destination": "demo-backend",
  "Start": "1527590590"
}
```
