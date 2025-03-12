---
title: MeshAccessLog
---

With the MeshAccessLog policy you can easily set up access logs on every data plane proxy in a mesh.

{% warning %}
This policy uses a new policy matching algorithm.
Do **not** combine with [TrafficLog](/docs/{{ page.release }}/policies/traffic-log).
{% endwarning %}

{% tip %}
This guide assumes you have already configured your observability tools to work with Kuma.
If you haven't, see the [observability docs](/docs/{{ page.release }}/explore/observability).
{% endtip %}

## `targetRef` support matrix

{% if_version gte:2.4.x %}
{% tabs %}
{% tab Sidecar %}
{% if_version gte:2.4.x %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endif_version %}
{% endif_version %}
{% if_version eq:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService`             |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endif_version %}
{% if_version gte:2.10.x %}
| `targetRef`             | Allowed kinds                                |
| ----------------------- | -------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `Dataplane`                          |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService` |
{% endif_version %}
{% endtab %}

{% tab targetRef Builtin Gateway %}
{% if_version lte:2.5.x %}
| `targetRef`           | Allowed kinds                       |
| --------------------- | ----------------------------------- |
| `targetRef.kind`      | `Mesh`, `MeshSubset`, `MeshService` |
| `to[].targetRef.kind` | `Mesh`, `MeshService`               |
{% endif_version %}
{% if_version gte:2.6.x %}
| `targetRef`             | Allowed kinds                                    |
| ----------------------- | ------------------------------------------------ |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with `tags` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                            |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endif_version %}
{% endtab %}

{% if_version gte:2.6.x %}
{% tab targetRef Delegated Gateway %}
{% if_version gte:2.6.x %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`, `MeshExternalService`             |
{% endif_version %}
{% endtab %}
{% endif_version %}

{% endtabs %}
{% endif_version %}

{% if_version lte:2.3.x %}

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ✅   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ✅  | ❌   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

### Format

Kuma gives you full control over the format of the access logs.

The shape of a single log record is defined by a template string that uses [command operators](https://www.envoyproxy.io/docs/envoy/v1.22.0/configuration/observability/access_log/usage#command-operators) to extract and format data about a `TCP` connection or an `HTTP` request.

For example:

```
%START_TIME% %KUMA_SOURCE_SERVICE% => %KUMA_DESTINATION_SERVICE% %DURATION%
```

`%START_TIME%` and `%KUMA_SOURCE_SERVICE%` are examples of available _command operators_.

All _command operators_ [defined by Envoy](https://www.envoyproxy.io/docs/envoy/v1.22.0/configuration/observability/access_log/usage#command-operators) are supported, along with additional _command operators_ defined by Kuma:

| Command Operator                     | Description                                                      |
|--------------------------------------|------------------------------------------------------------------|
| `%KUMA_MESH%`                        | Name of the mesh in which traffic is flowing.                     |
| `%KUMA_SOURCE_SERVICE%`              | Name of a `service` that is the `source` of traffic.              |
| `%KUMA_DESTINATION_SERVICE%`         | Name of a `service` that is the `destination` of traffic.         |
| `%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%` | Address of a `Dataplane` that is the `source` of traffic.         |
| `%KUMA_TRAFFIC_DIRECTION%`           | Direction of the traffic, `INBOUND`, `OUTBOUND`, or `UNSPECIFIED`. |

All additional access log _command operators_ are valid to use with both `TCP` and `HTTP` traffic.

Internally, Kuma [determines traffic protocol](/docs/{{ page.release }}/policies/protocol-support-in-kuma) based on the value of `kuma.io/protocol` tag on the `inbound` interface of a `destination` `Dataplane`.

There are two types of `format`, `plain` and `json`.

Plain accepts a string with _command operators_ and produces a string output.

JSON accepts a list of key-value pairs that produces a valid JSON object.

It is up to the user to decide which format type to use.
Some system will automatically parse JSON logs and allow you to filter and query based on available keys.

If a _command operator_ is specific to `HTTP` traffic, such as `%REQ(X?Y):Z%` or `%RESP(X?Y):Z%`, in the case of TCP traffic it will be replaced by a symbol "`-`" for `plain` and a `null` value for `json`.
You can set the `format.omitEmptyValues` boolean option to change this to `""` for `plain` and
omit them entirely for `json`.

#### Plain

The default format string for `TCP` traffic is:

```
[%START_TIME%] %RESPONSE_FLAGS% %KUMA_MESH% %KUMA_SOURCE_ADDRESS_WITHOUT_PORT%(%KUMA_SOURCE_SERVICE%)->%UPSTREAM_HOST%(%KUMA_DESTINATION_SERVICE%) took %DURATION%ms, sent %BYTES_SENT% bytes, received: %BYTES_RECEIVED% bytes
```

The default format string for `HTTP` traffic is:

```
[%START_TIME%] %KUMA_MESH% "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%" "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%KUMA_SOURCE_SERVICE%" "%KUMA_DESTINATION_SERVICE%" "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%" "%UPSTREAM_HOST%"
```

Example configuration:

{% if_version lte:2.2.x %}
```yaml
format:
  plain: '[%START_TIME%] %BYTES_RECEIVED%'
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
format:
  type: Plain
  plain: '[%START_TIME%] %BYTES_RECEIVED%'
```
{% endif_version %}

Example output:

```text
[2016-04-15T20:17:00.310Z] 154
```

#### JSON

Example configuration:

{% if_version lte:2.2.x %}
```yaml
format:
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
format:
  type: Json
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
```
{% endif_version %}

Example output:

```json
{
  "start_time": "2016-04-15T20:17:00.310Z",
  "bytes_received": "154"
}
```

<details>
  <summary>TCP configuration with default fields:</summary>

  <div markdown="1" class="code">
{% if_version lte:2.2.x %}
```yaml
format:
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "response_flags"
      value: "%RESPONSE_FLAGS%"
    - key: "kuma_mesh"
      value: "%KUMA_MESH%"
    - key: "kuma_source_address_without_port"
      value: "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%"
    - key: "kuma_source_service"
      value: "%KUMA_SOURCE_SERVICE%"
    - key: "upstream_host"
      value: "%UPSTREAM_HOST%"
    - key: "kuma_destination_service"
      value: "%KUMA_DESTINATION_SERVICE%"
    - key: "duration_ms"
      value: "%DURATION%"
    - key: "bytes_sent"
      value: "%BYTES_SENT%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
format:
  type: Json
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "response_flags"
      value: "%RESPONSE_FLAGS%"
    - key: "kuma_mesh"
      value: "%KUMA_MESH%"
    - key: "kuma_source_address_without_port"
      value: "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%"
    - key: "kuma_source_service"
      value: "%KUMA_SOURCE_SERVICE%"
    - key: "upstream_host"
      value: "%UPSTREAM_HOST%"
    - key: "kuma_destination_service"
      value: "%KUMA_DESTINATION_SERVICE%"
    - key: "duration_ms"
      value: "%DURATION%"
    - key: "bytes_sent"
      value: "%BYTES_SENT%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
```
{% endif_version %}
</div>

</details>

<details>
  <summary>HTTP configuration with default fields:</summary>

<div markdown="1" class="code">
{% if_version lte:2.2.x %}
```yaml
format:
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "kuma_mesh"
      value: "%KUMA_MESH%"
    - key: 'method'
      value: '"%REQ(:METHOD)%'
    - key: "path"
      value: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
    - key: 'protocol'
      value: '%PROTOCOL%'
    - key: "response_code"
      value: "%RESPONSE_CODE%"
    - key: "response_flags"
      value: "%RESPONSE_FLAGS%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
    - key: "bytes_sent"
      value: "%BYTES_SENT%"
    - key: "duration_ms"
      value: "%DURATION%"
    - key: "upstream_service_time"
      value: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
    - key: 'x_forwarded_for'
      value: '"%REQ(X-FORWARDED-FOR)%"'
    - key: 'user_agent'
      value: '"%REQ(USER-AGENT)%"'
    - key: 'request_id'
      value: '"%REQ(X-REQUEST-ID)%"'
    - key: 'authority'
      value: '"%REQ(:AUTHORITY)%"'
    - key: "kuma_source_service"
      value: "%KUMA_SOURCE_SERVICE%"
    - key: "kuma_destination_service"
      value: "%KUMA_DESTINATION_SERVICE%"
    - key: "kuma_source_address_without_port"
      value: "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%"
    - key: "upstream_host"
      value: "%UPSTREAM_HOST%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
format:
  type: Json
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "kuma_mesh"
      value: "%KUMA_MESH%"
    - key: 'method'
      value: '"%REQ(:METHOD)%'
    - key: "path"
      value: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
    - key: 'protocol'
      value: '%PROTOCOL%'
    - key: "response_code"
      value: "%RESPONSE_CODE%"
    - key: "response_flags"
      value: "%RESPONSE_FLAGS%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
    - key: "bytes_sent"
      value: "%BYTES_SENT%"
    - key: "duration_ms"
      value: "%DURATION%"
    - key: "upstream_service_time"
      value: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
    - key: 'x_forwarded_for'
      value: '"%REQ(X-FORWARDED-FOR)%"'
    - key: 'user_agent'
      value: '"%REQ(USER-AGENT)%"'
    - key: 'request_id'
      value: '"%REQ(X-REQUEST-ID)%"'
    - key: 'authority'
      value: '"%REQ(:AUTHORITY)%"'
    - key: "kuma_source_service"
      value: "%KUMA_SOURCE_SERVICE%"
    - key: "kuma_destination_service"
      value: "%KUMA_DESTINATION_SERVICE%"
    - key: "kuma_source_address_without_port"
      value: "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%"
    - key: "upstream_host"
      value: "%UPSTREAM_HOST%"
```
{% endif_version %}
</div>

</details>


### Backends

A backend determines where the logs end up.

#### TCP

A TCP backend streams logs to a server via TCP protocol.
You can configure a TCP backend with an address:

{% if_version lte:2.2.x %}
```yaml
backends:
  - tcp:
      address: 127.0.0.1:5000
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
backends:
  - type: Tcp
    tcp:
      address: 127.0.0.1:5000
```
{% endif_version %}

#### File

A file backend streams logs to a text file.
You can configure a file backend with a path:

{% if_version lte:2.2.x %}
```yaml
backends:
  - file:
      path: /dev/stdout
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
backends:
  - type: File
    file:
      path: /dev/stdout
```
{% endif_version %}

#### OpenTelemetry

An OpenTelemetry (OTel) backend sends data to an OpenTelemetry server.
You can configure an OpenTelemetry backend with an endpoint, [attributes](https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-attributes) (which contain additional information about the log) and [body](https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-body) (can be a string message, including multi-line, or it can be a structured data).
Attributes and endpoints can use placeholders described in the [format section](#format).

{% if_version eq:2.2.x %}
```yaml
backends:
  - openTelemetry:
      endpoint: otel-collector:4317
      body:
        kvlistValue:
          values:
            - key: "mesh"
              value:
                stringValue: "%KUMA_MESH%"
      attributes:
        - key: "start_time"
          value: "%START_TIME%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
backends:
  - type: OpenTelemetry
    openTelemetry:
      endpoint: otel-collector:4317
      body:
        kvlistValue:
          values:
            - key: "mesh"
              value:
                stringValue: "%KUMA_MESH%"
      attributes:
        - key: "start_time"
          value: "%START_TIME%"
```
{% endif_version %}

### Body
Body is of type [any](https://opentelemetry.io/docs/specs/otel/logs/data-model/#type-any) (defined [here](https://github.com/open-telemetry/opentelemetry-proto/blob/342e1d4c3a1fe43312823ffb53bd38327f263059/opentelemetry/proto/common/v1/common.proto#L28-L40))
and can be one of the following forms:

```yaml
body:
  stringValue: "%KUMA_MESH%"
```

```yaml
body:
  boolValue: true
```

```yaml
body:
  intValue: 123
```

```yaml
body:
  doubleValue: 1.2
```

```yaml
body:
  bytesValue: aGVsbG8=
```

```yaml
body:
  arrayValue:
    values:
      - stringValue: "%KUMA_MESH%"
```

```yaml
body:
  kvlistValue:
    values:
      - key: "mesh"
        value:
          stringValue: "%KUMA_MESH%"
```

## Examples

### Log outgoing traffic from specific frontend version to a backend service

{% if_version lte:2.8.x %}
{% tabs %}
{% tab Kubernetes %}

{% if_version lte:2.2.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: MeshServiceSubset
    name: frontend
    tags:
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_8080
      default:
        backends:
          - file:
              path: /dev/stdout
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: MeshServiceSubset
    name: frontend
    tags:
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-demo_svc_8080
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endif_version %}

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab Universal %}

{% if_version lte:2.2.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: MeshServiceSubset
    name: frontend
    tags:
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        backends:
          - file:
              path: /dev/stdout
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: MeshServiceSubset
    name: frontend
    tags:
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endif_version %}

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).

{% endtab %}
{% endtabs %}
{% endif_version %}

{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshAccessLog
name: frontend-to-backend
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: frontend
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshAccessLog
name: frontend-to-backend
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: frontend
      version: canary
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
{% endif_version %}

### Logging to multiple backends

This configuration logs to three backends: TCP, file and OpenTelemetry.

{% if_version lte:2.8.x %}
{% tabs %}
{% tab Kubernetes %}

{% if_version eq:2.2.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - tcp:
              address: 127.0.0.1:5000
              format:
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - file:
              path: /dev/stdout
              format:
                plain: '[%START_TIME%]'
          - openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                  values:
                    - key: "mesh"
                      value:
                        stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: Tcp
            tcp:
              address: 127.0.0.1:5000
              format:
                type: Json
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - type: File
            file:
              path: /dev/stdout
              format:
                type: Plain
                plain: '[%START_TIME%]'
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                  values:
                    - key: "mesh"
                      value:
                        stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endif_version %}

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab Universal %}

{% if_version eq:2.2.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - tcp:
              address: 127.0.0.1:5000
              format:
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - file:
              path: /dev/stdout
              format:
                plain: '[%START_TIME%]'
          - openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                values:
                  - key: "mesh"
                    value:
                      stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: Tcp
            tcp:
              address: 127.0.0.1:5000
              format:
                type: Json
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - type: File
            file:
              path: /dev/stdout
              format:
                type: Plain
                plain: '[%START_TIME%]'
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                values:
                  - key: "mesh"
                    value:
                      stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endif_version %}

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).

{% endtab %}
{% endtabs %}
{% endif_version %}


{% if_version eq:2.9.x %}
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: multiple-backends
mesh: default
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: Tcp
            tcp:
              address: 127.0.0.1:5000
              format:
                type: Json
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - type: File
            file:
              path: /dev/stdout
              format:
                type: Plain
                plain: '[%START_TIME%]'
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                values:
                  - key: "mesh"
                    value:
                      stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endpolicy_yaml %}
{% endif_version %}


{% if_version gte:2.10.x %}
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: multiple-backends
mesh: default
spec:
  rules:
    - default:
        backends:
          - type: Tcp
            tcp:
              address: 127.0.0.1:5000
              format:
                type: Json
                json:
                  - key: "start_time"
                    value: "%START_TIME%"
          - type: File
            file:
              path: /dev/stdout
              format:
                type: Plain
                plain: '[%START_TIME%]'
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector:4317
              body:
                kvlistValue:
                values:
                  - key: "mesh"
                    value:
                      stringValue: "%KUMA_MESH%"
              attributes:
                - key: "start_time"
                  value: "%START_TIME%"
```
{% endpolicy_yaml %}
{% endif_version %}

### Log all incoming and outgoing traffic

{% if_version lte:2.8.x %}
{% tabs %}
{% tab Kubernetes %}

{% if_version lte:2.2.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: Mesh
  from: # delete this section if you don't want to log incoming traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - file:
              path: /dev/stdout
  to: # delete this section if you don't want to log outgoing traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - file:
              path: /dev/stdout
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if it isn't configured
spec:
  targetRef:
    kind: Mesh
  from: # delete this section if you don't want to log incoming traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
  to: # delete this section if you don't want to log outgoing traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endif_version %}

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab Universal %}

{% if_version lte:2.2.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  from: # delete this section if you don't want to log incoming traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - file:
              path: /dev/stdout
  to: # delete this section if you don't want to log outgoing traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - file:
              path: /dev/stdout
```
{% endif_version %}
{% if_version gte:2.3.x %}
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
    kind: Mesh
  from: # delete this section if you don't want to log incoming traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
  to: # delete this section if you don't want to log outgoing traffic
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endif_version %}

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](/docs/{{ page.release }}/reference/http-api).

{% endtab %}
{% endtabs %}
{% endif_version %}

{% if_version eq:2.9.x %}
For this use case we recommend creating two separate policies. One for incoming traffic: 
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: all-incoming-traffic
mesh: default
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
And one for outgoing traffic:
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: all-outgoing-traffic
mesh: default
spec:
  to:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
{% endif_version %}

{% if_version gte:2.10.x %}
For this use case we recommend creating two separate policies. One for incoming traffic:
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: all-incoming-traffic
mesh: default
spec:
  rules:
    - default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
And one for outgoing traffic:
{% policy_yaml namespace=kuma-demo %}
```yaml
type: MeshAccessLog
name: all-outgoing-traffic
mesh: default
spec:
  to:
    - targetRef:
        kind: Mesh
      default:
        backends:
          - type: File
            file:
              path: /dev/stdout
```
{% endpolicy_yaml %}
{% endif_version %}

## Logging traffic going outside the Mesh

To target [`ExternalServices`](/docs/{{ page.release }}/policies/external-services#usage), use `MeshService` as the `targetRef` kind with `name` set to  
the `kuma.io/service` value.

To target other non-mesh traffic, for example [passthrough traffic](/docs/{{ page.release }}/networking/non-mesh-traffic#outgoing), use `Mesh` as the `targetRef` kind. In this case, `%KUMA_DESTINATION_SERVICE%` is set to `external`.

## Select a built-in gateway

You can select a built-in gateway using the `kuma.io/service` value. A current limitation is that traffic routed from a gateway to a service is logged by that gateway as having destination `"*"`.

## All policy options

{% json_schema MeshAccessLogs %}
