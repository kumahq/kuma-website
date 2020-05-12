# Traffic Log

With `TrafficLog` policy you can easily set up access logs on every data-plane in a [`Mesh`](../mesh).

The logs can be then forwarded to a collector that can further transmit them into systems like Splunk, ELK and Datadog.

Configuring access logs in `Kuma` is a 2-step process:

1. First, you need to configure _logging backends_ that will be available for use in a given `Mesh`.

   A _logging backend_ is essentially a sink for access logs.

   In the current release of `Kuma`, a _logging backend_ can be either a _file_ or a _TCP log collector_, such as Logstash.

2. Second, you need to create a `TrafficLog` policy to select a subset of traffic and forward its access logs into one of the _logging backends_ configured for that `Mesh`.

### On Universal

```yaml
type: Mesh
name: default
logging:
  # TrafficLog policies may leave the `backend` field undefined.
  # In that case the logs will be forwarded into the `defaultBackend` of that Mesh.
  defaultBackend: file
  # List of logging backends that can be referred to by name
  # from TrafficLog policies of that Mesh.
  backends:
    - name: logstash
      # Use `format` field to adjust the access log format to your use case.
      format: '{"start_time": "%START_TIME%", "source": "%KUMA_SOURCE_SERVICE%", "destination": "%KUMA_DESTINATION_SERVICE%", "source_address": "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%", "destination_address": "%UPSTREAM_HOST%", "duration_millis": "%DURATION%", "bytes_received": "%BYTES_RECEIVED%", "bytes_sent": "%BYTES_SENT%"}'
      # Use `tcp` field to co configure a TCP logging backend.
      tcp:
        # Address of a log collector.
        address: 127.0.0.1:5000
    - name: file
      # Use `file` field to configure a file-based logging backend.
      file:
        path: /tmp/access.log
      # When `format` field is ommitted, the default access log format will be used.
```

```yaml
type: TrafficLog
name: all-traffic
mesh: default
# This TrafficLog policy applies to all traffic in the Mesh.
sources:
  - match:
      service: '*'
destinations:
  - match:
      service: '*'
# When `backend ` field is omitted, the logs will be forwarded into the `defaultBackend` of that Mesh.
```

```yaml
type: TrafficLog
name: backend-to-database-traffic
mesh: default
# this TrafficLog policy applies only to traffic from service `backend` to service `database`.
sources:
  - match:
      service: backend
destinations:
  - match:
      service: database
conf:
  # Forward the logs into the logging backend named `logstash`.
  backend: logstash
```

### On Kubernetes

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  logging:
    # TrafficLog policies may leave the `backend` field undefined.
    # In that case the logs will be forwarded into the `defaultBackend` of that Mesh.
    defaultBackend: file
    # List of logging backends that can be referred to by name
    # from TrafficLog policies of that Mesh.
    backends:
      - name: logstash
        # Use `format` field to adjust the access log format to your use case.
        format: '{"start_time": "%START_TIME%", "source": "%KUMA_SOURCE_SERVICE%", "destination": "%KUMA_DESTINATION_SERVICE%", "source_address": "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%", "destination_address": "%UPSTREAM_HOST%", "duration_millis": "%DURATION%", "bytes_received": "%BYTES_RECEIVED%", "bytes_sent": "%BYTES_SENT%"}'
        # Use `tcp` field to co configure a TCP logging backend.
        tcp:
          # Address of a log collector.
          address: 127.0.0.1:5000
      - name: file
        # Use `file` field to configure a file-based logging backend.
        file:
          path: /tmp/access.log
        # When `format` field is ommitted, the default access log format will be used.
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-example
  name: all-traffic
spec:
  # This TrafficLog policy applies all traffic in that Mesh.
  sources:
    - match:
        service: '*'
  destinations:
    - match:
        service: '*'
  # When `backend ` field is omitted, the logs will be forwarded into the `defaultBackend` of that Mesh.
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-example
  name: backend-to-database-traffic
spec:
  # This TrafficLog policy applies only to traffic from service `backend` to service `database`.
  sources:
    - match:
        service: backend.kuma-example.svc:8080
  destinations:
    - match:
        service: database.kuma-example.svc:5432
  conf:
    # Forward the logs into the logging backend named `logstash`.
    backend: logstash
```

::: tip
When `backend ` field of a `TrafficLog` policy is omitted, the logs will be forwarded into the `defaultBackend` of that `Mesh`.
:::

### Access Log Format

`Kuma` gives you full control over the format of access logs.

The shape of a single log record is defined by a template string that uses [command operators](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#command-operators) to extract and format data about a `TCP` connection or an `HTTP` request.

E.g.,

```
%START_TIME% %KUMA_SOURCE_SERVICE% => %KUMA_DESTINATION_SERVICE% %DURATION%
```

where `%START_TIME%` and `%KUMA_SOURCE_SERVICE%` are examples of available _command operators_.

A complete set of supported _command operators_ consists of:

1. All _command operators_ [supported by Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log#command-operators)
2. _Command operators_ unique to `Kuma`

The latter include:

| Command Operator                     | Description                                                |
| ------------------------------------ | ---------------------------------------------------------- |
| `%KUMA_MESH%`                        | name of the mesh in which traffic is flowing               |
| `%KUMA_SOURCE_SERVICE%`              | name of a `service` that is the `source` of traffic        |
| `%KUMA_DESTINATION_SERVICE%`         | name of a `service` that is the `destination` of traffic   |
| `%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%` | address of a `Dataplane` that is the `source` of traffic   |

### Access Logs for TCP and HTTP traffic

All access log _command operators_ are valid to use with both `TCP` and `HTTP` traffic.

If a _command operator_ is specific to `HTTP` traffic, such as `%REQ(X?Y):Z%` or `%RESP(X?Y):Z%`, it will be replaced by a symbol "`-`" in case of `TCP` traffic.

Internally, `Kuma` [determines traffic protocol](../http-support-in-kuma) based on the value of `protocol` tag on the `inbound` interface of a `destination` `Dataplane`.

The default format string for `TCP` traffic is:

```
[%START_TIME%] %RESPONSE_FLAGS% %KUMA_MESH% %KUMA_SOURCE_ADDRESS_WITHOUT_PORT%(%KUMA_SOURCE_SERVICE%)->%UPSTREAM_HOST%(%KUMA_DESTINATION_SERVICE%) took %DURATION%ms, sent %BYTES_SENT% bytes, received: %BYTES_RECEIVED% bytes
```

The default format string for `HTTP` traffic is:

```
[%START_TIME%] %KUMA_MESH% "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%" "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%KUMA_SOURCE_SERVICE%" "%KUMA_DESTINATION_SERVICE%" "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%" "%UPSTREAM_HOST%"
```

::: tip
To provide different format for TCP and HTTP logging you can define two separate logging backends with the same address and different format. Then define two TrafficLog entity, one for TCP and one for HTTP with `protocol: http` selector.
:::

### Access Logs in JSON format

If you need an access log with entries in `JSON` format, you have to provide a template string that is a valid `JSON` object, e.g.

```json
{
  "start_time":          "%START_TIME%",
  "source":              "%KUMA_SOURCE_SERVICE%",
  "destination":         "%KUMA_DESTINATION_SERVICE%",
  "source_address":      "%KUMA_SOURCE_ADDRESS_WITHOUT_PORT%",
  "destination_address": "%UPSTREAM_HOST%",
  "duration_millis":     "%DURATION%",
  "bytes_received":      "%BYTES_RECEIVED%",
  "bytes_sent":          "%BYTES_SENT%"
}
```

To use it with Logstash, use `json_lines` codec and make sure your JSON is formatted into one line.

### Logging external services

When running Kuma on Kubernetes you can also log the traffic to external services. To do it, the matched `TrafficPermission` destination section has to have wildcard `*` value.
In such case `%KUMA_DESTINATION_SERVICE%` will have value `external` and `%UPSTREAM_HOST%` will have an IP of the service.  
