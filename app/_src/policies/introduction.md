---
title: Policies
---
Here you can find the list of Policies that {{site.mesh_product_name}} supports.

Going forward from version 2.0, {{site.mesh_product_name}} is transitioning from [source/destination policies](/docs/{{ page.release }}/policies/general-notes-about-kuma-policies) to [`targetRef` policies](/docs/{{ page.release }}/policies/targetref).

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                                                   | `targetRef` policy                                                                                                                                                                   |
|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [CircuitBreaker](/docs/{{ page.release }}/policies/circuit-breaker)         | [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker)                                                                                                           |
| [FaultInjection](/docs/{{ page.release }}/policies/fault-injection)         | [MeshFaultInjection](/docs/{{ page.release }}/policies/meshfaultinjection)                                                                                                           |
| [HealthCheck](/docs/{{ page.release }}/policies/health-check)               | [MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck)                                                                                                                 |
| [RateLimit](/docs/{{ page.release }}/policies/rate-limit)                   | [MeshRateLimit](/docs/{{ page.release }}/policies/meshratelimit)                                                                                                                     |
| [Retry](/docs/{{ page.release }}/policies/retry)                            | [MeshRetry](/docs/{{ page.release }}/policies/meshretry)                                                                                                                             |
| [Timeout](/docs/{{ page.release }}/policies/timeout)                        | [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout)                                                                                                                         |
| [TrafficLog](/docs/{{ page.release }}/policies/traffic-log)                 | [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog)                                                                                                                     |
| [TrafficMetrics](/docs/{{ page.release }}/policies/traffic-metrics)         | {% if_version lte:2.5.x inline:true %} N/A {% endif_version %} {% if_version inline:true gte:2.6.x %} [MeshMetric](/docs/{{ page.release }}/policies/meshmetric) {% endif_version %} |
| [TrafficPermissions](/docs/{{ page.release }}/policies/traffic-permissions) | [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission)                                                                                                     |
| [TrafficRoute](/docs/{{ page.release }}/policies/traffic-route)             | [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute)                                                                                                                     |
| [TrafficTrace](/docs/{{ page.release }}/policies/traffic-trace)             | [MeshTrace](/docs/{{ page.release }}/policies/meshtrace)                                                                                                                             |
| [ProxyTemplate](/docs/{{ page.release }}/policies/proxy-template)           | [MeshProxyPatch](/docs/{{ page.release }}/policies/meshproxypatch)                                                                                                                   |

{% warning %}
{% if_version lte:2.5.x %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies
together.
{% endif_version %}
{% if_version gte:2.6.x %}
If you are new to Kuma you should only need to use `targetRef` policies.
If you already use source/destination policies you can keep using them. Future versions of Kuma will provide a migration path.
You can mix targetRef and source/destination policies as long as they are of different types. For example: You can use `MeshTrafficPermission` with `FaultInjection` but you can't use `MeshTrafficPermission` with `TrafficPermission`.
{% endif_version %}
{% endwarning %}
