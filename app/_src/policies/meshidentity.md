---
title: MeshIdentity
description: Define how workloads obtain cryptographic identity with MeshIdentity, supporting SPIFFE IDs and multiple certificate providers.
keywords:
  - workload identity
  - SPIFFE
  - certificate management
---

{% warning %}
This resource is experimental.
It works only on Kubernetes and requires [MeshServices](/docs/{{ page.release }}/networking/meshservice/) to be enabled. 
{% endwarning %}

## Overview

`MeshIdentity` is a resource that defines how workloads in a mesh obtain their cryptographic identity.
It separates the responsibility of issuing identities from establishing trust,
enabling {{site.mesh_product_name}} to adopt [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/) compliant practices
while remaining flexible and easy to use.

With `MeshIdentity`, users can:

* Enable secure mTLS between services, using trusted certificate authorities.
* Switch identity providers without downtime, for example when migrating from built-in certificates to [Spire](https://spiffe.io/docs/latest/spire-about/).
* Assign different identity providers to subsets of workloads, allowing more granular control.

A basic example follows to illustrate the structure:

{% policy_yaml %}
{% raw %}
```yaml
type: MeshIdentity
name: identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true
```
{% endraw %}
{% endpolicy_yaml %}

## Configuration

`MeshIdentity` is a namespaced (system-namespace only) resource that controls how data plane proxies receive identity certificates.
It is composed of a few key fields that control how identities are issued and applied.
In the following sections, each field is explained in detail with examples:

* `Selector` – which data plane proxies this identity applies to.
* `SpiffeID` – how the SPIFFE ID is constructed (trust domain and path).
* `Provider` – which system issues the certificates (`Bundled` or `Spire`).

### Selector

The selector field controls which data plane proxies a `MeshIdentity` applies to.
It uses a Kubernetes-style label selector on data plane proxy tags.
This makes it possible to scope an identity to all workloads, a subset of workloads, or none at all.

When multiple `MeshIdentity` resources apply to the same data plane proxy,
the one with the most specific selector (the greatest number of matching labels) takes precedence.
If two policies have selectors with the same number of labels, {{site.mesh_product_name}} compares their names lexicographically. 
The policy whose name comes first in alphabetical order takes precedence (for example, `aaa` is chosen over `bbb`).

#### Examples

##### Apply to all data plane proxies

```yaml
spec:
  selector:
    dataplane:
      matchLabels: {}
```

##### Apply to a group of data plane proxies

```yaml
spec:
  selector:
    dataplane:
      matchLabels:
        app: my-app
```

##### Apply to nothing

```yaml
spec:
  selector: {}
```

### SpiffeID

The `spiffeID` field lets you override how SPIFFE IDs are constructed for the data plane proxies selected by this `MeshIdentity`.
By default, {{site.mesh_product_name}} generates a SPIFFE ID based on the mesh and zone.
With `spiffeID`, you can customize the `trustDomain` and the `path` template.

{% raw %}
```yaml
spec:
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
```
{% endraw %}

Supported variables in `trustDomain` field are:
* `.Mesh`
* `.Zone`

Supported variables in `path` field are:
* `.Namespace`
* `.ServiceAccount`

Also, both in `trustDomain` and `path` it's possible to use resource's `labels`, i.e.:

{% raw %}
```yaml
spec:
  spiffeID:
    trustDomain: '{{ label "kuma.io/mesh" }}.{{ label "kuma.io/zone" }}.mesh.local'
    path: '/ns/{{ label "k8s.kuma.io/namespace" }}/sa/{{ label "k8s.kuma.io/service-account" }}'
```
{% endraw %}

{% if_version gte:2.13.x %}

#### Workload label requirement

When using `{{ label "kuma.io/workload" }}` in the `path` template, data plane proxies selected by this `MeshIdentity` must have the `kuma.io/workload` label. This label can be provided either:

* Via a [data plane proxy token](/docs/{{ page.release }}/production/secure-deployment/dp-auth/#workload-label-in-tokens) generated with the `--workload` parameter
* Directly on the data plane proxy resource

Connections from data plane proxies lacking the required label will be rejected.

Example using workload label in path:

{% raw %}
```yaml
spec:
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/workload/{{ label \"kuma.io/workload\" }}"
```
{% endraw %}

This validation applies to Kubernetes and Universal deployments and is enforced at connection time.

{% endif_version %}

### Provider

The `provider` field defines how identity certificates are issued.
This field is required and must specify one of the supported provider types:

* `Bundled` – certificates are issued by {{site.mesh_product_name}}’s control plane, either autogenerated or supplied by the user.
* `Spire` – certificates are issued directly by a SPIRE Agent through SDS.

## Examples

### Minimal `Bundled` MeshIdentity

{% policy_yaml %}
{% raw %}
```yaml
type: MeshIdentity
name: identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {} # apply to all data plane proxies in the mesh
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Disabled # do not automatically create a MeshTrust from this identity
      insecureAllowSelfSigned: true # explicitly allow use of a self-signed CA
      autogenerate:
        enabled: true # let the control plane autogenerate a CA and store it
```
{% endraw %}
{% endpolicy_yaml %}

### MeshIdentity with CA provided by user

{% policy_yaml %}
{% raw %}
```yaml
type: MeshIdentity
name: identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels:
        app: my-app # apply to all data plane proxies with label `app: my-app`
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled # automatically create a MeshTrust from this identity
      insecureAllowSelfSigned: true # explicitly allow use of a self-signed CA
    ca:
      certificate: # SecureDataSource that'll be resolved by the Control Plane
        type: File
        file:
          path: /ca.crt # path should be reachable by the Control Plane
      privateKey: # SecureDataSource that'll be resolved by the Control Plane
        type: File
        file:
          path: /ca.key # path should be reachable by the Control Plane
```
{% endraw %}
{% endpolicy_yaml %}

### MeshIdentity with `Spire` provider

To enable `Spire` socket injection, you can either:
* turn it on globally by setting [`KUMA_RUNTIME_KUBERNETES_INJECTOR_SPIRE_ENABLED`](https://kuma.io/docs/dev/reference/kuma-cp/#kuma-cp-configuration) environment variable on the control plane, or
* enable it per pod by adding the `k8s.kuma.io/spire-support` label.

{% policy_yaml %}
{% raw %}
```yaml
type: MeshIdentity
name: identity-spire
mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: default.us-east.mesh.local
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
  provider:
    type: Spire
    spire: {}
```
{% endraw %}
{% endpolicy_yaml %}

## See also

* [MeshTrust](/docs/{{ page.release }}/policies/meshtrust) - Configure trust between different domains
* [MeshTLS](/docs/{{ page.release }}/policies/meshtls) - Configure TLS modes and ciphers
* [MeshTrafficPermission (experimental)](/docs/{{ page.release }}/policies/meshtrafficpermission_experimental) - Control traffic access with SPIFFE

