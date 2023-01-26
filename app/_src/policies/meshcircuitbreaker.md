---
title: MeshCircuitBreaker (beta)
---

{% warning %}
This policy uses new policy matching algorithm and is in beta state, it should not be mixed
with [CircuitBreaker](../circuit-breaker).
{% endwarning %}

This policy will look for errors in the live traffic being exchanged between our data plane proxies and it will mark a
data proxy as an unhealthy if certain conditions are met and - by doing so - making sure that no additional traffic can
reach an unhealthy data plane proxy until it is healthy again.

Circuit breakers - unlike active [MeshHealthChecks](/docs/{{ page.version }}/policies/meshhealthcheck/) - do not send
additional traffic to our data plane proxies but they rather inspect the existing service traffic. They are also
commonly used to prevent cascading failures in our services.

{% tip %}
Like a real-world circuit breaker when the circuit is **closed** then traffic between a source and destination data
plane proxy is allowed to freely flow through it, and when it is **open** then the traffic is interrupted.
{% endtip %}

The conditions that determine when a circuit breaker is closed or open are being configured on connection limits or
outlier detection basis. For outlier detection to open circuit breaker you can configure what we call "detectors".
This policy provides 5 different types of detectors, and they are triggered on some deviations in the upstream service
behavior. All detectors could coexist on the same outbound interface.

Once one of the detectors has been triggered the corresponding data plane proxy is ejected from the set of the load
balancer for a period equal to [baseEjectionTime](#outlier-detection-configuration). Every further ejection of the same data plane
proxy will further extend the [baseEjectionTime](#outlier-detection-configuration) multiplied by the number of ejections: for example
the 4th ejection will be lasting for a period of time of `4 * baseEjectionTime`.

This policy provides **passive** checks.
If you want to configure **active** checks, please utilize the [MeshHealthCheck](/docs/{{ page.version }}/policies/meshhealthcheckcz)
policy.
Data plane proxies with **passive** checks won't explicitly send requests to other data plane proxies to determine if
target proxies are healthy or not.

## TargetRef support matrix

| TargetRef type    | top level | to  | from |
|-------------------|-----------|-----|------|
| Mesh              | ✅         | ✅   | ✅    |
| MeshSubset        | ✅         | ❌   | ❌    |
| MeshService       | ✅         | ✅   | ❌    |
| MeshServiceSubset | ✅         | ❌   | ❌    |
| MeshGatewayRoute  | ❌         | ❌   | ❌    |

To learn more about the information in this table, see the [matching docs](/docs/{{ page.version }}/policies/targetref).

### Examples

#### Basic circuit breaker for outbound traffic from web, to backend service

{% tabs usage useUrlFragment=false %}
{% tab usage Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshCircuitBreaker
metadata:
  name: web-to-backend-circuit-breaker
  namespace: {{site.mesh_namespace}}
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        connectionLimits:
          maxConnections: 2
          maxPendingRequests: 8
          maxRetries: 2
          maxRequests: 2
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab usage Universal %}

```yaml
type: MeshCircuitBreaker
name: web-to-backend-circuit-breaker
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
      default:
        connectionLimits:
          maxConnections: 2
          maxPendingRequests: 8
          maxRetries: 2
          maxRequests: 2
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

#### Outlier detection for inbound traffic to backend service

{% tabs protocol useUrlFragment=false %}
{% tab protocol Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshCircuitBreaker
metadata:
  name: backend-inbound-outlier-detection
  namespace: {{site.mesh_namespace}}
spec:
  targetRef:
    kind: MeshService
    name: web
  from:
    - targetRef:
        kind: Mesh
      default:
        outlierDetection:
          interval: 5s
          baseEjectionTime: 30s
          maxEjectionPercent: 20
          splitExternalAndLocalErrors: true
          detectors:
            totalFailures:
              consecutive: 10
            gatewayFailures:
              consecutive: 10
            localOriginFailures:
              consecutive: 10
            successRate:
              minimumHosts: 5
              requestVolume: 10
              standardDeviationFactor: 1.9
            failurePercentage:
              requestVolume: 10
              minimumHosts: 5
              threshold: 85
```

We will apply the configuration with `kubectl apply -f [..]`.
{% endtab %}

{% tab protocol Universal %}

```yaml
type: MeshCircuitBreaker
name: backend-inbound-outlier-detection
mesh: default
spec:
  targetRef:
    kind: MeshService
    name: web
  from:
    - targetRef:
        kind: Mesh
      default:
        outlierDetection:
          interval: 5s
          baseEjectionTime: 30s
          maxEjectionPercent: 20
          splitExternalAndLocalErrors: true
          detectors:
            totalFailures:
              consecutive: 10
            gatewayFailures:
              consecutive: 10
            localOriginFailures:
              consecutive: 10
            successRate:
              minimumHosts: 5
              requestVolume: 10
              standardDeviationFactor: 1.9
            failurePercentage:
              requestVolume: 10
              minimumHosts: 5
              threshold: 85
```

We will apply the configuration with `kumactl apply -f [..]` or via the [HTTP API](/docs/{{ page.version }}/reference/http-api).
{% endtab %}
{% endtabs %}

## Connection limits configuration

- **`maxConnections`** - (optional) The maximum number of connections allowed to be made to the upstream cluster. If not
  specified then equal to "1024".
- **`maxConnectionPools`** - (optional) The maximum number of connection pools per cluster that are concurrently
  supported at once. Set this for clusters which create a large number of connection pools. If not specified, the
  default is unlimited.
- **`maxPendingRequests`** - (optional) The maximum number of pending requests that are allowed to the upstream cluster.
  This limit is applied as a connection limit for non-HTTP traffic. If not specified then equal to "1024".
- **`maxRetries`** - (optional) The maximum number of parallel retries that will be allowed to the upstream cluster. If
  not specified then equal to "3".
- **`maxRequests`** - (optional) The maximum number of parallel requests that are allowed to be made to the upstream
  cluster. This limit does not apply to non-HTTP traffic. If not specified then equal to "1024".

## Outlier detection configuration

- **`disabled`** - (optional) When set to true, outlierDetection configuration won't take any effect.
- **`interval`** - (optional) The time interval between ejection analysis sweeps. This can result in both new ejections
  and hosts being returned to service.
- **`baseEjectionTime`** - (optional) The base time that a host is ejected for. The real time is equal to the base time
  multiplied by the number of times the host has been ejected.
- **`maxEjectionPercent`** - (optional) The maximum % of an upstream cluster that can be ejected due to outlier
  detection. Defaults to 10% but will eject at least one host regardless of the value.
- **`splitExternalAndLocalErrors`** - (optional) Determines whether to distinguish local origin failures from external
  errors. If set to true the following configuration parameters are taken into
  account: `detectors.localOriginFailures.consecutive`.
- **`detectors`** - Contains configuration for supported outlier detectors. At least one detector needs to be configured
  when policy is configured for outlier detection.

### Detectors configuration

#### `totalFailures`

In the default mode (`outlierDetection.splitExternalAndLocalErrors` is false) this detection type takes into account all
generated errors: locally originated and externally originated (transaction) errors. In split mode (
`outlierDetection.splitExternalLocalOriginErrors` is true) this detection type takes into account only externally
originated (transaction) errors, ignoring locally originated errors. If an upstream host is an HTTP-server, only 5xx
types of error are taken into account (see Consecutive Gateway Failure for exceptions). Properly formatted responses,
even when they carry an operational error (like index not found, access denied) are not taken into account.

- **`consecutive`** - The number of consecutive server-side error responses (for HTTP traffic, 5xx responses; for TCP
  traffic, connection failures; for Redis, failure to respond PONG; etc.) before a consecutive total failure ejection
  occurs.

#### `gatewayFailures`

In the default mode (`outlierDetection.splitExternalLocalOriginErrors` is false) this detection type takes into account
a subset of 5xx errors, called "gateway errors" (502, 503 or 504 status code) and local origin failures, such as
timeout, TCP reset etc.
In split mode (`outlierDetection.splitExternalLocalOriginErrors` is true) this detection type takes into account a
subset of 5xx errors, called "gateway errors" (502, 503 or 504 status code) and is supported only by the http router.

- **`consecutive`** - The number of consecutive gateway failures (502, 503, 504 status codes) before a consecutive
  gateway failure ejection occurs.

#### `localOriginFailures`

This detection type is enabled only when `outlierDetection.splitExternalLocalOriginErrors` is true and takes into
account only locally originated errors (timeout, reset, etc).
If Envoy repeatedly cannot connect to an upstream host or communication with the upstream host is repeatedly
interrupted, it will be ejected. Various locally originated problems are detected: timeout, TCP reset, ICMP errors, etc.
This detection type is supported by http router and tcp proxy.

- **`consecutive`** - The number of consecutive locally originated failures before ejection occurs. Parameter takes
  effect only when `splitExternalAndLocalErrors` is set to true.

#### `successRate`

Success Rate based outlier detection aggregates success rate data from every host in a cluster. Then at given intervals
ejects hosts based on statistical outlier detection. Success Rate outlier detection will not be calculated for a host if
its request volume over the aggregation interval is less than the `outlierDetection.detectors.successRate.requestVolume`
value.
Moreover, detection will not be performed for a cluster if the number of hosts with the minimum required request volume
in an interval is less than the `outlierDetection.detectors.successRate.minimumHosts` value.
In the default configuration mode (`outlierDetection.splitExternalLocalOriginErrors` is false) this detection type takes
into account all types of errors: locally and externally originated.
In split mode (`outlierDetection.splitExternalLocalOriginErrors` is true), locally originated errors and externally
originated (transaction) errors are counted and treated separately.

- **`minimumHosts`** - The number of hosts in a cluster that must have enough request volume to detect success rate
  outliers. If the number of hosts is less than this setting, outlier detection via success rate statistics is not
  performed for any host in the cluster.
- **`requestVolume`** - The minimum number of total requests that must be collected in one interval (as defined by the
  interval duration configured in outlierDetection section) to include this host in success rate based outlier
  detection. If the volume is lower than this setting, outlier detection via success rate statistics is not performed
  for that host.
- **`standardDeviationFactor`** - This factor is used to determine the ejection threshold for success rate outlier
  ejection. The ejection threshold is the difference between the mean success rate, and the product of this factor and
  the standard deviation of the mean success rate: mean - (standard_deviation *success_rate_standard_deviation_factor).
  Either int or decimal represented as string.

#### `failurePercentage`

Failure Percentage based outlier detection functions similarly to success rate detection, in that it relies on success
rate data from each host in a cluster. However, rather than compare those values to the mean success rate of the cluster
as a whole, they are compared to a flat user-configured threshold. This threshold is configured via
the `outlierDetection.failurePercentageThreshold` field.
The other configuration fields for failure percentage based detection are similar to the fields for success rate
detection. As with success rate detection, detection will not be performed for a host if its request volume over the
aggregation interval is less than the `outlierDetection.detectors.failurePercentage.requestVolume` value.
Detection also will not be performed for a cluster if the number of hosts with the minimum required request volume in an
interval is less than the `outlierDetection.detectors.failurePercentage.minimumHosts` value.

- **`requestVolume`** - The minimum number of hosts in a cluster in order to perform failure percentage-based ejection.
  If the total number of hosts in the cluster is less than this value, failure percentage-based ejection will not be
  performed.
- **`minimumHosts`** - The minimum number of total requests that must be collected in one interval (as defined by the
  interval duration above) to perform failure percentage-based ejection for this host. If the volume is lower than this
  setting, failure percentage-based ejection will not be performed for this host.
- **`threshold`** - The failure percentage to use when determining failure percentage-based outlier detection. If the
  failure percentage of a given host is greater than or equal to this value, it will be ejected.
