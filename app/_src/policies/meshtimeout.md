---
title: Mesh Timeout (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state,
it should not be mixed with [Timeout policy](../timeout).
{% endwarning %}

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
| ----------------- | --------- | --- | ---- |
| Mesh              | ✅         | ✅   | ✅    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

## Configuration

This policy enables {{site.mesh_product_name}} to set timeouts on the inbound and outbound connections 
depending on the protocol. Using this policy you can configure TCP and HTTP timeouts. 
Timeout configuration is split into two sections: common configuration and HTTP configuration. 
Common config is applied to both HTTP and TCP communication. HTTP timeout are only applied when
service is marked as http. More on this in [protocol support section](../protocol-support-in-kuma).

MeshTimeout policy lets you configure multiple timeouts:

- connectionTimeout
- idleTimeout
- http requestTimeout
- http streamIdleTimeout
- http maxStreamDuration
- http maxConnectionDuration

### Timeouts explained

#### Connection timeout

Connection timeout specifies the amount of time DP will wait for a TCP connection to be established.

#### Idle timeout

For TCP connections idle timeout is the amount of time that the DP will allow a connection to exist 
with no inbound or outbound activity. On the other hand when connection in HTTP time at which a inbound
 or outbound connection will be terminated if there are no active streams

#### HTTP request timeout

Request timeout lets you configure how long the data plane proxy should wait for the full response. 
In details it spans between the point at which the entire request has been processed by DP and when the response has been completely processed by DP.

#### HTTP stream idle timeout

Stream idle timeout is the amount of time that the data plane proxy will allow a HTTP/2 stream to exist with no inbound or outbound activity. 
This timeout is strongly recommended for all requests (not just streaming requests/responses) as it additionally 
defends against a peer that does not open the stream window once an entire response has been buffered to be sent to a downstream client.

{% tip %}
Stream timeouts apply even when you are only using HTTP/1.1 in you services. This is because every connection between data plane proxies is upgraded to HTTP/2.
{% endtip %}

#### HTTP max stream duration

Max stream duration is the maximum time that a stream’s lifetime will span. You can use this functionality 
when you want to reset HTTP request/response streams periodically.

#### HTTP max connection duration

Max connection duration is the time after which an inbound or outbound connection will be drained and/or closed, 
starting from when it was first established. If there are no active streams, the connection will be closed. 
If there are any active streams, the drain sequence will kick-in, and the connection will be force-closed after 5 seconds.

### Examples

#### Simple outbound HTTP configuration

This configuration will be applied to all data plane proxies inside of Mesh.

{% tabs example1 useUrlFragment=false %}
{% tab example1 Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: timeout-global
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
        http:
          requestTimeout: 2s
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab example1 Universal %}

```yaml
type: MeshTimeout
name: timeout-global
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
        http:
          requestTimeout: 2s
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

#### Simple TCP configuration

{% tabs example2 useUrlFragment=false %}
{% tab example2 Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: tcp-timeout
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab example2 Universal %}

```yaml
type: MeshTimeout
name: tcp-timeout
mesh: default
spec:
  targetRef:
    kind: Mesh
  to:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

#### Simple configuration for inboud applied to specific service

This configuration will be applied to `backend` service inbound.

{% tabs example3 useUrlFragment=false %}
{% tab example3 Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: inboud-timeout
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: backend_kuma-test_svc_80
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab example3 Universal %}

```yaml
type: MeshTimeout
name: inboud-timeout
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: backend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 20s
        connectionTimeout: 2s
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

#### Full config applied to inbound and outboud of specific service

This timeout configuration will be applied to all inbound connections to `frontend` and outbound connections from `frontend` to `backend` service 

{% tabs example4 useUrlFragment=false %}
{% tab example4 Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: inboud-timeout
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: fontend_kuma-test_svc_80
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 2s
        http:
          requestTimeout: 10s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
  to:
    - targetRef:
        kind: MeshService
        name: backend_kuma-test_svc_80
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m

```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab example4 Universal %}

```yaml
type: MeshTimeout
name: inboud-timeout
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: frontend
  from:
    - targetRef:
        kind: Mesh
      default:
        idleTimeout: 60s
        connectionTimeout: 2s
        http:
          requestTimeout: 10s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        idleTimeout: 60s
        connectionTimeout: 1s
        http:
          requestTimeout: 5s
          streamIdleTimeout: 1h
          maxStreamDuration: 30m
          maxConnectionDuration: 30m
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

### Defaults

| Property                   | default |
| -------------------------- | ------- |
| idleTimeout                | 1h      |
| connectionTimeout          | 5s      |
| http.requestTimeout        | 15s     |
| http.streamIdleTimeout     | 30m     |
| http.maxStreamDuration     | 0s      |
| http.maxConnectionDuration | 0s      |

{% if_version eq:2.1.x %}
If you don't specify `from` or `to` section defaults from [Timeout policy](../timeout) will be used. This is [known bug](https://github.com/kumahq/kuma/issues/5850) and will be fixed in the next version.
{% endif_version %}

## All policy options

{% policy_schema MeshTimeout %}
