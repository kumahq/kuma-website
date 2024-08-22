---
title: Authentication with the API server
content_type: how-to
---

{{site.mesh_product_name}} exposes API server on [ports]{% if_version lte:2.1.x %}(/docs/{{ page.version }}/networking/networking){% endif_version %}{% if_version gte:2.2.x %}(/docs/{{ page.version }}/production/use-mesh#control-plane-ports){% endif_version %} `5681` and `5682` (protected by TLS).

An authenticated user can be authorized to execute administrative actions such as
* Managing administrative resources like {{site.mesh_product_name}} Secrets on Universal
* Generating user token, data plane proxy token, zone ingress token, zone token

## User token

A user token is a signed JWT token that contains
* The name of the user
* The list of groups that a user belongs to
* Expiration date of the token

### Groups

A user can be a part of many groups. {{site.mesh_product_name}} adds two groups to a user automatically:
* authenticated users are a part of `mesh-system:authenticated`.
* unauthenticated users are part of `mesh-system:unauthenticated`.

### Admin user token

{{site.mesh_product_name}} creates an admin user token on the first start of the control plane.
The admin user token is a user token issued for user `mesh-system:admin` that belongs to `mesh-system:admin` group.
This group is {% if_version lte:2.1.x %}[authorized by default](/docs/{{ page.version }}/security/api-access-control){% endif_version %}{% if_version gte:2.2.x %}[authorized by default](/docs/{{ page.version }}/production/secure-deployment/api-access-control/){% endif_version %} to execute all administrative operations.

{% tabs admin-user-token useUrlFragment=false %}
{% tab admin-user-token Kubernetes %}
1. Access admin user token

   Use `kubectl` to extract the admin token

   ```sh
   kubectl get secret admin-user-token -n {{site.mesh_namespace}} {% raw %}--template={{.data.value}}{% endraw %} | base64 -d
   ```

2. Expose {{site.mesh_product_name}} CP to be accessible from your machine

   To access {{site.mesh_product_name}} CP via kumactl, you need to expose {{site.mesh_product_name}} CP outside of a cluster in one of the following ways:
   * Port-forward port 5681
   * Expose port 5681 and protect it by TLS or just expose 5682 with builtin TLS of `{{site.mesh_cp_name}}` service via a load balancer.
   * Expose port 5681 of `{{site.mesh_cp_name}}` via `Ingress` (for example Kong Ingress Controller) and protect it with TLS

3. Configure `kumactl` with admin user token
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://<CONTROL_PLANE_ADDRESS>:5682 \
     --auth-type=tokens \
     --auth-conf token=<GENERATED_TOKEN> \
     --ca-cert-file=/path/to/ca.crt
   ```
   If you are using `5681` port, change the schema to `http://`.

   If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

{% endtab %}
{% tab admin-user-token Universal %}
1. Access admin user token

   Execute the following command on the machine where you deployed the control plane.
   ```sh
   curl http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d
   ```

2. Configure `kumactl` with admin user token
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://<CONTROL_PLANE_ADDRESS>:5682 \
     --auth-type=tokens \
     --auth-conf token=<GENERATED_TOKEN> \
     --ca-cert-file=/path/to/ca.crt
   ```
   If you are using `5681` port, change the schema to `http://`.

   If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

3. Disable localhost is admin (optional)

   By default, all requests originated from localhost are authenticated as an `mesh-system:admin` user.
   After you retrieve and store the admin token, [configure a control plane](/docs/{{ page.version }}/documentation/configuration) with `KUMA_API_SERVER_AUTHN_LOCALHOST_IS_ADMIN` set to `false`.
   {% endtab %}
   {% endtabs %}

### Generate user tokens

You can generate user tokens only when you provide the credentials of a user {% if_version lte:2.1.x %}[authorized to generate user tokens](/docs/{{ page.version }}/security/api-access-control#generate-user-token){% endif_version %}{% if_version gte:2.2.x %}[authorized to generate user tokens](/docs/{{ page.version }}/production/secure-deployment/api-access-control#generate-user-token){% endif_version %}.
`kumactl` configured with admin user token extracted in the preceding section is authorized to do it.

```sh
kumactl generate user-token \
  --name john \
  --group team-a \
  --valid-for 24h
```

or you can use API

```sh
curl localhost:5681/tokens/user \
  -H'authorization: Bearer eyJhbGc...' \
  -H'content-type: application/json' \
  --data '{"name": "john","groups": ["team-a"], "validFor": "24h"}' 
```

### Explore an example token

You can decode the tokens to validate the signature or explore details.

For example, run:

```sh
kumactl generate user-token \
  --name john \
  --group team-a \
  --valid-for 24h
```

which returns:

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IjEiLCJ0eXAiOiJKV1QifQ.eyJOYW1lIjoiam9obiIsIkdyb3VwcyI6WyJ0ZWFtLWEiXSwiZXhwIjoxNjM2ODExNjc0LCJuYmYiOjE2MzY3MjQ5NzQsImlhdCI6MTYzNjcyNTI3NCwianRpIjoiYmYzZDBiMmUtZDg0MC00Y2I2LWJmN2MtYjkwZjU0MzkxNDY4In0.XsaPcQ5wVzRLs4o1FWywf6kw4r2ceyLGxYO8EbyA0fAxU6BPPRsW71ueD8ZlS4JlD4UrVtQQ7LG-z_nIxlDRAYhx4mmHnSjtqWZIsVS13QRrm41zccZ0SKHYxGvWMW4IkGwUbA0UZOJGno8vbpI6jTGfY9bmof5FpJJAj_sf99jCaI1H_n3n5UxtwKVN7dXXD82r6axj700jgQD-2O8gnejzlTjZkBpPF_lGnlBbd39S34VNwT0UlvRJLmCRdfh5EL24dFt0tyzQqDG2gE1RuGvTV9LOT77ZsjfMP9CITICivF6Z7uqvlOYal10jd5gN0A6w6KSI8CCaDLmVgUHvAw
```

Paste the token into the UI at [jwt.io](https://jwt.io), or use [`jwt-cli`](https://www.npmjs.com/package/jwt-cli) tool

```sh
kumactl generate user-token --name=john --group=team-a --valid-for=24h | jwt

To verify on jwt.io:

https://jwt.io/#id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjEiLCJ0eXAiOiJKV1QifQ.eyJOYW1lIjoiam9obiIsIkdyb3VwcyI6WyJ0ZWFtLWEiXSwiZXhwIjoxNjM2ODExNjc0LCJuYmYiOjE2MzY3MjQ5NzQsImlhdCI6MTYzNjcyNTI3NCwianRpIjoiYmYzZDBiMmUtZDg0MC00Y2I2LWJmN2MtYjkwZjU0MzkxNDY4In0.XsaPcQ5wVzRLs4o1FWywf6kw4r2ceyLGxYO8EbyA0fAxU6BPPRsW71ueD8ZlS4JlD4UrVtQQ7LG-z_nIxlDRAYhx4mmHnSjtqWZIsVS13QRrm41zccZ0SKHYxGvWMW4IkGwUbA0UZOJGno8vbpI6jTGfY9bmof5FpJJAj_sf99jCaI1H_n3n5UxtwKVN7dXXD82r6axj700jgQD-2O8gnejzlTjZkBpPF_lGnlBbd39S34VNwT0UlvRJLmCRdfh5EL24dFt0tyzQqDG2gE1RuGvTV9LOT77ZsjfMP9CITICivF6Z7uqvlOYal10jd5gN0A6w6KSI8CCaDLmVgUHvAw

✻ Header
{
  "alg": "RS256",
  "kid": "1",
  "typ": "JWT"
}

✻ Payload
{
  "Name": "john",
  "Groups": [
    "team-a"
  ],
  "exp": 1636811674,
  "nbf": 1636724974,
  "iat": 1636725274,
  "jti": "bf3d0b2e-d840-4cb6-bf7c-b90f54391468"
}
   Issued At: 1636725274 11/12/2021, 2:54:34 PM
   Not Before: 1636724974 11/12/2021, 2:49:34 PM
   Expiration Time: 1636811674 11/13/2021, 2:54:34 PM

✻ Signature XsaPcQ5wVzRLs4o1FWywf6kw4r2ceyLGxYO8EbyA0fAxU6BPPRsW71ueD8ZlS4JlD4UrVtQQ7LG-z_nIxlDRAYhx4mmHnSjtqWZIsVS13QRrm41zccZ0SKHYxGvWMW4IkGwUbA0UZOJGno8vbpI6jTGfY9bmof5FpJJAj_sf99jCaI1H_n3n5UxtwKVN7dXXD82r6axj700jgQD-2O8gnejzlTjZkBpPF_lGnlBbd39S34VNwT0UlvRJLmCRdfh5EL24dFt0tyzQqDG2gE1RuGvTV9LOT77ZsjfMP9CITICivF6Z7uqvlOYal10jd5gN0A6w6KSI8CCaDLmVgUHvAw
```

### Token revocation

{{site.mesh_product_name}} doesn't keep the list of issued tokens. To invalidate the token, you can add it to a revocation list.
Every user token has its own ID. As you saw in the previous section, it's available in payload under `jti` key.
To revoke tokens, specify list of revoked IDs separated by `,` and store it as `GlobalSecret` named `user-token-revocations`

{% tabs token-revocation useUrlFragment=false %}
{% tab token-revocation Kubernetes %}
```sh
REVOCATIONS=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) && echo "apiVersion: v1
kind: Secret
metadata:
  name: user-token-revocations
  namespace: {{site.mesh_namespace}} 
data:
  value: $REVOCATIONS
type: system.kuma.io/global-secret" | kubectl apply -f -
```
{% endtab %}
{% tab token-revocation Universal %}
```sh
echo "
type: GlobalSecret
name: user-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endtab %}
{% endtabs %}

### Signing key

A user token is signed by a signing key that's autogenerated on the first start of the control plane.
The signing key is a 2048-bit RSA key stored as a `GlobalSecret` with a name that looks like `user-token-signing-key-{serialNumber}`.

### Signing key rotation

If the signing key is compromised, you must rotate it including all the tokens that were signed by it.

1. Generate a new signing key

   Make sure to generate the new signing key with a serial number greater than the serial number of the current signing key.

   {% capture tabs %}
   {% tabs key-rotation useUrlFragment=false %}
   {% tab key-rotation Kubernetes %}
   Check what's the current highest serial number.

   ```sh
   kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
   NAME                          TYPE                           DATA   AGE
   user-token-signing-key-1   system.kuma.io/global-secret   1      25m
   ```

   In this case, the highest serial number is `1`. Generate a new signing key with a serial number of `2`
   ```sh
   TOKEN="$(kumactl generate signing-key)" && echo "
   apiVersion: v1
   data:
     value: $TOKEN
   kind: Secret
   metadata:
     name: user-token-signing-key-2
     namespace: {{site.mesh_namespace}}
   type: system.kuma.io/global-secret
   " | kubectl apply -f - 
   ```

   {% endtab %}
   {% tab key-rotation Universal %}
   Check what's the current highest serial number.
   ```sh
   kumactl get global-secrets
   NAME                             AGE
   user-token-signing-key-1   36m
   ```

   In this case, the highest serial number is `1`. Generate a new signing key with a serial number of `2`
   ```sh
   echo "
   type: GlobalSecret
   name: user-token-signing-key-2
   data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
   ```
   {% endtab %}
   {% endtabs %}
   {% endcapture %}
   {{ tabs | indent }}

2. Regenerate user tokens

   Create new user tokens. Tokens are always signed by the signing key with the highest serial number.
   Starting from now, tokens signed by either new or old signing key are valid.

3. Remove the old signing key
   {% capture tabs %}
   {% tabs remove-key useUrlFragment=false %}
   {% tab remove-key Kubernetes %}
   ```sh
   kubectl delete secret user-token-signing-key-1 -n {{site.mesh_namespace}}
   ```
   {% endtab %}
   {% tab remove-key Universal %}
   ```sh
   kumactl delete global-secret user-token-signing-key-1
   ```
   {% endtab %}
   {% endtabs %}
   {% endcapture %}
   {{ tabs | indent }}

   All new requests to the control plane now require tokens signed with the new signing key.

### Disabling bootstrap of the admin user token

You can remove the default admin user token from the storage and prevent it from being recreated.
Keep in mind that even if you remove the admin user token, the signing key is still present.
A malicious actor that acquires the signing key, can generate an admin token.

{% tabs bootstrap useUrlFragment=false %}
{% tab bootstrap Kubernetes %}
1. Delete `admin-user-token` Secret
```sh
kubectl delete secret admin-user-token -n kuma-namespace
```

2. Disable bootstrap of the token
   [Configure a control plane](/docs/{{ page.version }}/documentation/configuration) with `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` set to `false`.
   {% endtab %}
   {% tab bootstrap Universal %}
1. Delete `admin-user-token` Global Secret
```sh
kumactl delete global-secret admin-user-token
```

2. Disable bootstrap of the token
   [Configure a control plane](/docs/{{ page.version }}/documentation/configuration) with `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` set to `false`.
   {% endtab %}
   {% endtabs %}

{% if_version gte:2.2.x %}
### Offline token issuing

In addition to the regular flow of generating signing keys, storing them in secret, and using them to sign tokens on the control plane, Kuma also offers offline signing of tokens.
In this flow, you can generate a pair of public and private keys and configure the control plane only with public keys for token verification.
You can generate all the tokens without running the control plane.

The advantages of this mode are:
* easier, more reproducible deployments of the control plane, and more in line with GitOps.
* potentially more secure setup, because the control plane does not have access to the private keys.

Here's how to use offline issuing

1. Generate a pair of signing keys

   The following commands generate standard RSA key of 2048 bits and outputs it in PEM-encoded format.
   You can use any external tool to generate a pair of keys.

   ```sh
   kumactl generate signing-key --format=pem > /tmp/key-private.pem
   kumactl generate public-key --signing-key-path=/tmp/key-private.pem > /tmp/key-public.pem
   ```

   The result should be similar to this output
   ```sh
   cat /tmp/key-private.pem /tmp/key-public.pem 
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/r
   ...
   htKtzsYA7yGlt364IuDybrP+PlPMSK9cQAmWRRZIcBNsKOODkAgKFA==
   -----END RSA PRIVATE KEY-----
   -----BEGIN RSA PUBLIC KEY-----
   MIIBCgKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/rL2u/
   ...
   se7sx2Pt/NPbWFFTMGVFm3A1ueTUoorW+wIDAQAB
   -----END RSA PUBLIC KEY----- 
   ```

2. Configure the control plane with public key

   [Configure a control plane](/docs/{{ page.version }}/documentation/configuration) with the following settings
   ```yaml
   apiServer:
     authn:
       type: tokens
       tokens:
         enableIssuer: false # disable control plane token issuer that uses secrets
         validator:
           useSecrets: false # do not use signing key stored in secrets to validate the token
           publicKeys:
           - kid: "key-1"
             key: |
               -----BEGIN RSA PUBLIC KEY-----
               MIIBCgKCAQEAsS61a79gC4mkr2Ltwi09ajakLyUR8YTkJWzZE805EtTkEn/rL2u/
               ...
               se7sx2Pt/NPbWFFTMGVFm3A1ueTUoorW+wIDAQAB
               -----END RSA PUBLIC KEY-----
   ```
   
3. Use the private key to issue tokens offline

   The command is the same as with online signing, but with two additional arguments:
   * `--kid` - ID of the key that should be used to validate the token. This should match `kid` specified in the control plane configuration.
   * `--signing-key-path` - path to a PEM-encoded private key.

   ```sh
   kumactl generate user-token \
     --name john.doe@example.com \
     --group users \
     --valid-for 24h \
     --signing-key-path /tmp/key-private.pem \
     --kid key-1
   ```
   
   You can also use any external system that can issue JWT tokens using `RS256` signing method with the following claims:
   * `Name` (string) - the name of the user
   * `Groups` ([]string) - list of user groups
   
#### Migration

You can use both offline and online issuing by keeping `apiServer.authn.tokens.enableIssuer` to true.
You can use both secrets and public key static config validators by keeping `apiServer.authn.tokens.validator.useSecrets` to true.

#### Management

Token revocation works the same when using both online and offline issuing.

Signing key rotation works similarly:
* generate another pair of signing keys
* configure a control plane with old and new public keys
* regenerate tokens for all existing users with the new private key
* remove the old public key from the configuration
{% endif_version %}

## Admin client certificates

This section describes the alternative way of authenticating to API Server.

{% warning %}
Admin client certificates are deprecated. If you are using it, please migrate to the user token in preceding section.
{% endwarning %}

To use admin client certificates, set `KUMA_API_SERVER_AUTHN_TYPE` to `adminClientCerts`.

All users that provide client certificate are authenticated as a user with the name `mesh-system:admin` that belongs to group `mesh-system:admin`.

### Usage

1. Generate client certificates by using kumactl
   ```sh
   kumactl generate tls-certificate --type=client \
     --cert-file=/tmp/tls.crt \
     --key-file=/tmp/tls.key
   ```

2. Configure the control plane with client certificates
   {% capture tabs %}
   {% tabs usage useUrlFragment=false %}
   {% tab usage Kubernetes (kumactl) %}
   Create a secret in the namespace in which control plane is installed
   ```sh
   kubectl create secret generic api-server-client-certs -n {{site.mesh_namespace}} \
     --from-file=client1.pem=/tmp/tls.crt \
   ```
   You can provide as many client certificates as you want. Remember to only provide certificates without keys.

   Point to this secret when installing {{site.mesh_product_name}}
   ```sh
   kumactl install control-plane \
     --tls-api-server-client-certs-secret=api-server-client-certs
   ```
   {% endtab %}
   {% tab usage Kubernetes (HELM) %}
   Create a secret in the namespace in which control plane is installed
   ```sh
   kubectl create secret generic api-server-client-certs -n {{site.mesh_namespace}} \
     --from-file=client1.pem=/tmp/tls.crt \
   ```
   You can provide as many client certificates as you want. Remember to only provide certificates without keys.

   Set `{{site.set_flag_values_prefix}}controlPlane.tls.apiServer.clientCertsSecretName` to `api-server-client-certs` via HELM
   {% endtab %}
   {% tab usage Universal %}
   Put all the certificates in one directory
   ```sh
   mkdir /opt/client-certs
   cp /tmp/tls.crt /opt/client-certs/client1.pem 
   ```
   All client certificates must end with `.pem` extension. Remember to only provide certificates without keys.

   Configure control plane by pointing to this directory
   ```sh
   KUMA_API_SERVER_AUTH_CLIENT_CERTS_DIR=/opt/client-certs \
     kuma-cp run
   ```
   {% endtab %}
   {% endtabs %}
   {% endcapture %}
   {{ tabs | indent }}

3. Configure `kumactl` with valid client certificate
   ```sh
   kumactl config control-planes add \
     --name=<NAME>
     --address=https://<KUMA_CP_DNS_NAME>:5682 \
     --client-cert-file=/tmp/tls.crt \
     --client-key-file=/tmp/tls.key \
     --ca-cert-file=/tmp/ca.crt
   ```

   If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

## Multizone

In a multizone setup, users execute a majority of actions on the global control plane.
However, some actions like generating dataplane tokens are available on the zone control plane.
The global control plane doesn't propagate authentication credentials to the zone control plane.
You can set up consistent user tokens across the whole setup by manually copying signing key from global to zone control planes. 
