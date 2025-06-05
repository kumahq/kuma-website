---
title: Progressively rolling in strict mTLS
---

{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

The [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy allows you to gradually migrate services to mutual TLS without dropping a packet.

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application.
- [`jq`](https://jqlang.github.io/jq/) - a command-line JSON processor

{% tip %}
If you are already familiar with quickstart you can set up required environment by running:

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ site.mesh_namespace }} \{% if version == "preview" %}
  --version {{ page.version }} \{% endif %}
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
kubectl wait -n {{ kuma-system }} --for=condition=ready pod --selector=app={{ kuma-control-plane }} --timeout=90s
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% endtip %}


## Basic setup

To make sure that traffic works in our examples let's configure MeshTrafficPermission to allow all traffic:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{ kuma-system }}
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

## Gradually bring another service into the mesh

### Start a second demo app

First we start a new demo setup in another namespace called `kuma-demo-migration`.
The below command installs the demo one more time in another namespace:

```sh
kubectl apply -f kuma-demo://k8s/003-migration-demo.yaml
```

Below diagram shows which applications are inside the mesh and which are not.
Purple links indicate that the communication is encrypted, gray ones are plaintext.

<!-- vale Google.Headings = NO -->
{% mermaid %}
---
title: service graph of the second demo app
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            kv(kv :6379)
            demo-app --> kv
        end
    end
    subgraph non-meshed
        subgraph kuma-demo-migration
            direction LR
            kv2(kv :6379)
            demo-app2(demo-app :5000)
            demo-app2 --> kv2
        end
    end
    linkStyle 0 stroke:#d25585, stroke-width:2px;
    linkStyle 1 stroke:#555a5d, stroke-width:2px;
{% endmermaid %}
<!-- vale Google.Headings = YES -->

### Enable port forwarding for both demo-apps

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5051:5050
```

And in separate terminal window

```sh
kubectl port-forward svc/demo-app -n kuma-demo-migration 5052:5050
```

Open up both apps' GUI and turn on auto incrementing.

### Enable permissive mode on kv

We begin with preparing kv to start in [permissive](/docs/{{ page.release }}/policies/meshtls/#configuration) mode when deployed inside the mesh.
To enable permissive mode we define this `MeshTLS` policy:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kv
  namespace: kuma-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  from:
  - targetRef:
      kind: Mesh
    default:
      mode: Permissive" | kubectl apply -f -
```


### Migrate kv to mesh

We need to start by labeling `kuma-demo-migration` namespace with `kuma.io/sidecar-injection=true` label:

```sh
kubectl label namespace kuma-demo-migration kuma.io/sidecar-injection=enabled --overwrite
```

Then we need to restart the kv deployment

```sh
kubectl rollout restart deployment kv -n kuma-demo-migration
```

After this kv will be receiving plaintext traffic from non-meshed client.
You can check the `stats` for kv data plane:

```sh
export KV_DPP_NAME=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=kv | jq -r '.items[0].name')
curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME/stats | grep cluster.localhost_5050.upstream_cx_total
```

{% warning %}
Make sure you have port forwarding enabled for control plane for this to work:
```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```
{% endwarning %}


You should see metrics increment after running this `curl` command multiple times. Metrics will look like:

```
cluster.localhost_5050.upstream_cx_total: 9
```

The below diagram shows that the second kv was moved to be inside the mesh:

<!-- vale Google.Headings = NO -->
{% mermaid %}
---
title: service graph when kv is inside the mesh
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            kv(kv :6379)
            demo-app --> kv
        end
        
        subgraph kuma-demo-migration 
            direction LR
            kv2(kv :6379)
        end
    end
    subgraph non-meshed
        subgraph kuma-demo-migration
            direction LR
            demo-app2(demo-app :5000)
            demo-app2 --> kv2
        end
    end
    linkStyle 0 stroke:#d25585, stroke-width:2px;
    linkStyle 1 stroke:#555a5d, stroke-width:2px;
{% endmermaid %}
<!-- vale Google.Headings = YES -->

### Migrate client to mesh

Next we do the same to the client so the traffic is encrypted:

```sh
kubectl rollout restart deployment demo-app -n kuma-demo-migration
```

After this is done, you'll have to re-enable the port-forward, and then you can go to the {{site.mesh_product_name}} GUI, check the `Stats` tab for the `kv` Dataplane in the `kuma-demo-migration` namespace, and you should see this metric increment:

<center>
<img src="/assets/images/guides/meshtls/dp-stats-view3.png" alt="Data Plane Proxies Stats metric for inbound_POD_IP_6379.rbac.allowed"/>
</center>

```yaml
inbound_POD_IP_5050.rbac.allowed
```

The below diagram shows that all services are now in the mesh:

<!-- vale Google.Headings = NO -->
{% mermaid %}
---
title: service graph when both client and kv are inside the mesh
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            kv(kv :6379)
            demo-app --> kv
        end
        subgraph kuma-demo-migration
            direction LR
            demo-app2(demo-app :5000)
            kv2(kv :6379)
            demo-app2 --> kv2
        end
    end
    linkStyle 0,1 stroke:#d25585, stroke-width:2px;
{% endmermaid %}
<!-- vale Google.Headings = YES -->

### Set strict mode on kv

Finally, to set strict mode you can either edit the policy or remove it (the default is taken from `Mesh` object which is `STRICT`).

{% tip %}
**Things to remember when migrating to strict TLS**

If only encrypted traffic is sent to the destination, the difference between `cluster.localhost_5050.upstream_cx_total` and `inbound_POD_IP_5050.rbac.allowed` will not change after setting the workload to `Strict` mode.
{% endtip %}

```sh
kubectl delete meshtlses.kuma.io -n kuma-demo-migration kv
```

## Next steps

With a couple of easy steps we were able to gradually bring a service into the mesh without dropping a packet and encrypting the traffic whenever it's possible.

Read more about [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy.
