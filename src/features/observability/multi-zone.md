---
title: Configure multi-zone observability
---
## Observability in multi-zone

Kuma is multi-zone at heart. We explain here how to architect your telemetry stack to accommodate multi-zone.

### Prometheus

When Kuma is used in multi-zone the recommended approach is to use 1 Prometheus instance in each zone and to send the metrics of each zone to a global Prometheus instance.

Prometheus offers different ways to do this:

- [Federation](https://prometheus.io/docs/prometheus/latest/federation/) the global Prometheus will scrape each zone Prometheuses.
- [Remote Write](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations) each zone Prometheuses will directly write their metrics to the global, this is meant to be more efficient the API the federation.
- [Remote Read](https://prometheus.io/docs/prometheus/latest/storage/#remote-storage-integrations) like remote write but the other way around.

### Jaeger, Loki, Datadog and others

Most telemetry components don't have a hierarchical setup like Prometheus.
If you want to have a central view of everything you can set up the system in global and have each zone send their data to it.
Because zone is present in data plane tags you shouldn't be worried about metrics, logs and traces overlapping between zones.
