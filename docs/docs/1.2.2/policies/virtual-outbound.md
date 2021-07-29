# Virtual Outbounds

This policy enables users to create ways to reach a specific set of dataplanes with a `hostname:port` generated from the dataplanes tags.

Possible use cases are:

1) Preserving hostnames when migrating to service mesh (This enables migration without modifying app configuration).
2) Providing multiple hostnames for reaching the same service (when renaming or usability).
3) For providing specific routes (reach a specific pod in a service for statefulSets, add a url to reach a specific version of a service).

This feature will only work when using transparent proxy.

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

Some constraints:

- If a `tagKey` is absent it uses `name` as `tagKey`.
- `name` must be alphanumeric as it's used as a go template key.
- for a virtual outbound set of parameters all `name` must be unique.
- `kuma.io/service` must be in the parameters even if it's unused in the template (this prevents defining hostnames that spans services).
- All policies `selectors.match` must contain always contain `kuma.io/service` (A wildcard can be used).

For each virtual outbound the kuma control plane will process all dataplanes matching the selector.
It will then apply the templates for `conf.host` and `conf.port` and assign a virtual ip for each unique set defined by all the `tagKeys` value in the parameters.
This means that different hostnames may resolve to the same vip because they map to the same tag set.

### Collisions

We rely on user defined templates it is thus possible to have hostname collisions.

We apply these rules to avoid them:

1) Collision between virtual-outbounds. The virtual outbound with the highest priority takes over as [explained in the policy doc](how-kuma-chooses-the-right-policy-to-apply.md).
2) Collision between 2 hostnames generated within the same virtual outbound. We pick the dataplane which has the `kuma.io/service` tag with the lowest lexicographic order, and a warning will be logged. 

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

Useful when using a headless service in kubernetes.

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
