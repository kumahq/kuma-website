---
title: Virtual Outbound
---

This policy lets you customize hostnames and ports for communicating with data plane proxies.

Possible use cases are:

1. Preserving hostnames when migrating to service mesh.
2. Providing multiple hostnames for reaching the same service, for example when renaming or for usability.
3. Providing specific routes, for example to reach a specific pod in a service with StatefulSets on Kubernetes, or to add a URL to reach a specific version of a service.
4. Expose multiple inbounds on different ports.

Limitations:

{% if_version lte:2.3.x %}
- A virtual outbound that contains any parameters other than `kuma.io/service` won’t work cross-zone.
{% endif_version %}
- When duplicate `(hostname, port)` combinations are detected, the virtual outbound with the highest priority takes over. For more information, see [the documentation on how {{site.mesh_product_name}} chooses the right policy](/docs/{{ page.release }}/policies/how-kuma-chooses-the-right-policy-to-apply). All duplicate instances are logged.

`conf.host` and `conf.port` are processed as [go text templates](https://pkg.go.dev/text/template) with a key-value pair derived from `conf.parameters`.

`conf.selectors` are used to specify which proxies this policy applies to.

For example a proxy with this definition:

```yaml
type: Dataplane
mesh: default
name: backend-1
networking:
  address: 192.168.0.2
inbound:
  - port: 9000
    servicePort: 6379
    tags:
      kuma.io/service: backend
      version: v1
      port: 1800
```

and a virtual outbound with this definition:

{% tabs %}
{% tab Kubernetes %}
{% raw %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
  name: test
spec:
  selectors:
    - match:
        kuma.io/service: "*"
  conf:
    host: "{{.v}}.{{.service}}.mesh"
    port: "{{.port}}"
    parameters:
      - name: service
        tagKey: "kuma.io/service"
      - name: port
        tagKey: "k8s.kuma.io/service-port"
      - name: v
        tagKey: version
```
{% endraw %}
{% endtab %}
{% tab Universal %}
{% raw %}
```yaml
type: VirtualOutbound
mesh: default
name: test
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.v}}.{{.service}}.mesh"
  port: "{{.port}}"
  parameters:
    - name: service
      tagKey: "kuma.io/service"
    - name: port
      tagKey: port
    - name: v
      tagKey: version
```
{% endraw %}
{% endtab %}
{% endtabs %}

produce the hostname: `v1.backend.mesh` with port: `1800`.

Additional Requirements:

- [Transparent proxying](/docs/{{ page.release }}/production/dp-config/transparent-proxying/) must be enabled.
- Either:
  - [Data plane proxy DNS](/docs/{{ page.release }}/networking/dns) must be enabled.
  - Or, the value of `conf.host` must end with the value of `dns_server.domain`, which defaults to `.mesh`.
- Parameter names must be alphanumeric. These names are used as Go template keys.
- Parameter names must be unique. This ensures that each parameter can be referenced unambiguously.
- Parameter with the `kuma.io/service` tagKey must be specified even if it is not used in the template. This prevents hostnames from being defined that could span multiple services.

The default value of `tagKey` is the value of `name`.

For each virtual outbound, the {{site.mesh_product_name}} control plane processes all data plane proxies that match the selector.
It then applies the templates for `conf.host` and `conf.port` and assigns a virtual IP address for each hostname.

## Examples

The following examples show how to use virtual outbounds for different use cases.

### Same as the default DNS

{% tabs %}
{% tab Kubernetes %}
{% raw %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
    name: default
spec:
    selectors:
      - match:
          kuma.io/service: "*"
    conf:
      host: "{{.service}}.mesh"
      port: "80"
      parameters:
        - name: service
          tagKey: "kuma.io/service"
```
{% endraw %}
{% endtab %}
{% tab Universal %}
{% raw %}
```yaml
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.service}}.mesh"
  port: "80"
  parameters:
    - name: service
      tagKey: "kuma.io/service"
```
{% endraw %}
{% endtab %}
{% endtabs %}

### One hostname per version

{% tabs %}
{% tab Kubernetes %}
{% raw %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
  name: versioned
spec:
    selectors:
      - match:
          kuma.io/service: "*"
    conf:
      host: "{{.service}}.{{.version}}.mesh"
      port: "80"
      parameters:
        - name: service
          tagKey: "kuma.io/service"
        - name: version
          tagKey: "kuma.io/version"
```
{% endraw %}
{% endtab %}
{% tab Universal %}
{% raw %}
```yaml
type: VirtualOutbound
mesh: default
name: versioned
spec:
    selectors:
      - match:
          kuma.io/service: "*"
    conf:
      host: "{{.service}}.{{.version}}.mesh"
      port: "80"
      parameters:
        - name: service
          tagKey: "kuma.io/service"
        - name: version
          tagKey: "kuma.io/version"
```
{% endraw %}
{% endtab %}
{% endtabs %}

### Custom tag to define the hostname and port

{% tabs %}
{% tab Kubernetes %}
{% raw %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
  name: host-port
spec:
    selectors:
      - match:
          kuma.io/service: "*"
    conf:
      host: "{{.hostname}}"
      port: "{{.port}}"
      parameters:
        - name: hostname
          tagKey: "my.mesh/hostname"
        - name: port
          tagKey: "my.mesh/port"
```
{% endraw %}
{% endtab %}
{% tab Universal %}
{% raw %}
```yaml
type: VirtualOutbound
mesh: default
name: host-port
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.hostname}}"
  port: "{{.port}}"
  parameters:
    - name: hostname
      tagKey: "my.mesh/hostname"
    - name: port
      tagKey: "my.mesh/port"
    - name: service
```
{% endraw %}
{% endtab %}
{% endtabs %}

### One hostname per instance

Enables reaching specific data plane proxies for a service.
Useful for running distributed databases such as Kafka or Zookeeper.

{% tabs %}
{% tab Kubernetes %}
{% raw %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
  name: instance
spec:
  selectors:
    - match:
        kuma.io/service: "*"
        statefulset.kubernetes.io/pod-name: "*"
  conf:
    host: "{{.svc}}.{{.inst}}.mesh"
    port: "8080"
    parameters:
      - name: "svc"
        tagKey: "kuma.io/service"
      - name: "inst"
        tagKey: "statefulset.kubernetes.io/pod-name"
```
{% endraw %}
{% endtab %}
{% tab Universal %}
{% raw %}
```yaml
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
      kuma.io/instance: "*"
conf:
  host: "inst-{{.instance}}.{{.service}}.mesh"
  port: "8080"
  parameters:
    - name: service
      tagKey: "kuma.io/service"
    - name: instance
      tagKey: "kuma.io/instance"
```
{% endraw %}
{% endtab %}
{% endtabs %}

## All options

{% json_schema VirtualOutbound type=proto %}
