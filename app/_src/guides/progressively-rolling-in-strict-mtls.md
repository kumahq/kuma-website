---
title: Progressively rolling in strict mTLS
description: Use MeshTLS policy to gradually migrate services to mutual TLS without dropping traffic.
keywords:
  - MeshTLS
  - mTLS
  - permissive mode
---

The [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy allows you to gradually migrate services to mutual TLS without dropping a packet.

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application.
- [`jq`](https://jqlang.github.io/jq/) - a command-line JSON processor

## Basic setup

In order to be able to fully utilize MeshTLS policy you need to enable [Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls/) (mTLS), and you can do it with `builtin` CA backend by executing:

```shell
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

To make sure that traffic works in our examples let's configure MeshTrafficPermission to allow all traffic:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-system
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
curl -s https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml | 
  sed "s#kuma.io/sidecar-injection: enabled#kuma.io/sidecar-injection: disabled#" |
  sed "s#name: kuma-demo#name: kuma-demo-migration#" |
  sed "s#redis.kuma-demo.svc.cluster.local#redis.kuma-demo-migration.svc.cluster.local#" |
  sed "s#namespace: kuma-demo#namespace: kuma-demo-migration#" | kubectl apply -f -
```

Below diagram shows which applications are inside the mesh and which are not.
Purple links indicate that the communication is encrypted, gray ones are plaintext.

{% mermaid %}
---
title: service graph of the second demo app
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            redis(redis :6379)
            demo-app --> redis
        end
    end
    subgraph non-meshed
        subgraph kuma-demo-migration
            direction LR
            redis2(redis :6379)
            demo-app2(demo-app :5000)
            demo-app2 --> redis2
        end
    end
    linkStyle 0 stroke:#d25585, stroke-width:2px;
    linkStyle 1 stroke:#555a5d, stroke-width:2px;
{% endmermaid %}

### Enable port forwarding for both demo-apps

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5001:5000
```

And in separate terminal window

```sh
kubectl port-forward svc/demo-app -n kuma-demo-migration 5002:5000
```

Open up both apps' GUI and turn on auto incrementing.

### Enable permissive mode on redis

We begin with preparing redis to start in [permissive](/docs/{{ page.release }}/policies/meshtls/#configuration) mode when deployed inside the mesh.
To enable permissive mode we define this `MeshTLS` policy:

{% if_version lte:2.9.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: redis
  namespace: kuma-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: redis
  from:
  - targetRef:
      kind: Mesh
    default:
      mode: Permissive" | kubectl apply -f -
```
{% endif_version %}

{% if_version gte:2.10.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: redis
  namespace: kuma-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: redis
  from:
  - targetRef:
      kind: Mesh
    default:
      mode: Permissive" | kubectl apply -f -
```
{% endif_version %}

### Migrate redis to mesh

Then we bring redis into the mesh by adding [kuma.io/sidecar-injection=true](/docs/{{ page.release }}/reference/kubernetes-annotations/#kumaiosidecar-injection) label:

```sh
kubectl patch deployment redis -n kuma-demo-migration \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/metadata/labels/kuma.io~1sidecar-injection", "value": "enabled"}]'
```

After this redis will be receiving plaintext traffic from non-meshed client.
You can check the `stats` for redis data plane:

```sh
export REDIS_DPP_NAME=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=redis | jq -r '.items[0].name')
curl -s http://localhost:5681/meshes/default/dataplanes/$REDIS_DPP_NAME/stats | grep cluster.localhost_6379.upstream_cx_total
```

You should see metrics increment after running this `curl` command multiple times. Metrics will look like:

```
cluster.localhost_6379.upstream_cx_total: 9362
```

The below diagram shows that the second redis was moved to be inside the mesh:

{% mermaid %}
---
title: service graph when redis is inside the mesh
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            redis(redis :6379)
            demo-app --> redis
        end
        
        subgraph kuma-demo-migration 
            direction LR
            redis2(redis :6379)
        end
    end
    subgraph non-meshed
        subgraph kuma-demo-migration
            direction LR
            demo-app2(demo-app :5000)
            demo-app2 --> redis2
        end
    end
    linkStyle 0 stroke:#d25585, stroke-width:2px;
    linkStyle 1 stroke:#555a5d, stroke-width:2px;
{% endmermaid %}

### Migrate client to mesh

Next we do the same to the client so the traffic is encrypted:

```sh
kubectl patch deployment demo-app -n kuma-demo-migration \
--type='json' \
-p='[{"op": "add", "path": "/spec/template/metadata/labels/kuma.io~1sidecar-injection", "value": "enabled"}]'
```

After this is done, you'll have to re-enable the port-forward, and then you can go to the {{site.mesh_product_name}} GUI, check the `Stats` tab for the `redis` Dataplane in the `kuma-demo-migration` namespace, and you should see this metric increment:

<center>
<img src="/assets/images/guides/meshtls/dp-stats-view2.png" alt="Data Plane Proxies Stats metric for inbound_POD_IP_6379.rbac.allowed"/>
</center>

```yaml
inbound_POD_IP_6379.rbac.allowed
```

The below diagram shows that all services are now in the mesh:

{% mermaid %}
---
title: service graph when both client and redis are inside the mesh
---
flowchart LR
    subgraph meshed
        subgraph kuma-demo
            direction LR
            demo-app(demo-app :5000)
            redis(redis :6379)
            demo-app --> redis
        end
        subgraph kuma-demo-migration
            direction LR
            demo-app2(demo-app :5000)
            redis2(redis :6379)
            demo-app2 --> redis2
        end
    end
    linkStyle 0,1 stroke:#d25585, stroke-width:2px;
{% endmermaid %}

### Set strict mode on redis

Finally, to set strict mode you can either edit the policy or remove it (the default is taken from `Mesh` object which is `STRICT`).

{% tip %}
**Things to remember when migrating to strict TLS**

If only encrypted traffic is sent to the destination, the difference between `cluster.localhost_6379.upstream_cx_total` and `inbound_10_42_0_13_6379.rbac.allowed` will not change after setting the workload to `Strict` mode.
{% endtip %}

```sh
kubectl delete meshtlses.kuma.io -n kuma-demo-migration redis
```

## Next steps

With a couple of easy steps we were able to gradually bring a service into the mesh without dropping a packet and encrypting the traffic whenever it's possible.

Read more about [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy.
