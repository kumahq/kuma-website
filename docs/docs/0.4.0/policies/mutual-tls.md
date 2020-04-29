# Mutual TLS

This policy enables automatic encrypted mTLS traffic for all the services in a [`Mesh`](../mesh).

Kuma ships with a `builtin` CA (Certificate Authority) which is initialized with an auto-generated root certificate. The root certificate is unique for every [`Mesh`](../mesh) and it used to sign identity certificates for every data-plane. Kuma also supports third-party CA.

The mTLS feature is used for AuthN/Z as well: each data-plane is being assigned with a workload identity certificate, which is SPIFFE compatible. This certificate has a SAN set to `spiffe://<mesh name>/<service name>`. When Kuma enforces policies that require an identity, like [`TrafficPermission`](../traffic-permissions), it will extract the SAN from the client certificate and use it for every identity matching operation.

By default, mTLS is **not** enabled. You can enable Mutual TLS by updating the [`Mesh`](../mesh) policy with the `mtls` setting.

::: tip
With mTLS enabled, all traffic is denied by default.

Remember to apply a `TrafficPermission` policy to explictly allow legitimate traffic between certain Dataplanes.
:::

### Builtin CA

On Universal:

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1 # enable mTLS 
  backends:
  - name: ca-1
    type: builtin # use Builtin CA (a unique Root CA certificate will be generated automatically)
```

You can apply this configuration with `kumactl apply -f [file-path]`.

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1 # enable mTLS 
    backends:
    - name: ca-1
      type: builtin # use Builtin CA (a unique Root CA certificate will be generated automatically)
```

You can apply this configuration with `kubectl apply -f [file-path]`.

### Provided CA

In some cases users might need to opt out of auto-generated Root CA certificates, e.g. to stay compliant with internal company policies.

To that end, Kuma supports another type of CA - `provided` CA.

Like the name implies, a user will have to provide a custom Root CA certificate and take a responsibility for managing its lifecycle.

A complete workflow of chaning CA type from `builtin` to `provided` looks the following way:

1. A user must first upload a custom Root CA certificate using `kumactl manage ca provided` command, e.g.

   ```shell
   kumactl manage ca provided certificates add --mesh demo --cert-file demo.root_ca.crt --key-file demo.root_ca.key
   ```

   ::: warning
   This is a security-sensitive opreation, which implies very restrictive default settings.

   If you are just Getting Started with Kuma, run `kumactl manage ca provided` commands on the same machine where `kuma-cp` is running.
   :::

2. Next, a user must **disable** mTLS on a `Mesh` before he will be allowed to change CA type from `builtin` to `provided`, e.g.

   On Universal:

   ```shell
   echo "
   type: Mesh
   name: demo
   mtls:
    # there is no enabledBackend property which means mTLS is enabled
    backends:
    - name: ca-1
      type: builtin # use Builtin CA (a unique Root CA certificate will be generated automatically)
   " | kumactl apply -f -
   ```

   On Kubernetes:

   ```shell
   echo "
   apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: default
   spec:
     mtls:
      # there is no enabledBackend property which means mTLS is enabled
      backends:
      - name: ca-1
        type: builtin # use Builtin CA (a unique Root CA certificate will be generated automatically)
   " | kubectl apply -f -
   ```

3. A user can now change CA type to `provided` and **enable** mTLS back after that

   On Universal:

   ```shell
   echo "
   type: Mesh
   name: demo
   mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: provided
      config:
        cert:
          secret: path-to-secret
        key:
          secret: path-to-secret
   " | kumactl apply -f -
   ```

   On Kubernetes:

   ```shell
   echo "
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
         config:
           cert:
             secret: path-to-secret
           key:
             secret: path-to-secret
   " | kubectl apply -f -
   ```

::: warning
Root CA certificate provided by a user must meet certain constraints:
1. It MUST be a self-signed Root CA certificate (Intermediate CA certificates are not allowed)
2. It MUST have basic constraint `CA` set to `true` (see [X509-SVID: 4.1. Basic Constraints](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#41-basic-constraints))
3. It MUST have key usage extension `keyCertSign` set (see [X509-SVID: 4.3. Key Usage](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#43-key-usage))
4. It MUST NOT have key usage extension 'digitalSignature' set (see [X509-SVID: Appendix A. X.509 Field Reference](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#appendix-a-x509-field-reference))
5. It MUST NOT have key usage extension 'keyAgreement' set (see [X509-SVID: Appendix A. X.509 Field Reference](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#appendix-a-x509-field-reference))
6. It MUST NOT have key usage extension 'keyEncipherment' set (see [X509-SVID: Appendix A. X.509 Field Reference](https://github.com/spiffe/spiffe/blob/master/standards/X509-SVID.md#appendix-a-x509-field-reference))

If a provided certificate doesn't meet those constraints, `kumactl manage ca provided certificates add` command will fail with a respective error message, e.g.

```shell
kumactl manage ca provided certificates add --mesh demo --cert-file demo.root_ca.crt --key-file demo.root_ca.key

Error: Could not add signing cert (Resource is not valid)
* cert: certificate must be self-signed (intermediate CAs are not allowed)
```

The error message in the above example indicates that a user is trying to upload an Intermediate CA certificate while only Root CA certificates are allowed.
:::
