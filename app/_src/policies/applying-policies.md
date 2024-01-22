---
title: Applying Policies
---

Once installed, {{site.mesh_product_name}} can be configured via its policies. 
You can apply policies with [`kumactl`](/docs/{{ page.version }}/explore/cli) on Universal, and with `kubectl` on Kubernetes. 
Regardless of what environment you use, you can always read the latest {{site.mesh_product_name}} state with [`kumactl`](/docs/{{ page.version }}/explore/cli) on both environments.

{% tip %}
We follow the best practices. You should always change your Kubernetes state with CRDs, that's why {{site.mesh_product_name}} disables `kumactl apply [..]` when running in K8s environments.
{% endtip %}

{% tabs policy-apply useUrlFragment=false %}
{% tab policy-apply Kubernetes %}

```sh
echo "
  apiVersion: kuma.io/v1alpha1
  kind: ..
  spec: ..
" | kubectl apply -f -
```

{% endtab %}
{% tab policy-apply Universal %}

```sh
echo "
  type: ..
  spec: ..
" | kumactl apply -f -
```

{% endtab %}
{% endtabs %}

In addition to [`kumactl`](/docs/{{ page.version }}/explore/cli), you can also retrieve the state via the {{site.mesh_product_name}} [HTTP API](/docs/{{ page.version }}/reference/http-api) as well.

{% if_version gte:2.6.x %}

## Applying policies on Zone and Global Control Planes

Multi-zone deployment consists of Global Control Plane (Global CP) deployment with one or many Zone Control Planes (Zone CP) connected to it.
Each Zone CP represents a single cluster (i.e. Kubernetes or Universal cluster). 
Policies can be applied on both Global and Zone CPs.

When policy is applied on Global CP:
* it is propagated to all Zone CPs and applied to all matched data plane proxies in all zones
* Global CP is a source of truth for the policy (when Global CP is down it's not possible to create/update policies)

When policy is applied on Zone CP:
* it is applied only to matched data plane proxies in the same zone
* Zone CP is a source of truth for the policy (when Global CP is down it's still possible to create/update zone-originated policies)
* it is synced to Global CP to be visible in the UI and API calls

Applying policy on Zone CP requires setting `kuma.io/origin` label to `zone` (`zone` is a keyword, not a name of the zone):

{% policy_yaml example1 %}
```yaml
type: MeshTimeout
name: timeout-on-zone-cp
mesh: default
labels:
  kuma.io/origin: zone
spec:
  targetRef:
    kind: Mesh
  to:
  - targetRef:
      kind: Mesh
    default:
      idleTimeout: 20s
      connectionTimeout: 2s
      http:
        requestTimeout: 2s
```
{% endpolicy_yaml %}

Validation of the origin label can be disabled by providing `KUMA_MULTIZONE_ZONE_DISABLE_ORIGIN_LABEL_VALIDATION: "true"` environment variable to the Zone CP.

{% endif_version %}

{% if_version gte:1.3.x %}

{% endif_version %}
