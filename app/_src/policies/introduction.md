---
title: Policies
---
Here you can find the list of Policies that {{site.mesh_product_name}} supports.

Going forward from version 2.0, {{site.mesh_product_name}} is transitioning from [source/destination policies](/docs/{{ page.version }}/policies/general-notes-about-kuma-policies) to [`targetRef` policies](/docs/{{ page.version }}/policies/targetref).

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                                                   | `targetRef` policy                                                               |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| [CircuitBreaker](/docs/{{ page.version }}/policies/circuit-breaker)         | [MeshCircuitBreaker](/docs/{{ page.version }}/policies/meshcircuitbreaker)       |
| [FaultInjection](/docs/{{ page.version }}/policies/fault-injection)         | [MeshFaultInjection](/docs/{{ page.version }}/policies/meshfaultinjection)       |
| [HealthCheck](/docs/{{ page.version }}/policies/health-check)               | [MeshHealthCheck](/docs/{{ page.version }}/policies/meshhealthcheck)             |
| [RateLimit](/docs/{{ page.version }}/policies/rate-limit)                   | [MeshRateLimit](/docs/{{ page.version }}/policies/meshratelimit)                 |
| [Retry](/docs/{{ page.version }}/policies/retry)                            | [MeshRetry](/docs/{{ page.version }}/policies/meshretry)                         |
| [Timeout](/docs/{{ page.version }}/policies/timeout)                        | [MeshTimeout](/docs/{{ page.version }}/policies/meshtimeout)                     |
| [TrafficLog](/docs/{{ page.version }}/policies/traffic-log)                 | [MeshAccessLog](/docs/{{ page.version }}/policies/meshaccesslog)                 |
| [TrafficMetrics](/docs/{{ page.version }}/policies/traffic-metrics)         | [MeshMetric](/docs/{{ page.version }}/policies/meshmetric)                       |
| [TrafficPermissions](/docs/{{ page.version }}/policies/traffic-permissions) | [MeshTrafficPermission](/docs/{{ page.version }}/policies/meshtrafficpermission) |
| [TrafficRoute](/docs/{{ page.version }}/policies/traffic-route)             | [MeshHTTPRoute](/docs/{{ page.version }}/policies/meshhttproute)                 |
| [TrafficTrace](/docs/{{ page.version }}/policies/traffic-trace)             | [MeshTrace](/docs/{{ page.version }}/policies/meshtrace)                         |
| [ProxyTemplate](/docs/{{ page.version }}/policies/proxy-template)           | [MeshProxyPatch](/docs/{{ page.version }}/policies/meshproxypatch)               |

{% warning %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies
together.
{% endwarning %}
