---
title: Reachable Backends
content_type: how-to
---

{% assign docs = "/docs/" | append: page.release %}
{% assign Kuma = site.mesh_product_name %}
{% assign tproxy = site.data.tproxy %}

{% capture Important %}{% if page.edition and page.edition != "kuma" %}**Important:** {% endif %}{% endcapture %}

{% warning %}
{{ Important }}This feature works only when [MeshService]({{ docs }}/networking/meshservice) is enabled.
{% endwarning %}

Reachable Backends provides similar functionality to [Reachable Services]({{ docs }}/networking/transparent-proxy/reachable-services/), but it applies to resources such as [MeshService]({{ docs }}/networking/meshservice), [MeshExternalService]({{ docs }}/networking/meshexternalservice), and [MeshMultiZoneService]({{ docs }}/networking/meshmultizoneservice).

By default, each data plane proxy can access all other services in the mesh, which affects performance and increases resource consumption. Defining a specific set of services your application communicates with allows {{ Kuma }} to reduce the configuration size and operate more efficiently.

Unlike Reachable Services, Reachable Backends uses a structured model that allows dynamic selection based on multiple attributes, including labels, instead of relying on a predefined, static list. This makes it more flexible and scalable, especially in environments with frequently changing workloads.

### Model

<!-- vale Vale.Terms = NO -->  
- **refs**: Lists the resources your application needs to connect with, including:
  - **kind**: Type of resource. Options include:
    - **MeshService**
    - **MeshExternalService**
    - **MeshMultiZoneService**
  - **name**: Name of the resource. Mutually exclusive with `labels`.
  - **namespace**: (Kubernetes only) Namespace where the resource is located.
  - **labels**: A list of labels used to match resources. When specified, it selects **all** workloads that have these labels, rather than a single named resource. Mutually exclusive with `name`.
  - **port**: (Optional) Port for the service, used with `MeshService` and `MeshMultiZoneService`.
<!-- vale Vale.Terms = YES -->

{% tabs reachable-backends-model useUrlFragment=false %}
{% tab reachable-backends-model Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        name: redis
        namespace: kuma-demo
        port: 8080
      - kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: test-server
      - kind: MeshExternalService
        name: mes-http
        namespace: kuma-system
...
```
{% endtab %}
{% tab reachable-backends-model Universal %}
```yaml
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
      - kind: MeshMultiZoneService
        labels:
          kuma.io/display-name: test-server
      - kind: MeshExternalService
        name: mes-http
```
{% endtab %}
{% endtabs %}

### Examples

<!-- vale Google.Headings = NO -->
#### `demo-app` communicates only with `redis` on port 6379
<!-- vale Google.Headings = YES -->

{% tabs reachable-backends useUrlFragment=false %}
{% tab reachable-backends Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        name: redis
        namespace: kuma-demo
        port: 6379
...
```
{% endtab %}
{% tab reachable-backends Universal %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
        port: 6379
```
{% endtab %}
{% endtabs %}

<!-- vale Google.Headings = NO -->
#### `demo-app` doesn’t need to communicate with any service
<!-- vale Google.Headings = YES -->

{% tabs reachable-backends-no-services useUrlFragment=false %}
{% tab reachable-backends-no-services Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Pod
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs: []
...
```
{% endtab %}
{% tab reachable-backends-no-services Universal %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableBackends:
      refs: []
```
{% endtab %}
{% endtabs %}

<!-- vale Google.Headings = NO -->
#### `demo-app` communicates with all MeshServices in the `kuma-demo` namespace
<!-- vale Google.Headings = YES -->

{% tabs reachable-backends-in-namespace useUrlFragment=false %}
{% tab reachable-backends-in-namespace Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    kuma.io/reachable-backends: |
      refs:
      - kind: MeshService
        labels:
          k8s.kuma.io/namespace: kuma-demo
...
```
{% endtab %}
{% tab reachable-backends-in-namespace Universal %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: {{ tproxy.defaults.redirect.inbound.port }}
    redirectPortOutbound: {{ tproxy.defaults.redirect.outbound.port }}
    reachableBackends:
      refs:
      - kind: MeshService
        labels:
          k8s.kuma.io/namespace: kuma-demo
...
```
{% endtab %}
{% endtabs %}
