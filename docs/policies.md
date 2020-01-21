---
sidebar: false
layout: Policies
title: Policies
subTitle: Bundled policies for your services and network.

# the data that is used to build this page
policies:
  - section: security
    sectionTitle: Security
    sectionSubTitle: Identity, Encryption and Compliance
    items:
      - title: mTLS
        url: /docs/latest/policies/#mutual-tls
      - title: Traffic Permissions
        url: /docs/latest/policies/#traffic-permissions
      - title: DP/CP Security
        url: /docs/latest/documentation/#dataplane-token
  - section: traffic-control
    sectionTitle: Traffic Control
    sectionSubTitle: Routing, Versioning, Deployments
    items:
      - title: Traffic Route
        url: /docs/latest/policies/#traffic-route
  - section: observability
    sectionTitle: Observability
    sectionSubTitle: Metrics, Logs and Traces
    items:
      - title: Traffic Metrics
        url: /docs/latest/policies/#traffic-metrics
      - title: Traffic Trace
        url: /docs/latest/policies/#traffic-tracing
      - title: Traffic Log
        url: /docs/latest/policies/#traffic-log
  - section: advanced
    sectionTitle: Advanced
    sectionSubTitle: Envoy configuration and Miscellaneous
    items:
      - title: Mesh/Multi-tenancy
        url: /docs/latest/policies/#mesh
      - title: Proxy Template
        url: /docs/latest/policies/#proxy-template
      - title: Healthcheck
        url: /docs/latest/policies/#health-check
---