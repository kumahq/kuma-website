---
title: Policies
---

{% tip %}
**Need help?** Installing and using {{site.mesh_product_name}} should be as easy as
possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are
here to help.
{% endtip %}

Here you can find the list of Policies that {{site.mesh_product_name}} supports.

Going forward from version 2.0, {{site.mesh_product_name}} is transitioning from [source/destination policies](/docs/{{ page.version }}/policies/general-notes-about-kuma-policies) to [`targetRef` policies](/docs/{{ page.version }}/policies/targetref).

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                                                   | `targetRef` policy                                                               |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| [CircuitBreaker](/docs/{{ page.version }}/policies/circuit-breaker)         | N/A                                                                              |
| [FaultInjection](/docs/{{ page.version }}/policies/fault-injection)         | N/A                                                                              |
| [HealthCheck](/docs/{{ page.version }}/policies/health-check)               | N/A                                                                              |
| [RateLimit](/docs/{{ page.version }}/policies/rate-limit)                   | N/A                                                                              |
| [Retry](/docs/{{ page.version }}/policies/retry)                            | N/A                                                                              |
| [Timeout](/docs/{{ page.version }}/policies/timeout)                        | N/A                                                                              |
| [TrafficLog](/docs/{{ page.version }}/policies/traffic-log)                 | [MeshAccessLog](/docs/{{ page.version }}/policies/meshaccesslog)                 |
| [TrafficMetrics](/docs/{{ page.version }}/policies/traffic-metrics)         | N/A                                                                              |
| [TrafficPermissions](/docs/{{ page.version }}/policies/traffic-permissions) | [MeshTrafficPermission](/docs/{{ page.version }}/policies/meshtrafficpermission) |
| [TrafficRoute](/docs/{{ page.version }}/policies/traffic-route)             | N/A                                                                              |
| [TrafficTrace](/docs/{{ page.version }}/policies/traffic-trace)             | [MeshTrace](/docs/{{ page.version }}/policies/meshtrace)                         |

{% warning %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies
together.
{% endwarning %}
