# Traffic Log

With the `TrafficLog` policy you can configure access logging on every Envoy data-plane belonging to the [`Mesh`](../mesh). These logs can then be collected by any agent to be inserted into systems like Splunk, ELK and Datadog.
The first step is to configure backends for the `Mesh`. A backend can be either a file or a TCP service (like Logstash). Second step is to create a `TrafficLog` entity to select connections to log.

On Universal:

```yaml
type: Mesh
name: default
mtls:
  ca:
    builtin: {}
  enabled: true
logging:
  defaultBackend: file
  backends:
    - name: logstash
      format: |
        {
            "destination": "%UPSTREAM_CLUSTER%",
            "destinationAddress": "%UPSTREAM_LOCAL_ADDRESS%",
            "source": "%KUMA_DOWNSTREAM_CLUSTER%",
            "sourceAddress": "%DOWNSTREAM_REMOTE_ADDRESS%",
            "bytesReceived": "%BYTES_RECEIVED%",
            "bytesSent": "%BYTES_SENT%"
        }
      tcp:
        address: 127.0.0.1:5000
    - name: file
      file:
        path: /tmp/access.log
```

```yaml
type: TrafficLog
name: all-traffic
mesh: default
sources:
- match:
    service: '*'
destinations:
- match:
    service: '*'
# if omitted, the default logging backend of that mesh will be used
```

```yaml
type: TrafficLog
name: backend-to-database-traffic
mesh: default
sources:
- match:
    service: backend
destinations:
- match:
    service: database
conf:
  backend: logstash
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  mtls:
    ca:
      builtin: {}
    enabled: true
  logging:
    defaultBackend: file
    backends:
      - name: logstash
        format: |
          {
              "destination": "%UPSTREAM_CLUSTER%",
              "destinationAddress": "%UPSTREAM_LOCAL_ADDRESS%",
              "source": "%KUMA_DOWNSTREAM_CLUSTER%",
              "sourceAddress": "%DOWNSTREAM_REMOTE_ADDRESS%",
              "bytesReceived": "%BYTES_RECEIVED%",
              "bytesSent": "%BYTES_SENT%"
          }
        tcp:
          address: 127.0.0.1:5000
      - name: file
        file:
          path: /tmp/access.log
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-system
  name: all-traffic
spec:
  sources:
  - match:
      service: '*'
  destinations:
  - match:
      service: '*'
  # if omitted, the default logging backend of that mesh will be used
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-system
  name: backend-to-database-traffic
spec:
  sources:
  - match:
      service: backend
  destinations:
  - match:
      service: database
  conf:
    backend: logstash
```

::: tip
If a backend in `TrafficLog` is not explicitly specified, the `defaultBackend` from `Mesh` will be used.
:::

In the `format` field, you can use [standard Envoy placeholders](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log) for TCP as well as a few additional placeholders:

- `%KUMA_SOURCE_ADDRESS%` - source address of the Dataplane
- `%KUMA_SOURCE_SERVICE%` - source service from which traffic is sent
- `%KUMA_DESTINATION_SERVICE%` - destination service to which traffic is sent