---
title: Reachable Services
content_type: how-to
---

{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

When the transparent proxy is enabled, {{ Kuma }} automatically configures each data plane proxy to connect with **every other** data plane proxy in the same mesh. This setup ensures broad service-to-service communication but can create issues in large meshes:

- **Increased Memory Usage**: The configuration for each data plane proxy can consume significant memory as the mesh grows.
- **Slower Propagation**: Even small configuration changes for one service must be propagated to all data planes, which can be slow and resource-intensive.
- **Excessive Traffic**: Frequent updates generate additional traffic between the control plane and data plane proxies, especially when services are added or changed often.

In real-world scenarios, services usually need to communicate only with a few other services rather than all services in the mesh. To address these challenges, {{ Kuma }} offers the **Reachable Services** feature, allowing you to define only the services that each proxy should connect to. Specifying reachable services helps reduce memory usage, improves configuration propagation speed, and minimizes unnecessary traffic.

Here’s how to configure reachable services:

{% tabs reachable-services useUrlFragment=false %}
{% tab reachable-services Kubernetes %}
Specify the list of reachable services in the `kuma.io/transparent-proxying-reachable-services` annotation, separating each service with a comma. Your workload configuration could look like this:

```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-client
  annotations:
    kuma.io/transparent-proxying-reachable-services: "redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
...
```

You can update your pods manually or with kubectl:

```sh
kubectl annotate pods example-app \
  "kuma.io/transparent-proxying-reachable-services=redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
```
{% endtab %}
{% tab reachable-services Universal %}
To specify reachable services in your `Dataplane` resource, add them under the `networking.transparentProxying.reachableServices` path. Here’s an example:

```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-client
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableServices:
    - redis_kuma-demo_svc_6379
    - elastic_kuma-demo_svc_9200 
```
{% endtab %}
{% endtabs %}

This configuration ensures that `example-app` only connects to `redis_kuma-demo_svc_6379` and `elastic_kuma-demo_svc_9200`, reducing the overhead associated with managing connections to all services in the mesh.

## Marking a service as not reaching any other service

If you want to indicate that a service should not reach any other service, do not set the annotation to an empty string. An empty value is treated as if no reachable services are configured, meaning the service can access all other services in the mesh.

Instead, use a non-existing service name, such as `_noservice_`, in the annotation. For example:

{% tabs reachable-services-placeholder useUrlFragment=false additionalClasses="codeblock" %}
{% tab reachable-services-placeholder Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: isolated-service
  annotations:
    kuma.io/transparent-proxying-reachable-services: "_noservice_"
...
```
{% endtab %}
{% tab reachable-services-placeholder Universal %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: isolated-service
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableServices:
    - _noservice_
```
{% endtab %}
{% endtabs %}

This ensures that the service does not have access to any other services in the mesh while avoiding unintended behavior caused by an empty annotation.
