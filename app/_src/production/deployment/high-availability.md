---
title: High availability
content_type: explanation
---

In order to ensure high availability (HA) of a control plane, both global and zone,
you can deploy more than one replica.

Each replica should be behind a load balancer such that requests to the control
plane API are distributed across the replicas.

On Kubernetes this is handled using a Deployment and a Service.
When your control plane isn't deployed on Kubernetes, it's up to you to handle
this within your infrastructure.

## Leader

Control planes also perform tasks independent of API requests. To avoid
conflicts, each of these tasks needs to be performed by only one instance at a
time, by the _leader_.

For each logical control plane, the instances work together to ensure there's only one
leader at a time. When the control planes are running in universal mode, this is
handled by the leader maintaining a lock on the database. In Kubernetes mode, it's
handled similarly but uses the built-in coordination API resources.

An example of a leader task is that every zone control plane leader
maintains a connection to the global control plane in order to:

- send relevant changes in the zone to the global control plane
- receive and act on relevant updates about the global state
