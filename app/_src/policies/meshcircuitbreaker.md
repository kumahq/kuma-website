---
title: MeshCircuitBreaker
---

{% warning %}
This policy uses new policy matching algorithm.
Do **not** combine with [CircuitBreaker](/docs/{{ page.release }}/policies/circuit-breaker).
{% endwarning %}

This policy will look for errors in the live traffic being exchanged between our data plane proxies. It will mark a data
proxy as unhealthy if certain conditions are met. The policy will ensure that no additional traffic can reach an
unhealthy data plane proxy until it is healthy again.

Circuit breakers - unlike active [MeshHealthChecks](/docs/{{ page.release }}/policies/meshhealthcheck/) - do not send
additional traffic to our data plane proxies but they rather inspect the existing service traffic. They are also
commonly used to prevent cascading failures.

{% tip %}
Like a real-world circuit breaker when the circuit is **closed** then traffic between a source and destination data
plane proxy is allowed to freely flow through it. When it is **open** then the traffic is interrupted.
{% endtip %}

The conditions that determine when a circuit breaker is closed or open are being configured on connection limits or
outlier detection basis. For outlier detection to open circuit breaker you can configure what we call _detectors_.
This policy provides 5 different types of detectors, and they are triggered on some deviations in the upstream service
behavior. All detectors could coexist on the same outbound interface.

Once one of the detectors has been triggered the corresponding data plane proxy is ejected from the set of the load
balancer for a period equal to [baseEjectionTime](#outlier-detection). Every further ejection of the same data plane
proxy will further extend the [baseEjectionTime](#outlier-detection) multiplied by the number of ejections: for example
the fourth ejection will be lasting for a period of time of `4 * baseEjectionTime`.

This policy provides **passive** checks.
If you want to configure **active** checks, please utilize the [MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck)
policy.
Data plane proxies with **passive** checks won't explicitly send requests to other data plane proxies to determine if
target proxies are healthy or not.

## TargetRef support matrix

{% if_version gte:2.6.x %}
{% tabs targetRef useUrlFragment=false %}
{% tab targetRef Sidecar %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
| `from[].targetRef.kind` | `Mesh`                                                   |
{% endif_version %}
{% endtab %}

{% tab targetRef Builtin Gateway %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshGateway`, `MeshGateway` with listener `tags`|
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endtab %}

{% tab targetRef Delegated Gateway %}
{% if_version lte:2.8.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`, `MeshService`, `MeshServiceSubset` |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% if_version gte:2.9.x %}
| `targetRef`             | Allowed kinds                                            |
| ----------------------- | -------------------------------------------------------- |
| `targetRef.kind`        | `Mesh`, `MeshSubset`                                     |
| `to[].targetRef.kind`   | `Mesh`, `MeshService`                                    |
{% endif_version %}
{% endtab %}
{% endtabs %}

{% endif_version %}
{% if_version lte:2.5.x %}

| `targetRef.kind`    | top level | to  | from |
| ------------------- | --------- | --- | ---- |
| `Mesh`              | ✅        | ✅  | ✅   |
| `MeshSubset`        | ✅        | ❌  | ❌   |
| `MeshService`       | ✅        | ✅  | ❌   |
| `MeshServiceSubset` | ✅        | ❌  | ❌   |

{% endif_version %}

To learn more about the information in this table, see the [matching docs](/docs/{{ page.release }}/policies/introduction).

## Configuration

### Connection limits

- **`maxConnections`** - (optional) The maximum number of connections allowed to be made to the upstream Envoy Cluster.
  If not specified then equal to _1024_.
- **`maxConnectionPools`** - (optional) The maximum number of connection pools per Envoy Cluster that are concurrently
  supported at once. Set this for Envoy Clusters which create a large number of connection pools. If not specified, the
  default is unlimited.
- **`maxPendingRequests`** - (optional) The maximum number of pending requests that are allowed to the upstream Envoy
  Cluster. This limit is applied as a connection limit for non-HTTP traffic. If not specified then equal to _1024_.
- **`maxRetries`** - (optional) The maximum number of parallel retries that will be allowed to the upstream Envoy
  Cluster. If not specified then equal to _3_.
- **`maxRequests`** - (optional) The maximum number of parallel requests that are allowed to be made to the upstream
  Envoy Cluster. This limit does not apply to non-HTTP traffic. If not specified then equal to _1024_.

### Outlier detection

Outlier detection can be configured for [HTTP, TCP or gRPC](/docs/{{ page.release }}/policies/protocol-support-in-kuma) traffic.

{% warning %}
For **gRPC** requests, the outlier detection will use the HTTP status mapped from the `grpc-status` response header.
{% endwarning %}

- **`disabled`** - (optional) When set to true, outlierDetection configuration won't take any effect.
- **`interval`** - (optional) The time interval between ejection analysis sweeps. This can result in both new ejections
  and hosts being returned to service.
- **`baseEjectionTime`** - (optional) The base time that a host is ejected for. The real time is equal to the base time
  multiplied by the number of times the host has been ejected.
- **`maxEjectionPercent`** - (optional) The maximum % of an upstream Envoy Clusters that can be ejected due to outlier
  detection. Defaults to 10% but will eject at least one host regardless of the value.
- **`splitExternalAndLocalErrors`** - (optional) Determines whether to distinguish local origin failures from external
  errors. If set to true the following configuration parameters are taken into
  account: `detectors.localOriginFailures.consecutive`.
- **`detectors`** - Contains configuration for supported outlier detectors. At least one detector needs to be configured
  when policy is configured for outlier detection.
{% if_version gte:2.10.x %}
- **`healthyPanicThreshold`** - (optional) Allows to configure panic threshold for Envoy cluster. If not specified,
  the default is 50%. To disable panic mode, set to 0%.
{% endif_version %}


#### Detectors configuration

Configuration for supported outlier detectors. At least one detector needs to be configured when policy is configured for outlier detection.

{% tabs detectors useUrlFragment=false %}
{% tab detectors Total Failures %}

Depending on mode the outlier detection can take into account all or externally originated (transaction) errors only. 

{% tabs totalFailures_modes useUrlFragment=false %}
{% tab totalFailures_modes Default Mode %}

{% tip %}
Default mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is not set or equal `false`
{% endtip %}

This detection type takes into account all generated errors: **locally originated** and **externally originated** (transaction) errors.

**Configuration**

- **`totalFailures.consecutive`** - The number of consecutive server-side error responses
  (for HTTP traffic, 5xx responses; for TCP traffic, connection failures; etc.) before a consecutive total failure ejection occurs.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        detectors:
          totalFailures:
            consecutive: 10
```

{% endtab %}

{% tab totalFailures_modes Split Mode %}

{% tip %}
Split Mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is equal `true`
{% endtip %}

This detection type takes into account only externally originated (transaction) errors, ignoring locally originated ones.

[**HTTP**](/docs/{{ page.release }}/policies/protocol-support-in-kuma)

If an upstream host is an HTTP-server, only 5xx types of error are taken into account (see Consecutive Gateway Failure for exceptions).

{% warning %}
Properly formatted responses, even when they carry an operational error (like index not found, access denied) are not taken into account.
{% endwarning %}

**Configuration**

- **`totalFailures.consecutive`** - The number of consecutive server-side error responses (for HTTP traffic, 5xx responses) before a consecutive total failure ejection occurs.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        splitExternalAndLocalErrors: true
        detectors:
          totalFailures:
            consecutive: 10
```

{% endtab %}
{% endtabs %}

{% endtab %}
{% tab detectors Gateway Failures %}

Depending on mode the outlier detection can take into account gateway failures with locally originated failures (default mode) or gateway failures only (split mode).

{% tabs gatewayFailures_modes useUrlFragment=false %}
{% tab gatewayFailures_modes Default Mode %}

{% tip %}
Default mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is not set or equal `false`
{% endtip %}

This detection type takes into account a subset of **5xx** errors, called "gateway errors" (**502**, **503** or **504** status code) and local origin failures, such as **timeout**, **TCP reset** etc.

**Configuration**

- **`gatewayFailures.consecutive`** - The number of consecutive gateway failures (502, 503, 504 status codes) before a consecutive
  gateway failure ejection occurs.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        detectors:
          gatewayFailures:
            consecutive: 10
```

{% endtab %}

{% tab gatewayFailures_modes Split Mode %}

{% tip %}
Split Mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is equal `true`
{% endtip %}

This detection type takes into account a subset of **5xx** errors, called "gateway errors" (**502**, **503** or **504** status code).

{% warning %}
This detector is supported only for HTTP traffic.
{% endwarning %}

**Configuration**

- **`gatewayFailures.consecutive`** - The number of consecutive gateway failures (502, 503, 504 status codes) before a consecutive
  gateway failure ejection occurs.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        splitExternalAndLocalErrors: true
        detectors:
          gatewayFailures:
            consecutive: 10
```

{% endtab %}
{% endtabs %}

{% endtab %}
{% tab detectors Locally Originated Failures %}

{% warning %}
This detection is supported only in Split Mode
{% endwarning %}

This detection takes into account only locally originated errors (timeout, reset, etc).

If Envoy repeatedly cannot connect to an upstream host or communication with the upstream host is repeatedly interrupted, it will be ejected. Various locally originated problems are detected: timeout, TCP reset, ICMP errors, etc.

{% tabs localOriginFailures_modes useUrlFragment=false %}
{% tab localOriginFailures_modes Split Mode %}

{% tip %}
Split Mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is equal `true`
{% endtip %}

**Configuration**

- **`localOriginFailures.consecutive`** - The number of consecutive locally originated failures before ejection occurs.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        splitExternalAndLocalErrors: true
        detectors:
          localOriginFailures:
            consecutive: 10
```
{% endtab %}
{% tab localOriginFailures_modes Default Mode %}

This detection is not supported in the Default Mode

{% endtab %}
{% endtabs %}

{% endtab %}
{% tab detectors Success Rate %}

Success Rate based outlier detection aggregates success rate data from every host in an Envoy Cluster. Then at given intervals ejects hosts based on statistical outlier detection.

Success Rate outlier detection will not be calculated for a host if its request volume over the aggregation interval is less than the value of `successRate.requestVolume`
value.

Moreover, detection will not be performed for a cluster if the number of hosts with the minimum required request volume in an interval is less than the `successRate.minimumHosts` value.

{% tabs successRate_modes useUrlFragment=false %}
{% tab successRate_modes Default Mode %}

{% tip %}
Default mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is not set or equal `false`
{% endtip %}

This detection type takes into account all types of errors: locally and externally originated.

{% endtab %}
{% tab successRate_modes Split Mode %}

{% tip %}
Split Mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is equal `true`
{% endtip %}

Locally originated errors and externally originated (transaction) errors are counted and treated separately.

{% endtab %}
{% endtabs %}

**Configuration**

- **`successRate.minimumHosts`** - The number of hosts in an Envoy Cluster that must have enough request volume to detect success rate outliers. If the number of hosts is less than this setting, outlier detection via success rate statistics is not performed for any host in the Cluster.
- **`successRate.requestVolume`** - The minimum number of total requests that must be collected in one interval (as defined by the interval duration configured in outlierDetection section) to include this host in success rate based outlier detection. If the volume is lower than this setting, outlier detection via success rate statistics is not performed for that host.
- **`successRate.standardDeviationFactor`** - This factor is used to determine the ejection threshold for success rate outlier ejection. The ejection threshold is the difference between the mean success rate, and the product of this factor and the standard deviation of the mean success rate: mean - (standard_deviation *success_rate_standard_deviation_factor). Either int or decimal represented as string.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        splitExternalAndLocalErrors: true
        detectors:
          successRate:
            minimumHosts: 5
            requestVolume: 10
            standardDeviationFactor: "1.9"
```

{% endtab %}
{% tab detectors Failure Percentage %}

Failure Percentage based outlier detection functions similarly to success rate detection, in that it relies on success rate data from each host in an Envoy Cluster. However, rather than compare those values to the mean success rate of the Cluster as a whole, they are compared to a flat user-configured threshold. This threshold is configured via the [`failurePercentageThreshold`](#outlier-detection) field.

The other configuration fields for failure percentage based detection are similar to the fields for success rate detection. As with success rate detection, detection will not be performed for a host if its request volume over the aggregation interval is less than the `failurePercentage.requestVolume` value.

Detection also will not be performed for an Envoy Cluster if the number of hosts with the minimum required request volume in an interval is less than the `failurePercentage.minimumHosts` value.

{% tabs failurePercentage_modes useUrlFragment=false %}
{% tab failurePercentage_modes Default Mode %}

{% tip %}
Default mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is not set or equal `false`
{% endtip %}

This detection type takes into account all types of errors: locally and externally originated.

{% endtab %}
{% tab failurePercentage_modes Split Mode %}

{% tip %}
Split Mode is when [`splitExternalAndLocalErrors`](#outlier-detection) is equal `true`
{% endtip %}

Locally originated errors and externally originated (transaction) errors are counted and treated separately.

{% endtab %}
{% endtabs %}

**Configuration**

- **`failurePercentage.requestVolume`** - The minimum number of hosts in an Envoy Cluster in order to perform failure percentage-based ejection. If the total number of hosts in the Cluster is less than this value, failure percentage-based ejection will not be performed.
- **`failurePercentage.minimumHosts`** - The minimum number of total requests that must be collected in one interval (as defined by the interval duration above) to perform failure percentage-based ejection for this host. If the volume is lower than this setting, failure percentage-based ejection will not be performed for this host.
- **`failurePercentage.threshold`** - The failure percentage to use when determining failure percentage-based outlier detection. If the failure percentage of a given host is greater than or equal to this value, it will be ejected.

**Example**

```yaml
type: MeshCircuitBreaker
mesh: default
name: circuit-breaker
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      outlierDetection:
        splitExternalAndLocalErrors: true
        detectors:
          failurePercentage:
            requestVolume: 10
            minimumHosts: 5
            threshold: 85
```

{% endtab %}

{% endtabs %}

<hr />

### Examples

#### Basic circuit breaker for outbound traffic from web, to backend service

{% if_version lte:2.8.x %}
{% policy_yaml usage-28x %}
```yaml
type: MeshCircuitBreaker
name: web-to-backend-circuit-breaker
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        _port: 8080
      default:
        connectionLimits:
          maxConnections: 2
          maxPendingRequests: 8
          maxRetries: 2
          maxRequests: 2
```
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml usage-29x namespace=kuma-demo use_meshservice=true %}
```yaml
type: MeshCircuitBreaker
name: web-to-backend-circuit-breaker
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: web
  to:
    - targetRef:
        kind: MeshService
        name: backend
        namespace: kuma-demo
        sectionName: http
        _port: 8080
      default:
        connectionLimits:
          maxConnections: 2
          maxPendingRequests: 8
          maxRetries: 2
          maxRequests: 2
```
{% endpolicy_yaml %}
{% endif_version %}

#### Outlier detection for inbound traffic to backend service

{% if_version lte:2.8.x %}
{% policy_yaml protocol-28x %}
```yaml
type: MeshCircuitBreaker
name: backend-inbound-outlier-detection
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: web
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
{% endpolicy_yaml %}
{% endif_version %}
{% if_version gte:2.9.x %}
{% policy_yaml protocol-29x namespace=kuma-demo %}
```yaml
type: MeshCircuitBreaker
name: backend-inbound-outlier-detection
mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: web
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
{% endpolicy_yaml %}
{% endif_version %}

## All policy options

{% json_schema MeshCircuitBreakers %}
