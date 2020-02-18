# Mutual TLS

This policy enables automatic encrypted mTLS traffic for all the services in a [`Mesh`](#mesh).

Kuma ships with a `builtin` CA (Certificate Authority) which is initialized with an auto-generated root certificate. The root certificate is unique for every [`Mesh`](#mesh) and it used to sign identity certificates for every data-plane.

The mTLS feature is used for AuthN/Z as well: each data-plane is being assigned with a workload identity certificate, which is SPIFFE compatible. This certificate has a SAN set to `spiffe://<mesh name>/<service name>`. When Kuma enforces policies that require an identity, like [`TrafficPermission`](#traffic-permission), it will extract the SAN from the client certificate and use it for every identity matching operation.

By default, mTLS is **not** enabled. You can enable Mutual TLS by updating the [`Mesh`](#mesh) policy with the `mtls` setting.

On Universal:

```yaml
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    builtin: {}
```

You can apply this configuration with `kumactl apply -f [file-path]`.

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  mtls:
    enabled: true
    ca:
      builtin: {}
```

You can apply this configuration with `kubectl apply -f [file-path]`.

Currently, Kuma only supports self-signed certificates (`builtin`). In the future, we plan to add support for third-party Certificate Authorities.

::: tip
With mTLS enabled, traffic is restricted by default. Remember to apply a `TrafficPermission` policy to permit connections
between Dataplanes.
:::