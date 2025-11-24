---
title: Kuma in Production
content_type: explanation
---

Production deployment of {{site.mesh_product_name}} involves choosing the right topology, deploying control and data planes, and configuring security and operational features. This section guides you through all aspects of running {{site.mesh_product_name}} in production.

## Deployment topologies

Choose the deployment model that fits your infrastructure:

- **[Deployment overview](/docs/{{ page.release }}/production/deployment/)** - Understand deployment modes and when to use each
- **[Single-zone deployment](/docs/{{ page.release }}/production/deployment/single-zone/)** - Deploy {{site.mesh_product_name}} in a single Kubernetes cluster or data center
- **[Multi-zone deployment](/docs/{{ page.release }}/production/deployment/multi-zone/)** - Connect multiple zones across regions, clouds, or data centers
- **[High availability](/docs/{{ page.release }}/production/deployment/high-availability/)** - Configure control plane redundancy for production reliability

Common scenarios:

| Scenario | Recommended topology |
| -------- | -------------------- |
| Single Kubernetes cluster or VPC | {% if_version gte:2.6.x inline:true %}[Single-zone](/docs/{{ page.release }}/production/deployment/single-zone/){% endif_version %}{% if_version lte:2.5.x inline:true %}Standalone{% endif_version %} |
| Multiple regions, clouds, or data centers | [Multi-zone](/docs/{{ page.release }}/production/deployment/multi-zone/) |
| Hybrid Kubernetes and VMs | [Multi-zone](/docs/{{ page.release }}/production/deployment/multi-zone/) |
| Cloud migration (on-premise to cloud) | [Multi-zone](/docs/{{ page.release }}/production/deployment/multi-zone/) |

## Control plane deployment

Deploy and configure the {{site.mesh_product_name}} control plane:

- **[Single-zone control plane](/docs/{{ page.release }}/production/cp-deployment/single-zone/)** - Deploy control plane for a single zone
- **[Multi-zone global control plane](/docs/{{ page.release }}/production/cp-deployment/multi-zone/)** - Deploy global and zone control planes for multi-zone setup
- **[Zone Ingress](/docs/{{ page.release }}/production/cp-deployment/zone-ingress/)** - Configure cross-zone service communication
- **[Zone Egress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/)** - Route external traffic through dedicated egress proxies
- **[Zone proxy authentication](/docs/{{ page.release }}/production/cp-deployment/zoneproxy-auth/)** - Secure zone proxy connections to the global control plane
- **[Kubernetes deployment](/docs/{{ page.release }}/production/cp-deployment/kubernetes/)** - Kubernetes-specific control plane configuration
- **[systemd deployment](/docs/{{ page.release }}/production/cp-deployment/systemd/)** - Run control plane as a system daemon on Universal
- **[Control plane configuration reference](/docs/{{ page.release }}/reference/kuma-cp/)** - Complete configuration options for kuma-cp

## Data plane configuration

Configure data plane proxies for Kubernetes and Universal:

- **[Data plane proxy overview](/docs/{{ page.release }}/production/dp-config/dpp/)** - Understand how data plane proxies work
- **[Kubernetes data plane](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/)** - Configure proxies with sidecar injection on Kubernetes
- **[Universal data plane](/docs/{{ page.release }}/production/dp-config/dpp-on-universal/)** - Configure proxies on VMs or bare metal
- **[Transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/)** - Enable automatic traffic interception without code changes
- **[Kuma CNI](/docs/{{ page.release }}/production/dp-config/cni/)** - Use CNI plugin for network configuration on Kubernetes
- **[IPv6 support](/docs/{{ page.release }}/production/dp-config/ipv6/)** - Configure IPv6 networking

## Secure your deployment

Protect your mesh with authentication, authorization, and encryption:

- **[Secrets management](/docs/{{ page.release }}/production/secure-deployment/secrets/)** - Store and manage sensitive data like certificates and keys
- **[API access control](/docs/{{ page.release }}/production/secure-deployment/api-access-control/)** - Control administrative access to the {{site.mesh_product_name}} API
- **[API server authentication](/docs/{{ page.release }}/production/secure-deployment/api-server-auth/)** - Configure authentication for the control plane API
- **[Data plane proxy authentication](/docs/{{ page.release }}/production/secure-deployment/dp-auth/)** - Require proxies to authenticate before receiving configuration
- **[Data plane proxy membership](/docs/{{ page.release }}/production/secure-deployment/dp-membership/)** - Restrict which proxies can join specific meshes
- **[Certificates](/docs/{{ page.release }}/production/secure-deployment/certificates/)** - Manage TLS certificates for control plane and data plane communication
- **[Kubernetes RBAC](/docs/{{ page.release }}/production/secure-deployment/manage-control-plane-permissions-on-kubernetes/)** - Control plane permissions in Kubernetes environments

## Mesh configuration and multi-tenancy

Organize services and manage multiple teams:

- **[Mesh resource configuration](/docs/{{ page.release }}/production/mesh/)** - Configure mesh resources and multi-tenancy
- **[Using your mesh](/docs/{{ page.release }}/production/use-mesh/)** - Best practices for mesh usage in production

## Operations and maintenance

Manage, monitor, and upgrade your deployment:

- **[Upgrade {{site.mesh_product_name}}](/docs/{{ page.release }}/production/upgrades-tuning/upgrades/)** - Safely upgrade control and data planes
- **[Version-specific upgrade notes](/docs/{{ page.release }}/production/upgrades-tuning/upgrade-notes/)** - Important changes and breaking updates per version
- **[Performance fine-tuning](/docs/{{ page.release }}/production/upgrades-tuning/fine-tuning/)** - Optimize control plane and proxy performance
- **[Kuma GUI](/docs/{{ page.release }}/production/gui/)** - Web interface for managing and observing your mesh
- **[Inspect API](/docs/{{ page.release }}/explore/inspect-api/)** - Debug proxy configuration and policy application
- **[Control plane configuration](/docs/{{ page.release }}/documentation/configuration/)** - Modify and inspect control plane settings

## Tools and utilities

Essential command-line tools:

- **[kumactl CLI](/docs/{{ page.release }}/explore/cli/)** - Command-line interface for managing {{site.mesh_product_name}}
- **[HTTP API reference](/docs/{{ page.release }}/reference/http-api/)** - Complete HTTP API for programmatic access

## Next steps

1. **Choose your topology**: Start with [deployment topologies](/docs/{{ page.release }}/production/deployment/) to decide between single-zone and multi-zone
2. **Deploy control plane**: Follow [single-zone](/docs/{{ page.release }}/production/cp-deployment/single-zone/) or [multi-zone](/docs/{{ page.release }}/production/cp-deployment/multi-zone/) guides
3. **Configure data plane**: Set up proxies for [Kubernetes](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/) or [Universal](/docs/{{ page.release }}/production/dp-config/dpp-on-universal/)
4. **Secure your mesh**: Enable [authentication](/docs/{{ page.release }}/production/secure-deployment/dp-auth/) and [access control](/docs/{{ page.release }}/production/secure-deployment/api-access-control/)
