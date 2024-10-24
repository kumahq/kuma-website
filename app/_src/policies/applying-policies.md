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

In addition to [`kumactl`](/docs/{{ page.version }}/explore/cli), you can also retrieve the state via the {{site.mesh_product_name}} [HTTP API](/docs/{{ page.version }}/reference/http-api).

{% if_version gte:2.6.x %}

## Applying policies on Zone and Global Control Planes

Multi-zone deployment consists of Global Control Plane (Global CP) deployment with one or many Zone Control Planes (Zone CP) connected to it.
Each Zone CP represents a single cluster (i.e. Kubernetes or Universal cluster). 
Policies can be applied on both Global and Zone CPs.

When policy is applied on Global CP:
* it is propagated to all Zone CPs and applied to all matched data plane proxies in all zones
* Global CP is a source of truth for the policy (when Global CP is down it's not possible to create/update those policies)
* You cannot manage this policy (modify / delete) on Zone CP

When policy is applied on Zone CP:
* it is applied only to matched data plane proxies in the **same zone**
* Zone CP is a source of truth for the policy (when Global CP is down it's still possible to create/update zone-originated policies)
* you cannot manage this policy (modify / delete) on Global CP
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

Validation of the origin label can be disabled by [configuring](/docs/{{ page.version }}/documentation/configuration) a zone CP with `KUMA_MULTIZONE_ZONE_DISABLE_ORIGIN_LABEL_VALIDATION: "true"`.

{% endif_version %}

{% if_version gte:1.3.x %}

{% endif_version %}

{% if_version gte:2.7.x %}

## Applying policies in shadow mode

### Overview

The new shadow mode functionality allows users to mark policies with a specific label to simulate configuration changes
without affecting the live environment. 
It enables the observation of potential impact on Envoy proxy configurations, providing a risk-free method to test, 
validate, and fine-tune settings before actual deployment. 
Ideal for learning, debugging, and migrating, shadow mode ensures configurations are error-free, 
improving the overall system reliability without disrupting ongoing operations.

### Recommended setup

It's not necessary but CLI tools like [jq](https://jqlang.github.io/jq/) and [jd](https://github.com/josephburnett/jd) can greatly improve the UX.

### How to use shadow mode 

1. Before applying the policy, add a `kuma.io/effect: shadow` label.

2. Check the proxy config with shadow policies taken into account through the {{site.mesh_product_name}} API. By using HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true
    ```
    or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow
    ```

3. Check the diff in [JSONPatch](https://jsonpatch.com/) format through the {{site.mesh_product_name}} API. By using HTTP API:
    ```shell
    curl http://localhost:5681/meshes/${mesh}/dataplane/${dataplane}/_config?shadow=true&include=diff
    ```
   or by using `kumactl`:
    ```shell
    kumactl inspect dataplane ${name} --type=config --shadow --include=diff
    ```

### Limitations and Considerations

Currently, the {{site.mesh_product_name}} API mentioned above works only on Zone CP. 
Attempts to use it on Global CP lead to `405 Method Not Allowed`. 
This might change in the future.

### Examples 

Apply policy with `kuma.io/effect: shadow` label:

{% policy_yaml example2 %}
```yaml
type: MeshTimeout
name: frontend-timeouts
mesh: default
labels:
  kuma.io/effect: shadow
spec:
   targetRef:
     kind: MeshSubset
     tags:
        kuma.io/service: frontend
   to:
   - targetRef:
       kind: MeshService
       name: backend
       namespace: kuma-demo
       sectionName: httport
       _port: 3001
     default:
       idleTimeout: 23s
```
{% endpolicy_yaml %}

Check the diff using `kumactl`:

```shell
$ kumactl inspect dataplane frontend-dpp --type=config --include=diff --shadow | jq '.diff' | jd -t patch2jd
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
- "3600s"
@ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","backend_kuma-demo_svc_3001","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
+ "23s"
```

The output not only identifies the exact location in Envoy where the change will occur, but also shows the current timeout value that we're planning to replace.

{% endif_version %}
