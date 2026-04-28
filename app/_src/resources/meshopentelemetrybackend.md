---
title: MeshOpenTelemetryBackend
description: Reference for MeshOpenTelemetryBackend, a shared OpenTelemetry collector configuration that MeshMetric, MeshTrace, and MeshAccessLog can reference instead of duplicating endpoint settings.
keywords:
  - MeshOpenTelemetryBackend
  - OpenTelemetry
  - observability
content_type: reference
category: resource
---

{% if_version gte:2.14.x %}

`MeshOpenTelemetryBackend` defines an OpenTelemetry collector endpoint that observability policies reference through a `backendRef`. Without it, every MeshMetric, MeshTrace, and MeshAccessLog policy carries its own copy of the collector address. With it, the address lives in one place and the policies point at it by name.

Inline `endpoint` fields on those three policies still work in 2.14 but are deprecated and will be removed in 3.0. New deployments should use `backendRef`.

## Migrate from inline `endpoint`

1. Create one `MeshOpenTelemetryBackend` carrying the address that was inline on the policy.
2. On each policy, replace the inline `endpoint` with `backendRef: {kind: MeshOpenTelemetryBackend, name: <backend>}`.
3. Signal-specific fields (`refreshInterval`, `attributes`, `body`, `sampling`) stay on the policy.

To move the collector later, edit the backend - the policies stay untouched.

`MeshOpenTelemetryBackend` must be created in the system namespace (`kuma-system` on Kubernetes). On Universal, it lives in the Global CP store with no namespace concept.

## Single collector for all three signals

The most common shape: one backend resource, three policies pointing at it.

{% tabs %}
{% tab Kubernetes %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: main-collector
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  endpoint:
    address: otel-collector.observability
    port: 4317
  protocol: grpc
---
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: all-metrics
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
          refreshInterval: 30s
---
apiVersion: kuma.io/v1alpha1
kind: MeshTrace
metadata:
  name: all-traces
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
    sampling:
      overall: 80
---
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: all-access-logs
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: main-collector
```

{% endtab %}
{% tab Universal %}

```yaml
type: MeshOpenTelemetryBackend
name: main-collector
mesh: default
spec:
  endpoint:
    address: otel-collector.observability
    port: 4317
  protocol: grpc
```

{% endtab %}
{% endtabs %}

## Node-local collector

If the collector runs as a DaemonSet with `hostPort`, an empty backend is enough. `kuma-dp` resolves `HOST_IP:4317` on Kubernetes (Downward API) and `127.0.0.1:4317` on Universal and VMs.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: node-collector
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
# No spec - defaults apply: protocol grpc, port 4317, address resolved at runtime.
```

If the DaemonSet exposes OTLP/HTTP on a different port, override only the fields that change:

```yaml
spec:
  endpoint:
    port: 4318
    path: /otlp
  protocol: http
```

## Reuse OpenTelemetry environment variables from the sidecar

Many setups already inject standard `OTEL_EXPORTER_OTLP_*` environment variables into the sidecar (OpenTelemetry Operator on Kubernetes, systemd unit on Universal, container runtime, wrapper script). The default `env` policy is `mode: Optional` plus `precedence: EnvFirst` plus `allowSignalOverrides: true`, so an empty backend reuses those values. With per-signal variables, traces can target a different collector while logs and metrics share the default.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: from-env
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
# No spec - sidecar environment variables drive the configuration.
# Example sidecar environment:
#   OTEL_EXPORTER_OTLP_ENDPOINT=https://otel-gateway.observability:4318
#   OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
#   OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https://tempo.observability:4318
# Result: traces -> tempo, logs and metrics -> otel-gateway.
```

When environment input must be ignored (regulated backends), set `mode: Disabled`. When the backend is meaningless without environment input (per-tenant headers, mTLS client keys), set `mode: Required` - the signal stays `missing` until the keys are present.

## Spec fields

| Field | Description |
|-------|-------------|
| `endpoint` | Collector address. Optional - omitting `endpoint` is equivalent to omitting all of its sub-fields. When omitted, `kuma-dp` resolves a node-local default at runtime. |
| `endpoint.address` | DNS name or IP address. Optional. Defaults to `HOST_IP` on Kubernetes (Downward API) and `127.0.0.1` elsewhere. |
| `endpoint.port` | Collector port. Optional. Default: `4317`. |
| `endpoint.path` | Base path prefix for OTLP/HTTP. Optional. Rejected when `protocol: grpc`. The control plane appends `/v1/traces`, `/v1/metrics`, `/v1/logs` per signal. |
| `protocol` | `grpc` or `http`. Optional. Default: `grpc`. `http` means OTLP/HTTP with Protobuf encoding. |
| `env` | OpenTelemetry environment-variable policy. Optional. Defaults to `mode: Optional`, `precedence: EnvFirst`, `allowSignalOverrides: true`. |
| `env.mode` | `Disabled`, `Optional`, or `Required`. Default: `Optional`. |
| `env.precedence` | `EnvFirst` (environment variables win, explicit config fills gaps) or `ExplicitFirst` (explicit config wins, environment variables fill gaps). Default: `EnvFirst`. |
| `env.allowSignalOverrides` | boolean. When `true`, per-signal variables may override shared variables per signal. When `false`, per-signal variables are ignored. Default: `true`. |

## Referencing a backend from a policy

Every observability policy that supports OpenTelemetry has a `backendRef` field on its OTel backend block. The reference works the same way as `BackendRef` on MeshHTTPRoute: use `name` to reference a resource in the same cluster, use `labels` to reference a resource synced from another cluster.

| Field | Description |
|-------|-------------|
| `backendRef.kind` | Must be `MeshOpenTelemetryBackend`. |
| `backendRef.name` | `metadata.name` of the backend, for same-cluster references. |
| `backendRef.labels` | Label selector. Required for cross-zone references because [KDS](/docs/{{ page.release }}/production/deployment/multi-zone/) appends a hash suffix to `metadata.name` on synced resources. |

Exactly one of `name` or `labels` must be set. When `labels` matches more than one backend, the oldest by creation time wins.

For cross-zone references, match on `kuma.io/display-name` so the resource resolves regardless of the hashed name added during sync:

```yaml
backendRef:
  kind: MeshOpenTelemetryBackend
  labels:
    kuma.io/display-name: main-collector
```

### Per-zone collectors in multi-zone

When zones run separate collectors, create one backend per zone on the Global CP and scope each policy to the matching zone. Because both the backend and the policy live on Global, the CP resolves `backendRef.name` before KDS sync - the hashed name that appears on zones never matters.

If the policy is created on a zone CP and references a backend synced from Global, use `backendRef.labels` instead - the synced backend's `metadata.name` carries a hash suffix that does not match a plain `name:`.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOpenTelemetryBackend
metadata:
  name: collector-us-east
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  endpoint:
    address: collector.us-east.internal
    port: 4317
---
apiVersion: kuma.io/v1alpha1
kind: MeshMetric
metadata:
  name: metrics-us-east
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/zone: us-east
  default:
    backends:
      - type: OpenTelemetry
        openTelemetry:
          backendRef:
            kind: MeshOpenTelemetryBackend
            name: collector-us-east
          refreshInterval: 30s
```

When all zones can share the same collector service name, one backend on the Global CP is enough - DNS resolves to the local collector in each zone.

## Environment-variable resolution

`kuma-dp` reads `OTEL_EXPORTER_OTLP_*` environment variables locally at startup and merges them with the backend config. Secret-bearing values (headers, client keys, certificates) stay local to `kuma-dp`. During startup, `kuma-dp` reports only which environment variable keys are present to the control plane, never the values.

Recognized variable families:

- shared: `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_EXPORTER_OTLP_HEADERS`, `OTEL_EXPORTER_OTLP_INSECURE`, `OTEL_EXPORTER_OTLP_TIMEOUT`, `OTEL_EXPORTER_OTLP_COMPRESSION`, `OTEL_EXPORTER_OTLP_CERTIFICATE`, `OTEL_EXPORTER_OTLP_CLIENT_KEY`, `OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE`
- per-signal (override shared per signal): `OTEL_EXPORTER_OTLP_TRACES_*`, `OTEL_EXPORTER_OTLP_LOGS_*`, `OTEL_EXPORTER_OTLP_METRICS_*`

For each field, `kuma-dp` resolves the first available source. With default `precedence: EnvFirst`:

1. signal-specific environment variable (when `allowSignalOverrides: true`)
2. shared environment variable
3. explicit field on the backend
4. built-in default

With `precedence: ExplicitFirst`, the explicit backend field moves from position 3 to 1.

When `mode: Disabled`, environment variables are skipped entirely (points 1 and 2).

When `mode: Required`, missing or invalid input blocks the signal even if explicit config or defaults could otherwise fill the gap. Use `Required` when missing input should fail loud - the signal blocks, `RequiredEnvMissing` shows up in `DataplaneInsight`, and you can alert on the absence of exported data.

Environment-variable values change only when `kuma-dp` restarts and re-bootstraps. Status updates pick them up at the same time.

### Ambiguity rule

OpenTelemetry environment variables are process-global. If one data plane resolves more than one backend for the same signal and both backends allow environment input, the control plane cannot tell which backend the values belong to. The signal is marked `ambiguous` and environment input is dropped for it. Explicit config still applies. Plan one backend per signal per data plane, or set `mode: Disabled` on backends that should never receive environment input.

## Troubleshooting

The control plane writes runtime status per backend and signal to each [DataplaneInsight](/docs/{{ page.release }}/resources/dataplane/) under `spec.openTelemetry`. Read it with:

```sh
kubectl get dataplaneinsight <name> -o yaml   # Kubernetes
kumactl inspect dataplane <name>              # Universal
```

Per signal (one block each for `traces`, `metrics`, `logs`):

| Field | Description |
|-------|-------------|
| `enabled` | whether a policy targets this signal on this backend - `false` means no policy asked for it, distinct from `state: missing` (asked for but unresolved) |
| `state` | `ready`, `blocked`, `missing`, or `ambiguous` |
| `envAllowed` | whether `env.mode` permits environment input for this backend |
| `envInputPresent` | whether `kuma-dp` reported any matching environment-variable keys at bootstrap |
| `overrideKinds` | OTLP fields where a per-signal variable overrides the shared layer (sorted), such as `endpoint`, `protocol`, `headers`, `timeout` |
| `missingFields` | fields the merge could not produce, such as `endpoint`, `protocol`, `headers`, `client_key` |
| `blockedReasons` | one or more of `EnvDisabledByPolicy`, `RequiredEnvMissing`, `SignalOverridesDisallowed`, `MultipleBackendsForSignal` |

A signal is `ready` when the merge produces an `endpoint`. Other fields fall back to OpenTelemetry SDK defaults. A signal can be `ready` and still carry `blockedReasons` - those are soft blocks (`EnvDisabledByPolicy`, `SignalOverridesDisallowed`) that tell you environment input was ignored, not that export failed. Hard blocks (`RequiredEnvMissing`, `MultipleBackendsForSignal`) move the state out of `ready`.

### Signal missing: no endpoint resolved

```yaml
openTelemetry:
  backends:
  - name: from-env
    metrics:
      enabled: true
      state: missing
      envAllowed: true
      envInputPresent: false
      missingFields:
      - endpoint
```

The backend has no explicit address and no environment input was found. Either set `endpoint.address` on the backend or check the sidecar environment for `OTEL_EXPORTER_OTLP_ENDPOINT` or `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`.

### Signal blocked: required input missing

```yaml
openTelemetry:
  backends:
  - name: tenant-cloud
    traces:
      enabled: true
      state: blocked
      envAllowed: true
      envInputPresent: false
      blockedReasons:
      - RequiredEnvMissing
```

The backend has `mode: Required` but `kuma-dp` did not report the expected environment keys. Inject them on the sidecar and restart the data plane so the keys reach the control plane through bootstrap.

### Signal ambiguous: more than one backend competing for input

```yaml
openTelemetry:
  backends:
  - name: backend-a
    traces:
      enabled: true
      state: ambiguous
      envAllowed: true
      envInputPresent: true
      blockedReasons:
      - MultipleBackendsForSignal
  - name: backend-b
    traces:
      enabled: true
      state: ambiguous
      envAllowed: true
      envInputPresent: true
      blockedReasons:
      - MultipleBackendsForSignal
```

Two backends resolve to the same data plane and both allow environment input. Set `mode: Disabled` on every backend that should not receive environment input, or scope policies so only one backend reaches each data plane.

### Backend reference does not resolve

`MeshOpenTelemetryBackend` carries a `ReferencedByPolicies` condition with reason `Referenced` while at least one policy points at it, otherwise reason `NotReferenced`. When a policy points at a backend that does not exist, the control plane logs through the `otel-backend-resolution` logger and skips the OTel export for that signal:

```text
MeshOpenTelemetryBackend not found, skipping backend  name=main-collector  labels=null
```

In multi-zone, the most common cause is a zone-authored policy referencing a Global-synced backend by `name:` instead of `labels:`. Switch to `labels: {kuma.io/display-name: <name>}`. A backend just applied on the Global control plane can also take a few seconds to reach Zone control planes through KDS - expect short-lived `NotReferenced` and "not found" log lines while sync catches up.

### Mixed-version data planes during upgrade

`backendRef` requires the data plane to advertise the `feature-otel-via-kuma-dp` feature. All 2.14 data planes do by default. During an upgrade where some proxies are still on 2.13, the control plane silently skips the OTel pipe route for those proxies - **no log entry is emitted**. The signal does not export through the backend. Confirm by reading `DataplaneInsight.openTelemetry` on the affected proxies: no signal status entries are written for `backendRef`-based backends until the proxy advertises the feature.

Inline `endpoint` configurations stay on the direct Envoy export path and keep working through the upgrade.

## See also

- [MeshMetric](/docs/{{ page.release }}/policies/meshmetric/) - metrics collection and OpenTelemetry export
- [MeshTrace](/docs/{{ page.release }}/policies/meshtrace/) - distributed tracing
- [MeshAccessLog](/docs/{{ page.release }}/policies/meshaccesslog/) - request and connection access logs
- [Multi-zone deployment](/docs/{{ page.release }}/production/deployment/multi-zone/) - KDS sync and zone scoping

## All options

{% schema_viewer kuma.io_meshopentelemetrybackends type=crd %}

{% endif_version %}
