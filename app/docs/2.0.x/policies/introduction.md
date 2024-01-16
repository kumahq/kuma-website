---
title: Policies
---

{% tip %}
**Need help?** Installing and using {{site.mesh_product_name}} should be as easy as
possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are
here to help.
{% endtip %}

Here you can find the list of Policies that {{site.mesh_product_name}} supports.

Going forward from version 2.0, {{site.mesh_product_name}} is transitioning from [source/destination policies](/docs/{{ page.release }}/policies/general-notes-about-kuma-policies) to [`targetRef` policies](/docs/{{ page.release }}/policies/targetref).

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                                                   | `targetRef` policy                                                               |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| [CircuitBreaker](/docs/{{ page.release }}/policies/circuit-breaker)         | N/A                                                                              |
| [FaultInjection](/docs/{{ page.release }}/policies/fault-injection)         | N/A                                                                              |
| [HealthCheck](/docs/{{ page.release }}/policies/health-check)               | N/A                                                                              |
| [RateLimit](/docs/{{ page.release }}/policies/rate-limit)                   | N/A                                                                              |
| [Retry](/docs/{{ page.release }}/policies/retry)                            | N/A                                                                              |
| [Timeout](/docs/{{ page.release }}/policies/timeout)                        | N/A                                                                              |
| [TrafficLog](/docs/{{ page.release }}/policies/traffic-log)                 | [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog)                 |
| [TrafficMetrics](/docs/{{ page.release }}/policies/traffic-metrics)         | N/A                                                                              |
| [TrafficPermissions](/docs/{{ page.release }}/policies/traffic-permissions) | [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission) |
| [TrafficRoute](/docs/{{ page.release }}/policies/traffic-route)             | N/A                                                                              |
| [TrafficTrace](/docs/{{ page.release }}/policies/traffic-trace)             | [MeshTrace](/docs/{{ page.release }}/policies/meshtrace)                         |

{% warning %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies
together.
{% endwarning %}
