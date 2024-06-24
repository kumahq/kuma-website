---
title: MeshService
---

{% warning %}
This resource is experimental!
In Kubernetes, to take advantage of the automatic generation described below,
you need to set both [control plane configuration variables](/docs/{{ page.version }}/reference/kuma-cp/) `KUMA_EXPERIMENTAL_SKIP_PERSISTED_VIPS`
and `KUMA_EXPERIMENTAL_GENERATE_MESH_SERVICES` to `"true"` on the zone control
planes that use `MeshServices`.
{% endwarning %}

MeshService is a new resource that represents what was previously expressed by
the `Dataplane` tag `kuma.io/service`. Kubernetes users should think about it as
the analog of a Kubernetes `Service`.

A basic example follows to illustrate the structure:

{% policy_yaml meshservice_example %}
```yaml
type: MeshService
name: redis
mesh: default
labels:
  team: db-operators
spec:
  selector:
    dataplaneTags: # tags in Dataplane object, see below
      app: redis
      k8s.kuma.io/namespace: redis-system # added automatically
  ports:
  - port: 6739
    targetPort: 6739
    appProtocol: tcp
  - name: some-port
    port: 16739
    targetPort: target-port-from-container # name of the inbound
    appProtocol: tcp
status:
  addresses:
  - hostname: redis.mesh
    origin: HostnameGenerator
    hostnameGeneratorRef:
      name: kmy-hostname-generator
  vips:
  - ip: 10.0.1.1 # kuma VIP or Kubernetes cluster IP
```
{% endpolicy_yaml %}

The MeshService represents a destination for traffic from elsewhere in the mesh.
It defines which `Dataplane` objects serve this traffic as well as what ports
are available. It also holds information about which IPs and hostnames can be used
to reach this destination.

## Zone types

How users interact with `MeshServices` will depend on the type of zone.

### Kubernetes

On Kubernetes, `Service` already provides a number of the features provided by
MeshService. For this reason, Kuma generates `MeshServices` from `Services` and:

- reuses VIPs in the form of cluster IPs
- uses Kubernetes DNS names

In the vast majority of cases, Kubernetes users do not create `MeshServices`.

### Universal

In universal zones, `MeshServices` need to be created manually for now. A
strategy of
automatically generating `MeshService` objects from `Dataplanes` is planned for
the future.

## Hostnames

Because of various shortcomings, the existing `VirtualOutbound` does not work
with `MeshService` and is planned for phasing out. A [new `HostnameGenerator`
resource was introduced to manage hostnames for
`MeshServices`](/docs/{{ page.version }}/policies/hostnamegenerator/).

## Ports

The `ports` field lists the ports exposed by the `Dataplanes` that
the `MeshService` matches. `targetPort` can refer to a port directly or by the
name of the `Dataplane` port.

```
  ports:
  - name: redis-non-tls
    port: 16739
    targetPort: 6739
    appProtocol: tcp
```
