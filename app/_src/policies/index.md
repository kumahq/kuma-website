---
title: Policies Overview
content_type: explanation
---

[Policies](/docs/{{ page.release }}/introduction/concepts#policy) in {{site.mesh_product_name}} define how [data plane proxies](/docs/{{ page.release }}/introduction/concepts#data-plane-proxy--sidecar) behave and how traffic flows through your mesh. They provide a declarative way to configure security, routing, observability, and resilience features.

## Policy fundamentals

Before applying specific policies, understand how {{site.mesh_product_name}} policies work:

- **[Introduction to policies](/docs/{{ page.release }}/policies/introduction/)** - Learn what policies are, how to write them, and how they're applied to your mesh
- **[Policy selection logic](/docs/{{ page.release }}/policies/how-kuma-chooses-the-right-policy-to-apply/)** - How {{site.mesh_product_name}} determines which policy applies when multiple policies match

## Security and identity

Control authentication, authorization, and traffic encryption:

- **[MeshTLS](/docs/{{ page.release }}/policies/meshtls/)** - Configure TLS for service-to-service communication
- **[Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/)** - Enable automatic mutual TLS between services
- **[MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission/)** - Define which services can communicate with each other
- **[MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/)** - Manage service identity and certificate issuance
- **[MeshTrust](/docs/{{ page.release }}/policies/meshtrust/)** - Configure trust roots for your mesh

## Traffic routing

Shape and control how requests flow between services:

- **[MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/)** - Route HTTP/HTTPS traffic with advanced matching and manipulation
- **[MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/)** - Route TCP traffic to specific backend services
- **[MeshLoadBalancingStrategy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy/)** - Configure load balancing algorithms (round-robin, least-request, etc.)
- **[MeshPassthrough](/docs/{{ page.release }}/policies/meshpassthrough/)** - Control how traffic to external destinations is handled

## Resilience and reliability

Improve service reliability with automatic failure handling:

- **[MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/)** - Set request timeout limits to prevent hanging requests
- **[MeshRetry](/docs/{{ page.release }}/policies/meshretry/)** - Configure automatic retries for failed requests
- **[MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker/)** - Prevent cascading failures by detecting unhealthy services
- **[MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck/)** - Actively monitor service health and remove unhealthy instances
- **[MeshFaultInjection](/docs/{{ page.release }}/policies/meshfaultinjection/)** - Test resilience by injecting delays and failures
- **[MeshRateLimit](/docs/{{ page.release }}/policies/meshratelimit/)** - Protect services from being overwhelmed by requests

## Monitoring and observability

Monitor and understand your mesh behavior:

- **[MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog/)** - Configure access logging to files, Syslog, or external systems
- **[MeshMetric](/docs/{{ page.release }}/policies/meshmetric/)** - Collect metrics from proxies for Prometheus or OpenTelemetry
- **[MeshTrace](/docs/{{ page.release }}/policies/meshtrace/)** - Enable distributed tracing with Zipkin, Jaeger, or OpenTelemetry

## Advanced configuration

Fine-tune proxy behavior for specialized use cases:

- **[MeshProxyPatch](/docs/{{ page.release }}/policies/meshproxypatch/)** - Directly modify Envoy proxy configuration
- **[External services](/docs/{{ page.release }}/policies/external-services/)** - Integrate services outside the mesh
- **[Protocol support](/docs/{{ page.release }}/policies/protocol-support-in-kuma/)** - Understand HTTP/2, grpc, and websocket support
- **[Service health probes](/docs/{{ page.release }}/policies/service-health-probes/)** - Configure Kubernetes and Universal health probes
- **[Locality-aware load balancing](/docs/{{ page.release }}/policies/locality-aware/)** - Prefer local endpoints to reduce latency and cross-zone traffic

## Legacy policies

{% if_version lte:2.12.x %}
These policies are deprecated in favor of the new Mesh* policies:

- [TrafficPermission](/docs/{{ page.release }}/policies/traffic-permissions/)
- [TrafficRoute](/docs/{{ page.release }}/policies/traffic-route/)
- [TrafficMetrics](/docs/{{ page.release }}/policies/traffic-metrics/)
- [TrafficTrace](/docs/{{ page.release }}/policies/traffic-trace/)
- [TrafficLog](/docs/{{ page.release }}/policies/traffic-log/)
- [FaultInjection](/docs/{{ page.release }}/policies/fault-injection/)
- [HealthCheck](/docs/{{ page.release }}/policies/health-check/)
- [CircuitBreaker](/docs/{{ page.release }}/policies/circuit-breaker/)
- [Retry](/docs/{{ page.release }}/policies/retry/)
- [Timeout](/docs/{{ page.release }}/policies/timeout/)
- [RateLimit](/docs/{{ page.release }}/policies/rate-limit/)

See the [migration guide](/docs/{{ page.release }}/guides/migration-to-the-new-policies/) for moving to new policies.
{% endif_version %}

## Next steps

- **Start with security**: Enable [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) and [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission/) for zero-trust security
- **Add resilience**: Configure [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/), [MeshRetry](/docs/{{ page.release }}/policies/meshretry/), and [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker/)
- **Enable observability**: Set up [MeshMetric](/docs/{{ page.release }}/policies/meshmetric/) and [MeshTrace](/docs/{{ page.release }}/policies/meshtrace/) to monitor your services
