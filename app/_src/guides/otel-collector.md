---
title: Deploy an OpenTelemetry collector for metrics, traces, and logs
description: Run one OpenTelemetry collector that receives metrics, traces, and access logs from Kuma, with guidance on Deployment vs DaemonSet topologies and passthrough handling.
keywords:
  - OpenTelemetry
  - observability
  - collector
---

{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}

This guide deploys a single OpenTelemetry collector that receives all three telemetry signals from {{site.mesh_product_name}}: metrics from [MeshMetric](/docs/{{ page.release }}/policies/meshmetric), traces from [MeshTrace](/docs/{{ page.release }}/policies/meshtrace), and access logs from [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog). It covers two production topologies, how the collector fits with sidecar injection, and what changes when mesh passthrough is off.

For a metrics-only example that wires Prometheus and Grafana to the collector, see [Collect metrics with OpenTelemetry](/docs/{{ page.release }}/guides/otel-metrics).

## Prerequisites

- A running zone control plane with the demo app from [Quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/)
- The [observability stack](/docs/{{ page.release }}/guides/otel-metrics/#install-kuma-observability-stack) installed (`kumactl install observability`), or your own Prometheus, Tempo or Jaeger, and Loki backends ready to receive OTLP

## How Kuma talks to the collector

Sidecars push telemetry to the collector over OTLP gRPC on port 4317. The collector receives, batches, and exports it to whatever backends you configure.

This is a push model. Each sidecar opens an outbound connection to one collector pod and writes its own telemetry. Compare that to a pull model, where a collector scrapes Prometheus endpoints from every workload it can reach.

The distinction matters when you pick a topology. A [CNCF post](https://www.cncf.io/blog/2025/12/16/how-to-build-a-cost-effective-observability-platform-with-opentelemetry/) warns about 20-40x metric explosion when DaemonSet collectors all scrape the same Prometheus targets. That problem is specific to the pull model. Kuma pushes, so each metric reaches one collector instance regardless of how many collector pods exist.

## Pick a topology

Two patterns work for the OTLP receiver. Pick one before you write the manifests.

### Deployment + ClusterIP service

Run two or three collector replicas behind a `ClusterIP` service. Sidecars resolve `otel-collector.observability:4317` to whichever replica kube-proxy picks.

This is the default recommendation. It's simple, the failure domain is the whole replica set, and a rolling update of the collector doesn't drop telemetry from any specific node.

Use this for small and medium clusters, or any cluster where collector throughput isn't a bottleneck.

### Per-node `DaemonSet`

Run one collector pod per node and route traffic node-locally. With `internalTrafficPolicy: Local` on the service, kube-proxy sends each sidecar to the collector pod on the same node. Sidecars still resolve the same DNS name (`otel-collector.observability:4317`), but the hop never leaves the node.

Pick this for large clusters or workloads where the extra network hop matters. It improves locality, distributes load across nodes, and isolates collector failure to a single node's telemetry.

The tradeoff is silent loss. If the collector pod on a node crashes or is being rescheduled, sidecars on that node have no fallback. Their telemetry drops on the floor until the pod is back. There is no cross-node failover with `Local` traffic policy.

## Deploy the collector

Both topologies share the same collector configuration. Only the workload kind and the service traffic policy change.

### Create the namespace

The collector lives outside the mesh. Use a dedicated namespace and exclude it from sidecar injection. If you put the collector in a mesh namespace and the sidecar tried to push its own telemetry through itself, you get a circular dependency.

```sh
kubectl create namespace observability
kubectl label namespace observability kuma.io/sidecar-injection=disabled
```

### Collector configuration

Save this as `otel-collector-config.yaml`. It defines three pipelines, a memory limiter as the first processor, a tuned batch processor, and a debug exporter you can switch on when something looks wrong.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: observability
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      memory_limiter:
        check_interval: 5s
        limit_mib: 500
        spike_limit_mib: 400
      batch:
        send_batch_size: 4096
        send_batch_max_size: 8192
        timeout: 10s

    exporters:
      debug:
        verbosity: basic
      otlp_grpc/tempo:
        endpoint: tempo.observability:4317
        tls:
          insecure: true
      prometheus:
        endpoint: 0.0.0.0:8889
      otlp_http/loki:
        endpoint: http://loki.observability:3100/otlp

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp_grpc/tempo, debug]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [prometheus, debug]
        logs:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp_http/loki, debug]
```

A few things worth flagging:

- `memory_limiter` runs first. The OpenTelemetry project recommends this so the collector can shed load before later processors allocate. If batching ran first, a burst could OOM the pod before the limiter ever saw it.
- `batch` reduces export overhead. `send_batch_size: 4096` is a reasonable starting point. Tune up if your backend complains about request rate, down if it complains about batch size.
- The `debug` exporter is sitting in every pipeline at `verbosity: basic`. It logs one line per batch. Bump to `detailed` and reload the config when you need to see individual records.
- Swap `otlp_grpc/tempo`, `prometheus`, and `otlp_http/loki` for whatever your backends are. A single OTLP-compatible backend can replace all three.

### Deployment manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: observability
spec:
  replicas: 2
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
        - name: otel-collector
          image: otel/opentelemetry-collector-contrib:latest
          args: ["--config=/conf/config.yaml"]
          ports:
            - name: otlp-grpc
              containerPort: 4317
            - name: otlp-http
              containerPort: 4318
            - name: prometheus
              containerPort: 8889
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          volumeMounts:
            - name: config
              mountPath: /conf
      volumes:
        - name: config
          configMap:
            name: otel-collector-config
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: observability
spec:
  selector:
    app: otel-collector
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: otlp-grpc
      appProtocol: grpc
    - name: otlp-http
      port: 4318
      targetPort: otlp-http
    - name: prometheus
      port: 8889
      targetPort: prometheus
```

### Manifest for `DaemonSet`

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: otel-collector
  namespace: observability
spec:
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
        - name: otel-collector
          image: otel/opentelemetry-collector-contrib:latest
          args: ["--config=/conf/config.yaml"]
          ports:
            - name: otlp-grpc
              containerPort: 4317
            - name: otlp-http
              containerPort: 4318
            - name: prometheus
              containerPort: 8889
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          volumeMounts:
            - name: config
              mountPath: /conf
      volumes:
        - name: config
          configMap:
            name: otel-collector-config
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: observability
spec:
  selector:
    app: otel-collector
  internalTrafficPolicy: Local
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: otlp-grpc
      appProtocol: grpc
    - name: otlp-http
      port: 4318
      targetPort: otlp-http
    - name: prometheus
      port: 8889
      targetPort: prometheus
```

The DNS name `otel-collector.observability:4317` works the same way in both options. With `internalTrafficPolicy: Local`, kube-proxy resolves it to the node-local pod transparently.

Apply the `ConfigMap` and the manifest you picked:

```sh
kubectl apply -f otel-collector-config.yaml
kubectl apply -f otel-collector-<deployment-or-daemonset>.yaml
kubectl wait -n observability --for=condition=ready pod -l app=otel-collector --timeout=120s
```

## Point Kuma policies at the collector

All three policies use the same endpoint. Apply them at the `Mesh` level to cover every sidecar in the mesh:

```sh
echo '
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: {{ kuma-system }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.observability:4317
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: all-traces
  namespace: {{ kuma-system }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          endpoint: otel-collector.observability:4317
    sampling:
      overall: 100
---
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: all-access-logs
  namespace: {{ kuma-system }}
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  rules:
    - default:
        backends:
          - type: OpenTelemetry
            openTelemetry:
              endpoint: otel-collector.observability:4317
' | kubectl apply -f -
```

Sampling for traces is set to 100% here so you see something during testing. Drop it to single digits in production.

## Reach the collector when passthrough is off

By default, sidecars can reach addresses outside the mesh through [passthrough mode](/docs/{{ page.release }}/networking/non-mesh-traffic). The collector lives outside the mesh, so passthrough is what gets sidecar telemetry to it.

If you disable passthrough at the `Mesh` level, sidecars can't reach the collector anymore and telemetry stops. To restore that path, declare the collector with a [MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice).

`MeshExternalService` requires [ZoneEgress](/docs/{{ page.release }}/production/cp-deployment/zoneegress) and [mutual TLS](/docs/{{ page.release }}/policies/mutual-tls) on the mesh. If you already disabled passthrough, you likely have mTLS on already.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: otel-collector
  namespace: {{ kuma-system }}
  labels:
    kuma.io/mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4317
    protocol: grpc
  endpoints:
    - address: otel-collector.observability
      port: 4317
```

The hostname generator publishes the service under `otel-collector.extsvc.mesh.local`. Update the three policies to point at that hostname on port 4317 instead of `otel-collector.observability:4317`.

## Verify

Check that the collector is receiving data:

```sh
kubectl logs -n observability -l app=otel-collector --tail=20
```

With the `debug` exporter at `verbosity: basic`, each batch shows up as one line per signal. If you see nothing, walk back: is the policy applied to the right `Mesh`, does the collector pod's address match the policy `endpoint`, can a debug pod in a mesh namespace reach `otel-collector.observability:4317` on TCP?

For the DaemonSet topology, also confirm that traffic is going node-local. A sidecar's connections should resolve to the collector pod on its own node:

```sh
kubectl get pod -n observability -o wide -l app=otel-collector
kubectl get endpointslice -n observability -l kubernetes.io/service-name=otel-collector -o yaml
```

The endpoint slice will list one collector pod per node. With `Local` traffic policy, each node's kube-proxy only routes to its own entry.

## Next steps

- Read the [MeshMetric](/docs/{{ page.release }}/policies/meshmetric), [MeshTrace](/docs/{{ page.release }}/policies/meshtrace), and [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog) policy references for filtering, sampling, and per-route configuration
- Wire the collector to your backend of choice (Tempo, Jaeger, Prometheus, Loki, or a SaaS) by editing the `exporters` section
- Browse the [OpenTelemetry collector processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor) for tail sampling, filtering, and attribute transformation
