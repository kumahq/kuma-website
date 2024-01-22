---
layout: features
title: Features
subTitle: Bundled features for your service traffic and network configuration.
themeContainerClasses: 'no-sidebar'

# the data that is used to build this page
features:
  - section: security
    sectionTitle: Security
    sectionSubTitle: Identity, Encryption and Compliance
    items:
      - title: Mesh / Multi-Mesh (Multi-tenancy)
        url: /docs/latest/production/mesh/
        icon: /assets/images/icons/policies/icon-mesh-multi-tenancy@2x.png
      - title: Mutual TLS (mTLS)
        url: /docs/latest/policies/mutual-tls/
        icon: /assets/images/icons/policies/icon-mtls@2x.png
      - title: Mesh Traffic Permissions
        url: /docs/latest/policies/meshtrafficpermission/
        icon: /assets/images/icons/policies/icon-traffic-control@2x.png
  - section: ingress-traffic
    sectionTitle: Ingress Traffic
    sectionSubTitle: Getting traffic inside your mesh
    items:
    - title: Delegated Gateway
      url: /docs/latest/explore/gateway/#delegated 
      icon: /assets/images/icons/policies/icon-delegatedgateway.png
    - title: Builtin Gateway
      url: /docs/latest/explore/gateway/#builtin
      icon: /assets/images/icons/policies/icon-builtingateway.png
    - title: Gateway API
      url: /docs/latest/explore/gateway-api
      icon: /assets/images/icons/policies/icon-gatewayapi.png
  - section: traffic-control
    sectionTitle: Traffic Control
    sectionSubTitle: Routing, Ingress, Failover
    items:
      - title: Mesh HTTP Route 
        url: /docs/latest/policies/meshhttproute/
        icon: /assets/images/icons/policies/icon-traffic-route@2x.png
      - title: Mesh TCP Route
        url: /docs/latest/policies/meshtcproute/
        icon: /assets/images/icons/policies/icon-traffic-route@2x.png
      - title: Mesh Health Check
        url: /docs/latest/policies/meshhealthcheck/
        icon: /assets/images/icons/policies/icon-healthcheck@2x.png
      - title: Mesh Circuit Breaker
        url: /docs/latest/policies/meshcircuitbreaker/
        icon: /assets/images/icons/policies/icon-circuitbreaker.png
      - title: Mesh Fault Injection
        url: /docs/latest/policies/meshfaultinjection
        icon: /assets/images/icons/policies/icon-fault-injection@2x.png
      - title: External Services
        url: /docs/latest/policies/external-services/
        icon: /assets/images/icons/policies/icon-external-services.png
      - title: Mesh Retry
        url: /docs/latest/policies/meshretry/
        icon: /assets/images/icons/policies/retry@2x.png
      - title: Mesh Timeout
        url: /docs/latest/policies/meshtimeout/
        icon: /assets/images/icons/policies/icon-timeout@2x-80.jpg
      - title: Mesh Rate Limit
        url: /docs/latest/policies/meshratelimit/
        icon: /assets/images/icons/policies/icon-rate-limits.png
      - title: Virtual Outbound
        url: /docs/latest/policies/virtual-outbound/
        icon: /assets/images/icons/policies/virtual-outbound@2x.png
  - section: observability
    sectionTitle: Observability
    sectionSubTitle: Metrics, Logs and Traces
    items:
      - title: Service Map
        url: /docs/latest/explore/observability/#datasource-and-service-map
        icon: /assets/images/icons/policies/service-map@2x.png
      - title: Mesh Metric
        url: /docs/latest/policies/meshmetric/
        icon: /assets/images/icons/policies/icon-dataplane-metrics@2x.png
      - title: Mesh Trace
        url: /docs/latest/policies/meshtrace/
        icon: /assets/images/icons/policies/icon-traffic-trace@2x.png
      - title: Mesh Access Log
        url: /docs/latest/policies/meshaccesslog/
        icon: /assets/images/icons/policies/icon-traffic-log@2x.png
      - title: Open telemetry support 
        url: /docs/latest/explore/observability/
        icon: /assets/images/icons/policies/icon-opentelemetry.png

  - section: advanced
    sectionTitle: Advanced
    sectionSubTitle: Envoy configuration and Miscellaneous
    items:
      - title: Mesh Proxy Patch 
        url: /docs/latest/policies/meshproxypatch/
        icon: /assets/images/icons/policies/icon-proxy-template@2x.png
      - title: DP/CP Security
        url: /docs/latest/production/secure-deployment/dp-auth/
        icon: /assets/images/icons/policies/icon-dc-cp-security@2x.png
---
