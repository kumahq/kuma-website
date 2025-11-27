---
title: Mesh
description: Reference for the Mesh resource, the root resource that defines service mesh instances with mTLS, networking, routing, and observability configuration.
keywords:
  - Mesh
  - multi-tenancy
  - mTLS
content_type: reference
category: resource
---

The `Mesh` resource defines a service mesh instance. It is the parent resource of all other {{site.mesh_product_name}} resources, including [data plane proxies](/docs/{{ page.release }}/production/dp-config/dpp/) and [policies](/docs/{{ page.release }}/policies/).

Create multiple meshes to isolate services by team, environment, or security requirements. Each data plane proxy belongs to exactly one mesh.

{{site.mesh_product_name}} creates a `default` mesh automatically on startup. Disable this by setting `KUMA_DEFAULTS_SKIP_MESH_CREATION=true`.

## Spec fields

| Field | Description |
|-------|-------------|
| `mtls` | mTLS configuration with CA backends. See [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/). |
| `networking.outbound.passthrough` | Allow traffic to unknown destinations. Default: `true`. See [Non-mesh traffic](/docs/{{ page.release }}/networking/non-mesh-traffic/). |
| `routing.zoneEgress` | Route cross-zone/external traffic through ZoneEgress. See [Zone Egress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/). |
| `routing.localityAwareLoadBalancing` | Prefer endpoints in same zone. See [MeshLoadBalancingStrategy](/docs/{{ page.release }}/policies/meshloadbalancingstrategy/). |
| `routing.defaultForbidMeshExternalServiceAccess` | Block MeshExternalService traffic by default. |
| `constraints.dataplaneProxy` | Control which proxies can join mesh. See [DP membership](/docs/{{ page.release }}/production/secure-deployment/dp-membership/). |
| `skipCreatingInitialPolicies` | Skip default policy creation. Use `['*']` to skip all. |
| `meshServices.mode` | MeshService generation: `Disabled`, `Everywhere`, `ReachableBackends`, `Exclusive`. See [MeshService](/docs/{{ page.release }}/networking/meshservice/). |

{% warning %}
When mTLS is enabled, all traffic is denied unless [`MeshTrafficPermission`](/docs/{{ page.release }}/policies/meshtrafficpermission/) allows it.
{% endwarning %}

## Examples

### Basic mesh

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
```

{% endtab %}
{% endtabs %}

### Mesh with mTLS enabled (builtin CA)

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        dpCert:
          rotation:
            expiration: 24h
        conf:
          caCert:
            RSAbits: 2048
            expiration: 10y
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      dpCert:
        rotation:
          expiration: 24h
      conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
```

{% endtab %}
{% endtabs %}

### Mesh with mTLS (provided CA)

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: provided
        dpCert:
          rotation:
            expiration: 24h
        conf:
          cert:
            secret: my-ca-cert
          key:
            secret: my-ca-key
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: provided
      dpCert:
        rotation:
          expiration: 24h
      conf:
        cert:
          secret: my-ca-cert
        key:
          secret: my-ca-key
```

{% endtab %}
{% endtabs %}

### Mesh with permissive mTLS mode

Accept both mTLS and plaintext traffic (for migration):

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        mode: PERMISSIVE
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      mode: PERMISSIVE
```

{% endtab %}
{% endtabs %}

{% warning %}
PERMISSIVE mode is not secure. Use only during migration, then switch to STRICT.
{% endwarning %}

### Mesh with ZoneEgress routing

Route cross-zone and external traffic through ZoneEgress:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    zoneEgress: true
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
routing:
  zoneEgress: true
```

{% endtab %}
{% endtabs %}

### Mesh with passthrough disabled

Block traffic to unknown destinations:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  networking:
    outbound:
      passthrough: false
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
networking:
  outbound:
    passthrough: false
```

{% endtab %}
{% endtabs %}

### Mesh without default policies

Skip all default policy creation:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ['*']
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
skipCreatingInitialPolicies: ['*']
```

{% endtab %}
{% endtabs %}

### Mesh with namespace restrictions (Kubernetes)

Allow only pods from specific namespaces:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  constraints:
    dataplaneProxy:
      requirements:
        - tags:
            k8s.kuma.io/namespace: team-a
        - tags:
            k8s.kuma.io/namespace: team-b
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          k8s.kuma.io/namespace: team-a
      - tags:
          k8s.kuma.io/namespace: team-b
```

{% endtab %}
{% endtabs %}

### Mesh with zone segmentation

Restrict mesh to specific zones in multizone deployment:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: production
spec:
  constraints:
    dataplaneProxy:
      requirements:
        - tags:
            kuma.io/zone: us-east
        - tags:
            kuma.io/zone: us-west
      restrictions:
        - tags:
            env: development
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: production
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          kuma.io/zone: us-east
      - tags:
          kuma.io/zone: us-west
    restrictions:
      - tags:
          env: development
```

{% endtab %}
{% endtabs %}

### Mesh with MeshServices enabled

Enable automatic MeshService generation:

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
```

{% endtab %}
{% tab Universal %}

```yaml
type: Mesh
name: default
meshServices:
  mode: Exclusive
```

{% endtab %}
{% endtabs %}

## See also

- [Configuring your Mesh and multi-tenancy](/docs/{{ page.release }}/production/mesh/)
- [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/)
- [Data plane proxy membership](/docs/{{ page.release }}/production/secure-deployment/dp-membership/)
- [Non-mesh traffic](/docs/{{ page.release }}/networking/non-mesh-traffic/)
- [Zone Egress](/docs/{{ page.release }}/production/cp-deployment/zoneegress/)
- [MeshService](/docs/{{ page.release }}/networking/meshservice/)

## All options

{% json_schema Mesh type=proto %}
