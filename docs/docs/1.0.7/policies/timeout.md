# Timeout

This policy enables Kuma to set timeouts on the outbound connections depending on the protocol.

## Usage

As usual, we can apply `sources` and `destinations` selectors to determine what proxy we want to configure (`sources` selector)
and what outbounds connection of the proxy will be used for this policy (`destinations` selector).

The policy let you configure retry behaviour for `HTTP`, `GRPC` and `TCP` protocols.

## Example

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: Timeout
mesh: default
metadata:
  name: timeouts-backend
spec:
  conf:
    # connectTimeout defines time to establish connection, 'connect_timeout' on Cluster, default 10s
    connectTimeout: 10s
    tcp:
      # 'idle_timeout' on TCPProxy, disabled by default
      idleTimeout: 1h
    http:
      # 'timeout' on Route, disabled by default
      requestTimeout: 5s
      # 'idle_timeout' on Cluster, disabled by default
      idleTimeout: 1h
    grpc:
      # 'stream_idle_timeout' on HttpConnectionManager, disabled by default
      streamIdleTimeout: 5m
      # 'max_stream_duration' on Cluster, disabled by default
      maxStreamDuration: 30m
```
:::

::: tab "Universal"
```yaml
type: Timeout
mesh: default
name: timeouts-backend
sources:
  - match:
      kuma.io/service: '*'
destinations:
  - match:
      kuma.io/service: 'backend'
conf:
  # connectTimeout defines time to establish connection, 'connect_timeout' on Cluster, default 10s
  connectTimeout: 10s
  tcp:
    # 'idle_timeout' on TCPProxy, disabled by default
    idleTimeout: 1h
  http:
    # 'timeout' on Route, disabled by default
    requestTimeout: 5s
    # 'idle_timeout' on Cluster, disabled by default
    idleTimeout: 1h
  grpc:
    # 'stream_idle_timeout' on HttpConnectionManager, disabled by default
    streamIdleTimeout: 5m
    # 'max_stream_duration' on Cluster, disabled by default
    maxStreamDuration: 30m
```
:::
