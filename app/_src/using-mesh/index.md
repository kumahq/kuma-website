---
title: Using Kuma
content_type: explanation
---

{{site.mesh_product_name}} provides comprehensive features for securing, managing, and observing your service mesh. This section covers practical guides for implementing common patterns and configuring essential functionality.

## Zero trust and application security

Secure service-to-service communication and control access:

- **[Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/)** - Enable automatic encryption and authentication between services
- **[MeshTrust](/docs/{{ page.release }}/policies/meshtrust/)** - Configure certificate authorities and trust domains
- **[MeshIdentity](/docs/{{ page.release }}/policies/meshidentity/)** - Manage workload identities and certificate issuance
- **[External services](/docs/{{ page.release }}/policies/external-services/)** - Integrate and secure connections to external dependencies

Start with [mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) to establish zero-trust security across your mesh.

## Resiliency and reliability

Build reliable applications that handle failures gracefully:

- **[Data plane health](/docs/{{ page.release }}/documentation/health/)** - Configure health checks and circuit breakers
- **[Service health probes](/docs/{{ page.release }}/policies/service-health-probes/)** - Define health checks for Kubernetes and Universal deployments
- **[MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker/)** - Prevent cascading failures
- **[MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck/)** - Actively monitor service health
- **[MeshRetry](/docs/{{ page.release }}/policies/meshretry/)** - Configure automatic request retries
- **[MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/)** - Set request timeout limits

Combine these policies to create resilient services that automatically recover from failures.

## Managing incoming traffic

Configure ingress and expose services outside the mesh:

- **[Gateway overview](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/overview/)** - Understand ingress patterns in {{site.mesh_product_name}}
- **[Built-in gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin/)** - Use Kuma's native gateway solution
- **[Delegated gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/delegated/)** - Integrate third-party ingress controllers
- **[Kubernetes Gateway API](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/gateway-api/)** - Use standard Kubernetes Gateway API resources
- **[Built-in gateway on Kubernetes](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-k8s/)** - Deploy gateway pods on Kubernetes
- **[Configuring listeners](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners/)** - Define gateway listeners for different protocols
- **[Configuring routes](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-routes/)** - Route traffic from gateways to services

Choose built-in gateways for a consistent experience or delegated gateways to use existing infrastructure.

## Monitoring and observability

Gain visibility into mesh behavior and service interactions:

- **[observability guide](/docs/{{ page.release }}/explore/observability/)** - Set up metrics, logs, and traces
- **[MeshMetric](/docs/{{ page.release }}/policies/meshmetric/)** - Collect metrics with Prometheus or OpenTelemetry
- **[MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog/)** - Configure access logging
- **[MeshTrace](/docs/{{ page.release }}/policies/meshtrace/)** - Enable distributed tracing

Integrate with monitoring tools like Prometheus, Grafana, Jaeger, or Datadog for comprehensive observability.

## Traffic routing and shaping

Control how requests flow between services:

- **[MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/)** - Route and manipulate HTTP traffic with advanced matching
- **[MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/)** - Route TCP traffic to backend services
- **[MeshLoadBalancingStrategy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy/)** - Configure load balancing algorithms
- **[Protocol support](/docs/{{ page.release }}/policies/protocol-support-in-kuma/)** - Understand HTTP/2, grpc, and websocket support
- **[MeshRateLimit](/docs/{{ page.release }}/policies/meshratelimit/)** - Protect services from traffic spikes

Use routing policies for traffic splitting, canary deployments, and A/B testing.

## Service discovery and networking

Configure how services discover and communicate with each other:

- **[Networking overview](/docs/{{ page.release }}/networking/)** - Service discovery and DNS configuration
- **[Service discovery](/docs/{{ page.release }}/networking/service-discovery/)** - How {{site.mesh_product_name}} discovers services
- **[MeshService](/docs/{{ page.release }}/networking/meshservice/)** - Define services for precise control
- **[MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice/)** - Configure cross-zone services
- **[DNS](/docs/{{ page.release }}/networking/dns/)** - Built-in DNS for service name resolution
- **[Transparent proxying](/docs/{{ page.release }}/networking/transparent-proxying/)** - Automatic traffic interception
- **[Non-mesh traffic](/docs/{{ page.release }}/networking/non-mesh-traffic/)** - Handle traffic outside the mesh

Start with [service discovery](/docs/{{ page.release }}/networking/service-discovery/) to understand how {{site.mesh_product_name}} tracks services.

## Common use cases

### Secure microservices

1. Enable [mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) for encryption
2. Configure [MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission/) for access control
3. Set up [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog/) for audit trails

### Build resilient applications

1. Configure [MeshTimeout](/docs/{{ page.release }}/policies/meshtimeout/) to prevent hanging requests
2. Enable [MeshRetry](/docs/{{ page.release }}/policies/meshretry/) for automatic retries
3. Add [MeshCircuitBreaker](/docs/{{ page.release }}/policies/meshcircuitbreaker/) to prevent cascading failures
4. Configure [MeshHealthCheck](/docs/{{ page.release }}/policies/meshhealthcheck/) to remove unhealthy instances

### Expose services with ingress

1. Choose between [built-in](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin/) or [delegated](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/delegated/) gateways
2. Deploy and configure gateway instances
3. Create [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/) or [MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/) policies
4. Apply security policies to gateway traffic

### Monitor and debug

1. Deploy [Prometheus and Grafana](/docs/{{ page.release }}/explore/observability/#configuring-prometheus) for metrics
2. Configure [MeshMetric](/docs/{{ page.release }}/policies/meshmetric/) to collect data plane metrics
3. Enable [MeshTrace](/docs/{{ page.release }}/policies/meshtrace/) for distributed tracing
4. Use [Inspect API](/docs/{{ page.release }}/explore/inspect-api/) to debug policy application

## Next steps

- **Secure your mesh**: Start with [mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) for zero-trust security
- **Add resilience**: Configure [timeout](/docs/{{ page.release }}/policies/meshtimeout/), [retry](/docs/{{ page.release }}/policies/meshretry/), and [circuit breaker](/docs/{{ page.release }}/policies/meshcircuitbreaker/) policies
- **Enable observability**: Set up [metrics](/docs/{{ page.release }}/policies/meshmetric/) and [tracing](/docs/{{ page.release }}/policies/meshtrace/)
- **Configure ingress**: Choose a [gateway solution](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/overview/) to expose services
