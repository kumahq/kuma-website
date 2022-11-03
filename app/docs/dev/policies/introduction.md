---
title: Policies
---

{% tip %}
**Need help?** Installing and using {{site.mesh_product_name}} should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
{% endtip %}

Here you can find the list of Policies that {{site.mesh_product_name}} supports, that will allow you to build a modern and reliable Service
Mesh.

Since 2.0 {{site.mesh_product_name}} is transitioning between 2 formats for policies:

1. The [source/destination policies](../general-notes-about-kuma-policies) which are the ones that will be replaced.
2. The [`targetRef` policies](../targetref) which are being introduced from 2.0

The following table shows the equivalence between source/destination and `targetRef` policies:

| source/destination policy                    | `targetRef` policy                |
|----------------------------------------------|-----------------------------------|
| [CircuitBreaker](../circuit-breaker)         | N/A                               |
| [FaultInjection](../fault-injection)         | N/A                               |
| [HealthCheck](../health-check)               | N/A                               |
| [RateLimit](../rate-limit)                   | N/A                               |
| [Retry](../retry)                            | N/A                               |
| [Timeout](../timeout)                        | N/A                               |
| [TrafficLog](../traffic-log)                 | [MeshAccessLog](../meshaccesslog) |
| [TrafficMetrics](../traffic-metrics)         | N/A                               |
| [TrafficPermissions](../traffic-permissions) | MeshTrafficPermission             |
| [TrafficRoute](../traffic-route)             | N/A                               |
| [TrafficTrace](../traffic-trace)             | [MeshTrace](../meshtrace)         |

{% warning %}
`targetRef` policies are still beta and it is therefore not supported to mix source/destination and targetRef policies together.
{% endwarning %}
