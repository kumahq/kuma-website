---
title: Unified resource naming
content_type: tutorial
---

Right now, Envoy resources and stats in Kuma use different naming styles.
Some follow legacy or default Envoy formats, which makes them harder to understand and trace.
Resource names and their related stats often don’t match, even when they come from the same Kuma resource.
This makes it difficult to work with observability tools and troubleshoot issues.



For example, if you want to query stats for all upstream connections to other services excluding kuma related clusters, you need to use the following query:

```
sum:envoy.cluster.upstream_rq.count{service:my-example-service, !envoy_cluster:kuma_* , !envoy_cluster:meshtrace_* , !envoy_cluster:access_log_sink} by {envoy_cluster}.as_count()
```

Which is not very intuitive.



