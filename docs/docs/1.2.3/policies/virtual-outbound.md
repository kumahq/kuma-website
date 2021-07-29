# Virtual Outbounds

This policy enables users to create ways to reach a specific set of dataplanes with a `hostname:port` generated from the dataplanes tags.

Possible use cases are:

1) Preserving hostnames when migrating to service mesh (This enables migration without modifying app configuration).
2) Providing multiple hostnames for reaching the same service (when renaming or for usability).
3) Providing specific routes (reach a specific pod in a service when using StatefulSets, add an url to reach a specific version of a service).
4) Expose multiple inbounds on different ports.

## Usage

`conf.host` and `conf.port` are processed as [go text templates](https://pkg.go.dev/text/template) with a map of key, value constituted from `conf.parameters`.

For example a dataplane with this definition:

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

A virtual outbound with definition:

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

Will create a hostname: `v1.backend.mesh` and port: `1800`.

Virtual Outbounds have some constraints/limitations:

- It only works when using transparent proxy.
- When not using the [data plane proxy DNS](/docs/1.2.3/networking/dns.md#data-plane-proxy-dns), all generated hostnames must end with the value of the configuration `dns_server.domain` (whose default is `.mesh`).
- If a `tagKey` is absent it uses `name` as `tagKey`.
- `name` must be alphanumeric as it's used as a go template key.
- for a virtual-outbound set of parameters all `name` must be unique.
- `kuma.io/service` must be in the parameters even if it's unused in the template (this prevents defining hostnames that spans services).

For each virtual outbound the Kuma control plane will process all dataplanes matching the selector.
It will then apply the templates for `conf.host` and `conf.port` and assign a virtual ip for each unique set defined by all the `tagKeys` value in the parameters.
This means that different hostnames may resolve to the same vip because they map to the same tag set.

### Collisions

We rely on user defined templates it is thus possible to have hostname collisions.

We apply these rules to avoid them:

1) For collisions between virtual outbounds, the virtual outbound with the highest priority takes over as [explained in the policy doc](../../1.2.2/policies/how-kuma-chooses-the-right-policy-to-apply.md).
2) For all collisions log messages will be emitted. 
3) Because only service tags are propagated across zones complex virtual outbounds will not work for cross-zone traffic. 

### Examples

#### Same as the default DNS

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.service}}.mesh"
  port: 80
  parameters:
    - name: service
      tagKey: "kuma.io/service"
```
:::
::: tab "Universal"
```yaml
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.service}}.mesh"
  port: 80
  parameters:
    - name: service
      tagKey: "kuma.io/service"
```
:::
::::

#### One hostname per version

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.service}}.{{.version}}.mesh"
  port: 80
  parameters:
    - name: service
      tagKey: "kuma.io/service"
    - name: version
      tagKey: "kuma.io/version"
```
:::
::: tab "Universal"
```yaml
type: VirtualOutbound
mesh: default
name: default
selectors:
  - match:
      kuma.io/service: "*"
conf:
  host: "{{.service}}.{{.version}}.mesh"
  port: 80
  parameters:
    - name: service
      tagKey: "kuma.io/service"
    - name: version
      tagKey: "kuma.io/version"
```
:::
::::

#### Custom tag to define the hostname and port

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
type: VirtualOutbound
mesh: default
name: default
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
:::
::: tab "Universal"
```yaml
type: VirtualOutbound
mesh: default
name: default
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
:::
::::

#### One hostname per instance

This enables reaching specific dataplanes in a service.
This is especially useful for running distributed databases like Kafka, Zookeeper...

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
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
:::
::: tab "Universal"
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
  port: 80
  parameters:
    - name: service
      tagKey: "kuma.io/service"
    - name: instance
      tagKey: "kuma.io/instance"
```
:::
::::
