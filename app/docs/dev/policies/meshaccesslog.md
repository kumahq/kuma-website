---
title: MeshAccessLog (beta)
---

With the MeshAccessLog policy you can easily set up access logs on every data plane in a mesh.

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [TrafficLog](/docs/{{ page.version }}/policies/traffic-log).
{% endwarning %}

{% tip %}
In the rest of this page we assume you have already configured your observability tools to work with Kuma.
If you haven't already read the [observability docs](/docs/{{ page.version }}/explore/observability).
{% endtip %}

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ✅   | ✅    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |

If you don't understand this table you should read [matching docs](/docs/{{ page.version }}/policies/matching).

## Configuration

### Format

Kuma gives you full control over the format of the access logs.

The shape of a single log record is defined by a template string that uses [command operators](https://www.envoyproxy.io/docs/envoy/v1.22.0/configuration/observability/access_log/usage#command-operators) to extract and format data about a `TCP` connection or an `HTTP` request.

E.g.,

```
%START_TIME% %KUMA_SOURCE_SERVICE% => %KUMA_DESTINATION_SERVICE% %DURATION%
```

where `%START_TIME%` and `%KUMA_SOURCE_SERVICE%` are examples of available _command operators_.

All _command operators_ [defined by Envoy](https://www.envoyproxy.io/docs/envoy/v1.22.0/configuration/observability/access_log/usage#command-operators) are supported, along with additional _command operators_ defined by Kuma:

| Command Operator                     | Description                                                      |
|--------------------------------------|------------------------------------------------------------------|
| `%KUMA_MESH%`                        | name of the mesh in which traffic is flowing                     |
| `%KUMA_SOURCE_SERVICE%`              | name of a `service` that is the `source` of traffic              |
| `%KUMA_DESTINATION_SERVICE%`         | name of a `service` that is the `destination` of traffic         |
| `%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%` | address of a `Dataplane` that is the `source` of traffic         |
| `%KUMA_TRAFFIC_DIRECTION%`           | direction of the traffic, `INBOUND`, `OUTBOUND` or `UNSPECIFIED` |

All additional access log _command operators_ are valid to use with both `TCP` and `HTTP` traffic.

If a _command operator_ is specific to `HTTP` traffic, such as `%REQ(X?Y):Z%` or `%RESP(X?Y):Z%`, it will be replaced by a symbol "`-`" in case of `TCP` traffic.

Internally, Kuma [determines traffic protocol](/docs/{{ page.version }}/policies/protocol-support-in-kuma) based on the value of `kuma.io/protocol` tag on the `inbound` interface of a `destination` `Dataplane`.

There are two types of `format` - `plain` and `json`.

Plain will accept a string with _command operators_ and produce a string output.

JSON will accept a list of key-value pairs that will produce a valid JSON object.

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

```yaml
format:
  plain: '[%START_TIME%] %BYTES_RECEIVED%'
```

Example output:

```text
[2016-04-15T20:17:00.310Z] 154
```

#### JSON

Example configuration:

```yaml
format:
  json:
    - key: "start_time"
      value: "%START_TIME%"
    - key: "bytes_received"
      value: "%BYTES_RECEIVED%"
```

Example output:

```json
{
  "start_time": "2016-04-15T20:17:00.310Z",
  "bytes_received": "154"
}
```

<details>
  <summary>TCP configuration with default fields:</summary>

  <div markdown="1">
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
</div>

</details>

<details>
  <summary>HTTP configuration with default fields:</summary>

<div markdown="1">
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
</div>

</details>


### Backends

#### TCP

You can configure a TCP backend with an address:

```yaml
backends:
  - tcp:
      address: 127.0.0.1:5000
```

#### File

You can configure a file backend with a path:

```yaml
backends:
  - file:
      path: /tmp/access.log
```

## Examples

{% tabs meshaccesslog useUrlFragment=false %}
{% tab meshaccesslog Kubernetes %}

Full example:
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: default
  namespace: kuma-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
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
          path: /tmp/access.log
          format:
            plain: '[%START_TIME%]'
```

Apply the configuration with `kubectl apply -f [..]`.

{% endtab %}
{% tab meshaccesslog Universal %}

Full example:
```yaml
type: MeshAccessLog
name: default
mesh: default
spec:
  targetRef:
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
          path: /tmp/access.log
          format:
            plain: '[%START_TIME%]'
```

Apply the configuration with `kumactl apply -f [..]` or with the [HTTP API](../../reference/http-api).

{% endtab %}
{% endtabs %}

## Logging external services

When running Kuma on Kubernetes you can also log the traffic to external services.
To do it use `MeshService` as a `targetRef` target.
In such case `%KUMA_DESTINATION_SERVICE%` will have value `external` and `%UPSTREAM_HOST%` will have an IP of the service.
