---
title: Progressively rolling in strict mTLS
---

The [MeshTLS](/docs/{{ page.version }}/policies/meshtls/) policy allows you to gradually migrate services to mutual TLS without dropping a packet.

## Prerequisites
- Completed [quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

## Gradually bring another service into the mesh

### Start a second demo app

First we start a new demo setup in another namespace called `kuma-demo-migration`.
The below command installs the demo one more time in another namespace:

```bash
curl -s https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml | 
  sed "s#kuma.io/sidecar-injection: enabled#kuma.io/sidecar-injection: disabled#" |
  sed "s#name: kuma-demo#name: kuma-demo-migration#" |
  sed "s#redis.kuma-demo.svc.cluster.local#redis.kuma-demo-migration.svc.cluster.local#" |
  sed "s#namespace: kuma-demo#namespace: kuma-demo-migration#" | kubectl apply -f -
```

Below diagram shows which applications are inside the mesh and which are not:

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
{% endmermaid %}

### Enable port forwarding for both second app

```bash
kubectl port-forward svc/demo-app -n kuma-demo-migration 5001:5000
```

Open up both apps' GUI and turn on auto incrementing.

### Enable permissive mode on redis

We begin with preparing redis to start in [permissive](/docs/{{ page.version }}/policies/meshtls/#configuration) mode when deployed inside the mesh.
To enable permissive mode we define this `MeshTLS` policy:

```yaml
apiVersion: kuma.io/v1alpha1
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
      mode: Permissive
```

### Migrate redis to mesh

Then we bring redis into the mesh by adding [kuma.io/sidecar-injection=true](/docs/{{ page.version }}/reference/kubernetes-annotations/#kumaiosidecar-injection) label:

```bash
kubectl patch deployment redis -n kuma-demo-migration \
--type='json' \
-p='[{"op": "add", "path": "/spec/template/metadata/labels/kuma.io~1sidecar-injection", "value": "enabled"}]'
```

After this redis will be receiving plaintext traffic from non-meshed client.
You can go to {{site.mesh_product_name}} GUI (port 5681) and you should see this metric increment on `redis` in `kuma-demo-migration` namespace:

```yaml
cluster.localhost_6379.upstream_cx_total
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
{% endmermaid %}

### Migrate client to mesh

Next we do the same to the client so the traffic is encrypted:

```bash
kubectl patch deployment demo-app -n kuma-demo-migration \
--type='json' \
-p='[{"op": "add", "path": "/spec/template/metadata/labels/kuma.io~1sidecar-injection", "value": "enabled"}]'
```

After this is done, you'll have to re-enable the port-forward, and then you can go to {{site.mesh_product_name}} GUI (port 5681) and you should see this metric increment on `redis` in `kuma-demo-migration` namespace:

```yaml
inbound_POD_IP_6379.rbac.allowed: 809
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
{% endmermaid %}

### Set strict mode on redis

Finally, to set strict mode you can either edit the policy or remove it (the default is taken from `Mesh` object which is `STRICT`).

```bash
kubectl delete meshtlses.kuma.io -n kuma-system redis
```

## Things to remember when migrating to strict TLS

* Before changing a workload to `Strict` mode check that `tls_inspector.tls_not_found` stat is no longer incrementing.

## Next steps

With a couple of easy steps we were able to gradually bring a service into the mesh without dropping a packet and encrypting the traffic whenever it's possible.

Read more about [MeshTLS](/docs/{{ page.version }}/policies/meshtls/) policy.
