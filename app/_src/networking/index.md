---
title: Service Discovery & Networking
content_type: explanation
---

{{site.mesh_product_name}} provides a comprehensive networking layer that handles service discovery, DNS resolution, traffic routing, and connectivity between services in your mesh. This section covers how services communicate with each other and with external systems.

## Service discovery

Understand how {{site.mesh_product_name}} discovers and tracks services:

- **[Service discovery overview](/docs/{{ page.release }}/networking/service-discovery/)** - How {{site.mesh_product_name}} automatically discovers services in Kubernetes and Universal modes
- **[MeshService](/docs/{{ page.release }}/networking/meshservice/)** - Define services within your mesh for more granular control and cross-zone communication
- **[MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice/)** - Configure services that span multiple zones in multi-zone deployments
- **[MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice/)** - Integrate external services (databases, APIs, third-party services) into your mesh

## DNS and hostname resolution

Configure DNS for service-to-service communication:

- **[DNS](/docs/{{ page.release }}/networking/dns/)** - Built-in DNS server for service name resolution within the mesh
- **[HostnameGenerator](/docs/{{ page.release }}/networking/hostnamegenerator/)** - Customize DNS hostname generation for services

## Traffic interception and proxying

Control how traffic flows through the mesh:

- **[Transparent proxying](/docs/{{ page.release }}/networking/transparent-proxying/)** - Automatically intercept application traffic without code changes or configuration
- **[Non-mesh traffic](/docs/{{ page.release }}/networking/non-mesh-traffic/)** - Handle traffic to and from services outside the mesh, including passthrough and direct access

## Common networking patterns

### Internal service communication

For services communicating within the mesh:

1. Use [service discovery](/docs/{{ page.release }}/networking/service-discovery/) to automatically detect services
2. Enable [transparent proxying](/docs/{{ page.release }}/networking/transparent-proxying/) for automatic traffic interception
3. Configure [DNS](/docs/{{ page.release }}/networking/dns/) for hostname-based service resolution
4. Apply routing policies with [MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/) or [MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/)

### External service integration

To connect mesh services with external dependencies:

1. Define external services using [MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice/)
2. Configure [non-mesh traffic](/docs/{{ page.release }}/networking/non-mesh-traffic/) policies for passthrough or direct access
3. Use [MeshPassthrough](/docs/{{ page.release }}/policies/meshpassthrough/) policy to control traffic to external destinations

### Multi-zone service communication

For services across multiple zones:

1. Deploy [multi-zone topology](/docs/{{ page.release }}/production/deployment/multi-zone/)
2. Use [MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice/) to define cross-zone services
3. Configure [Zone Ingress](/docs/{{ page.release }}/production/cp-deployment/zone-ingress/) for inter-zone communication
4. Optionally configure [Zone Egress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/) for external traffic

## Related policies

Networking works in conjunction with these policies:

- **[MeshHTTPRoute](/docs/{{ page.release }}/policies/meshhttproute/)** - Route and manipulate HTTP traffic between services
- **[MeshTCPRoute](/docs/{{ page.release }}/policies/meshtcproute/)** - Route TCP traffic to backend services
- **[MeshLoadBalancingStrategy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy/)** - Configure load balancing algorithms
- **[MeshPassthrough](/docs/{{ page.release }}/policies/meshpassthrough/)** - Control passthrough traffic to external destinations
- **[MeshTrafficPermission](/docs/{{ page.release }}/policies/meshtrafficpermission/)** - Define which services can communicate

## Next steps

- **Start with basics**: Understand [service discovery](/docs/{{ page.release }}/networking/service-discovery/) and how {{site.mesh_product_name}} tracks services
- **Enable transparent proxying**: Configure [transparent proxying](/docs/{{ page.release }}/networking/transparent-proxying/) to intercept traffic automatically
- **Set up DNS**: Use [DNS](/docs/{{ page.release }}/networking/dns/) for hostname-based service resolution
- **Add external services**: Define [MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice/) resources for dependencies outside the mesh
