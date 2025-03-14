---
title: Progressively rolling in strict mTLS
---

The [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy allows you to gradually migrate services to mutual TLS without dropping a packet.

## Prerequisites
- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application.

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

```shell
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

```bash
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

```bash
kubectl port-forward svc/demo-app -n kuma-demo 5001:5000
```

And in separate terminal window

```bash
kubectl port-forward svc/demo-app -n kuma-demo-migration 5002:5000
```

Open up both apps' GUI and turn on auto incrementing.

### Enable permissive mode on redis

We begin with preparing redis to start in [permissive](/docs/{{ page.release }}/policies/meshtls/#configuration) mode when deployed inside the mesh.
To enable permissive mode we define this `MeshTLS` policy:

{% if_version lte:2.9.x %}
```bash
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
```bash
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

```bash
kubectl patch deployment redis -n kuma-demo-migration \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/metadata/labels/kuma.io~1sidecar-injection", "value": "enabled"}]'
```

After this redis will be receiving plaintext traffic from non-meshed client.
You can check the `stats` for redis data plane:

```bash
export REDIS_DPP_NAME=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=redis | jq -r '.items[0].name')
curl -s http://localhost:5681/meshes/default/dataplanes/$REDIS_DPP_NAME/stats | grep cluster.localhost_6379.upstream_cx
```

You should see metrics increment after running this `curl` command multiple times. Metrics will look like:

```
cluster.localhost_6379.upstream_cx_active: 0
cluster.localhost_6379.upstream_cx_close_notify: 0
cluster.localhost_6379.upstream_cx_connect_attempts_exceeded: 0
cluster.localhost_6379.upstream_cx_connect_fail: 0
cluster.localhost_6379.upstream_cx_connect_timeout: 0
cluster.localhost_6379.upstream_cx_connect_with_0_rtt: 0
cluster.localhost_6379.upstream_cx_destroy: 2547
cluster.localhost_6379.upstream_cx_destroy_local: 2547
cluster.localhost_6379.upstream_cx_destroy_local_with_active_rq: 2547
cluster.localhost_6379.upstream_cx_destroy_remote: 0
cluster.localhost_6379.upstream_cx_destroy_remote_with_active_rq: 0
cluster.localhost_6379.upstream_cx_destroy_with_active_rq: 2547
cluster.localhost_6379.upstream_cx_http1_total: 0
cluster.localhost_6379.upstream_cx_http2_total: 0
cluster.localhost_6379.upstream_cx_http3_total: 0
cluster.localhost_6379.upstream_cx_idle_timeout: 0
cluster.localhost_6379.upstream_cx_max_duration_reached: 0
cluster.localhost_6379.upstream_cx_max_requests: 0
cluster.localhost_6379.upstream_cx_none_healthy: 0
cluster.localhost_6379.upstream_cx_overflow: 0
cluster.localhost_6379.upstream_cx_pool_overflow: 0
cluster.localhost_6379.upstream_cx_protocol_error: 0
cluster.localhost_6379.upstream_cx_rx_bytes_buffered: 0
cluster.localhost_6379.upstream_cx_rx_bytes_total: 14364324
cluster.localhost_6379.upstream_cx_total: 2547
cluster.localhost_6379.upstream_cx_tx_bytes_buffered: 0
cluster.localhost_6379.upstream_cx_tx_bytes_total: 198665
cluster.localhost_6379.upstream_cx_connect_ms: P0(0,0) P25(0,0) P50(0,0) P75(0,0) P90(0,0) P95(0,0) P99(0,0) P99.5(0,0) P99.9(8.052999999999997,1.0681749999999965) P100(8.1,8.1)
cluster.localhost_6379.upstream_cx_length_ms: P0(1,1) P25(1.0311007957559681,1.0438948995363215) P50(1.0622015915119363,1.087789799072643) P75(1.0933023872679044,2.0551816958277254) P90(2.0536904761904764,3.006666666666667) P95(2.081607142857143,4.007457627118645) P99(3.0662000000000003,7.082000000000005) P99.5(5.0654999999999974,12.319999999999936) P99.9(19.531000000000006,21.728000000000065) P100(20,51)
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

```bash
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

```bash
kubectl delete meshtlses.kuma.io -n kuma-demo-migration redis
```

## Next steps

With a couple of easy steps we were able to gradually bring a service into the mesh without dropping a packet and encrypting the traffic whenever it's possible.

Read more about [MeshTLS](/docs/{{ page.release }}/policies/meshtls/) policy.
