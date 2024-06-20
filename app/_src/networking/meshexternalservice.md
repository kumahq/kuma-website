---
title: MeshExternalService
---

{% warning %}
This resource is experimental!
{% endwarning %}

This resource allows services running inside the mesh to consume services that are not part of the mesh.
The `MeshExternalService` resource allows you to declare external resources instead of relying on [MeshPassthrough](/docs/{{ page.version }}/policies/meshpassthrough) or [passthrough mode](/docs/{{ page.version }}/networking/non-mesh-traffic#outgoing).

{% warning %}
Currently `MeshExternalService` resource only supports targeting by [MeshTrafficPermission](/docs/{{ page.version }}/policies/meshtrafficpermission) with [Zone Egress](/docs/{{ page.version }}/production/cp-deployment/zoneegress).
This limitation will be lifted in the next release.
{% endwarning %}

## Configuration

### Match

This section specifies the rules for matching traffic that will be routed to external resources defined in `endpoints` section.
The only `type` supported is [HostnameGenerator](/docs/{{ page.version }}/policies/hostnamegenerator) and it means that it will match traffic directed to a hostname created by the hostname generator.
The `port` field when omitted means that all traffic will be matched.
Protocols that are supported are: `tcp`, `grpc`, `http`, `http2`.

```yaml
match:
  type: HostnameGenerator # optional
  port: 4244
  protocol: tcp
```

### Endpoints

This section specifies the destination of the matched traffic.
It's possible to define IPs, DNS names and unix domain sockets.

```yaml
endpoints:
  - address: 1.1.1.1
    port: 12345
  - address: example.com
    port: 80
  - address: unix:///tmp/example.sock
```

### TLS

This section describes the TLS and verification behaviour.
TLS origination happens on the sidecar, so if your application is already using TLS you might want to use [MeshPassthrough](/docs/{{ page.version }}/policies/meshpassthrough).
You can define TLS version requirements, option to allow renegotiation, verification of SNI, SAN, custom CA and client certificate and key for server verification.
To disable parts of the verification you can set different `mode` - `SkipSAN`, `SkipCA`, `SkipAll`, `Secured` (default).

```yaml
tls:
  version:
    min: TLS12
    max: TLS13
  allowRenegotiation: false
  verification:
    mode: SkipCA
    serverName: "example.com"
    subjectAltNames:
      - type: Exact
        value: example.com
      - type: Prefix
        value: "spiffe://example.local/ns/local"
    caCert:
      inline: dGVzdA==
    clientCert:
      secret: "123"
    clientKey:
      secret: "456"
```

When TLS is enabled but `caCert` is not set, the sidecar uses the [autodetected OS-specific CA](https://github.com/kumahq/kuma/blob/aba6518fca65bc7ab52e5328eb686a51a6f98a53/app/kuma-dp/pkg/dataplane/certificate/cert.go#L12).
The user can override the default CA by setting the path in the environment variable `KUMA_DATAPLANE_RUNTIME_DYNAMIC_SYSTEM_CA_PATH` for the sidecar.

### DNS setup

To be able to access `MeshExternalService` via a hostname you need to define a [HostnameGenerator](/docs/{{ page.version }}/policies/hostnamegenerator) with a `meshExternalService` selector.
In the future release a default [HostnameGenerator](/docs/{{ page.version }}/policies/hostnamegenerator) will be provided.

Once a [HostnameGenerator](/docs/{{ page.version }}/policies/hostnamegenerator) and a `MeshExternalService` is in place the following will happen:
- a hostname (or multiple hostnames if there are many `HostnameGenerators` matching) are generated using the specified templates
- a VIP is allocated from `242.0.0.0/8` range (can be changed by `KUMA_IPAM_MESH_EXTERNAL_SERVICE_CIDR` environment variable)
- Envoy cluster is created which will use endpoints defined in `spec.endpoints` as the [cluster endpoints](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/endpoint/v3/endpoint_components.proto)

{% warning %}
Do **not** hijack original addresses like httpbin.com (the way it was done with [External Service](/docs/{{ page.version }}/policies/external-services)).
Hijacking the original address is like performing a man-in-the-middle attack so there is a high chance of something breaking.
If you need to transparently pass traffic through the Mesh without modifying it use [MeshPassthrough](/docs/{{ page.version }}/policies/meshpassthrough).
{% endwarning %}

For clients that the hostname is not fully known in advance please take a look at [Wildcard DNS matching in MeshPassthrough](/docs/{{ page.version }}/policies/meshpassthrough/#wildcard-dns-matching).

## Examples

TCP examples use https://tcpbin.com/ service which is a TCP echo service, check out the website for more details.
HTTP examples use https://httpbin.org/ service which is a website for inspecting and debugging HTTP requests.
GRPC examples use https://grpcbin.test.k6.io/ service which is a gRPC Request & Response Service.
You can use [grpcurl](https://github.com/fullstorydev/grpcurl) as a client, it is available in [netshoot](https://github.com/nicolaka/netshoot) debug image alongside other tools used in later sections.

For the examples below we're using a [single-zone deployment](/docs/{{ page.version }}/production/deployment/single-zone) and the following `HostnameGenerator`:

{% policy_yaml hostnamegen %}
{% raw %}
```yaml
type: HostnameGenerator
name: example
mesh: default
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone # only consider local MeshExternalServices
  template: '{{ .DisplayName }}.svc.meshext.local'
```
{% endraw %}
{% endpolicy_yaml %}

If you're in [multi-zone deployment](/docs/{{ page.version }}/production/deployment/multi-zone) and you're applying resources on the global control plane you'd need a second `HostnameGenerator` with `matchLabels: kuma.io/origin: global` for resources applied on the global Control Plane and to adjust the URLs accordingly to match the template.

### TCP

This is a simple example of accessing `tcpbin.com` service without TLS that echos back bytes sent to it.

{% policy_yaml tcp %}
```yaml
type: MeshExternalService
name: mes-tcp
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4242
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4242
```
{% endpolicy_yaml %}

Running this should result in printing 'echo this' in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp.svc.meshext.local 4242
```

### TCP with TLS

This example builds up on the previous example adding TLS verification with default system CA.
Notice that we're using a TLS port `4243`.

{% policy_yaml tcp-tls %}
```yaml
type: MeshExternalService
name: mes-tcp-tls
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4243
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4243
  tls:
    enabled: true
    verification:
      serverName: tcpbin.com
```
{% endpolicy_yaml %}

Running this should result in printing 'echo this' in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp-tls.svc.meshext.local 4243
```

### TCP with mTLS

This example builds up on the previous example adding client cert and key.
Notice that we're using an mTLS port `4244`.

{% tip %}
In a real world scenario you should use `secret` and refer to it through it's name and store sensitive information as a Kubernetes secret instead of using `inline`.
This example is purposefully simplified to make it easy to try out.
{% endtip %}

{% policy_yaml tcp-mtls %}
```yaml
type: MeshExternalService
name: mes-tcp-mtls
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4244
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4244
  tls:
    enabled: true
    verification:
      serverName: tcpbin.com
      clientCert:
        inline: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURaVENDQWsyZ0F3SUJBZ0lCS2pBTkJna3Foa2lHOXcwQkFRc0ZBRENCaXpFTE1Ba0dBMVVFQmhNQ1ZWTXgKQ3pBSkJnTlZCQWdNQWtOQk1SWXdGQVlEVlFRSERBMVRZVzRnUm5KaGJtTnBjMk52TVE4d0RRWURWUVFLREFaMApZM0JpYVc0eEREQUtCZ05WQkFzTUEyOXdjekVUTUJFR0ExVUVBd3dLZEdOd1ltbHVMbU52YlRFak1DRUdDU3FHClNJYjNEUUVKQVJZVWFHRnljbmxpWVdka2FVQm5iV0ZwYkM1amIyMHdIaGNOTWpRd05qRTBNRGt4T1RVMldoY04KTWpRd05qRTFNRGt4T1RVMldqQWNNUm93R0FZRFZRUUREQkYwWTNCaWFXNHVZMjl0TFdOc2FXVnVkRENDQVNJdwpEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS3VZVHo0UzRIcEtvc05FRWcxbDFOT3ZORjZtCkxEN0o4d1ZsdFVSd2JXNDNaM2JJVmNOUFVuNjdkTVpEUUpRcVU2Z05kRTg0eXBvQTUxbXpqcC9IeGZZY2c1cEMKZXFyK1RtVDV1S3UyME8ycDZmYXhrZDlYUHpmWXUybE1QM0tROU9DbmpNbEIwQkFiNUNpTklRTmIwMUtheDhCOAphT0Z1a3VYKzdheWhRRXFxRHJ5d0d6Q0hJc2ppU3lDVHdRRXhiQVJTY1BGOW5XaDlHZVRERGlRSEtKUXFVOEpnClVoRGMzQUdjdlI2c0pEZFZ1RXl2UndrNVcrTFhoNktPQVAwNHEwaGF2OXFiaXNaZitXNVNRMDFvbXIzRGhzSTQKZkx2c05oN0I5UGpqaVNnV09hQ3F4bEdCSDNJdUJtWXgxR1k5RCtia0VJazVsVkZ4WC92d0N1SmhzRlVDQXdFQQpBYU5DTUVBd0hRWURWUjBPQkJZRUZGSDRnN3V3OFdzTUIwYlRKNld2NFV5NGtlME1NQjhHQTFVZEl3UVlNQmFBCkZPTHVNb3dCU0FaZlY1djgyTG1sYUlJT3ZVL0RNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUJmYzlxQWFNUjcKbTEzMlZoSk52M0dVOXNZMytMUHN6dkJMMkYyeGw5U1AwVlA3cG9Hd3ZvSnJ0cXdGR0FFaGtibzNCUkhvZTBTMwpVUkdtTlNjWlpTMVdkQllBSVdvdkJKbFNhakxqVDVWNGNrc0FXVjZ3djlmaE9XcXFTSmpVaEwwZ3FkWkp2NDNoCkFnVnZGeXQrUHF4NmpZMHBhUkp6TS9OM1pkTFBDTkZiMVlIMzE3Q0FyQlV1R2xWQzJzRDNJd0lEK0YzczdhOEcKQ2FSb0VnWGpNdEZVcnBJN2RqaTVSeHlENE9Ma2o3bmw0aXk3anJDWlAvRitKbys4dEo3NVI4VW8xeU8zSXorOApTanFkYWdwT3RKQzdEV1pyNlNYOW85a0lsTUl4SEhITmN0RElteXB6SytmWFpaZUFnTVVTSE1kWCsrd0xNTVdrCnZ0Tm1vUFZVVHJvNwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCgo=
      clientKey:
        inline: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQ3JtRTgrRXVCNlNxTEQKUkJJTlpkVFRyelJlcGl3K3lmTUZaYlZFY0cxdU4yZDJ5RlhEVDFKK3UzVEdRMENVS2xPb0RYUlBPTXFhQU9kWgpzNDZmeDhYMkhJT2FRbnFxL2s1aytiaXJ0dER0cWVuMnNaSGZWejgzMkx0cFREOXlrUFRncDR6SlFkQVFHK1FvCmpTRURXOU5TbXNmQWZHamhicExsL3Uyc29VQktxZzY4c0Jzd2h5TEk0a3NnazhFQk1Xd0VVbkR4Zloxb2ZSbmsKd3c0a0J5aVVLbFBDWUZJUTNOd0JuTDBlckNRM1ZiaE1yMGNKT1Z2aTE0ZWlqZ0Q5T0t0SVdyL2FtNHJHWC9sdQpVa05OYUpxOXc0YkNPSHk3N0RZZXdmVDQ0NGtvRmptZ3FzWlJnUjl5TGdabU1kUm1QUS9tNUJDSk9aVlJjVi83CjhBcmlZYkJWQWdNQkFBRUNnZ0VBRTRiM3JaYTBXUFpaWTJOQnNxaWQrYUQ4a3JEU1pDclRMeEFOK3NYWWppeGIKNTlhUWUvTnc3ZDhqUU5TeWFxb09ieGRvM3dNVmUwVVREdEF5TU5pcEhJTE9MeVhWazlQdzAramZMUnRXMTFUNAp2UXdrRDRoOE56ekF4eERZUDQ5amJwVmluaHlSTXVRWnFNdTJzQTBwRlVOcjYrbThmYnI1bUpiVU1Vc0FaLzZXCmJzRjYyOEZxcVk3S0ZDSkY0RmNZaEdoREV2WTZiaWFUc3l2aUhSRWFhSkl1Mm5qQ3EwUnAza1UwSlhGamlXVS8KZSt4WHpoeXlKbkFsejNzRmJycWZzV3I1UHJ5NTJ3ZUlFOVBDSUxINzhldld1dXIxc0NSSHJ6SVAxS3JHWU1XMApkcXVJcllFbzZVUm1SU2ZuTzBjNFVjK2ltZzBLQUovWTFZeWM1c0MzQVFLQmdRRGhWZGt5VkRjWGUydFREZlFxCnBsU3FyWFRaZCtLRlhTdzBwNDNwMmltN2hzSmxmNUlHN3AwYWFEdUJlZUdsVmhGT3E5dU5CRmgxMWN4ajgza2gKZVI1Q1RWZXpjV1NhWExLN3pMUjdqNUFjdTlyaU1tWGFEUUdJaWQrNU83cGFnRFNtNHpOSENZdnFKYm1XcU5DWApOcXVsNFI3L3NoUGd3MjQ0R0J6TmxSdjJZUUtCZ1FEQzhrWGM4UWt1amtwS0pkVm8wWFZFd1MzdWFmb3lVeGNxClBmb2dWOEpsUE1GRCs5VjJjNkhSMkpJWktKMzU0RFhsby8ydWllZzhQT0lUMXBpVlVCQk55eElQY1FxMUcweFcKQmtPMkpyMmdyZlN6KzNwM2RzTGR5dXU5bWc4eVBiNWhwRVdjTjFtUDFiWko3YUs0Qjk5SFArczR2TXd1c2xWOApzZDI2Uk1YV2RRS0JnRnRqeWhkVGVKU1poY25GbXdYQk9BMlJGQmN2UER3Q3NlOFpGY0dHcmU1VWxYczg1aWpSCmxmNGowQjZQSkNrK1l2NlpUUTVBZVBBeHFoZlBvNDBqNWxYVnNJQWl1VDZ4NGZ1dzVuSkdvNWhEeUY1OU9qbloKbEltZ0FaREszS1hmNFhyZUl1bm93VXBSeXBlRUdEVjhBdG5nR0FaMFh3T0Z2Nm9ZZlhZVHg2ZUJBb0dBRlJQNAo5ZENoKzRTckI2VmJrNy9CL0RNZThqNUhMUlhLMVdocUdRRWtKYW9TQTNYQk9OTjcxYUtpK1ZGbzgxR0l3bEdlCjVqWkhBK3haVFdmUWk2UmlmdWJNQnh0ajJ2MGVuZGFEajdoVW5JRHlpbHRRZklZOHY1cG5MdEx2ZmJFcldvZFcKZDNPTW5YNnYvUUpTcTY4K053ZjBPT2hBODNPWXhxaThucDA4L3RrQ2dZRUFqYkNUcHhIM2hmd2p2Y2t2TFIxVQpHWVdUaVkzMWJWVDJEVTNFZjlLb09KQXJQSlRuRlNyQ0VuNEpESGk0S1NrencvRHpQRmtMRzdsSXZFV21qcTJTCnRyUGdHMEtCcWxQa1pCRkRYUy9tdWFWVzQyUFhFeVhLV1kzdFFaRnVzQk5XdVZXOFNvZW8zdTd1YWlXbHRPNzAKTnZOSW83U21MNVJ0UEF4d1NpUTJzOGc9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0KCg==
```
{% endpolicy_yaml %}

Running this should result in printing 'echo this' in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp-mtls.svc.meshext.local 4244
```

### HTTP

This is a simple example using plaintext HTTP.

{% policy_yaml http %}
```yaml
type: MeshExternalService
name: mes-http
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 80
```
{% endpolicy_yaml %}

Running this should result in printing httpbin.org HTML in the terminal:

```bash
curl -s http://mes-http.svc.meshext.local
```

### HTTPS

This example builds up on the previous example adding TLS verification with default system CA.

{% policy_yaml https %}
```yaml
type: MeshExternalService
name: mes-https
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.org
      port: 443
  tls:
    enabled: true
    verification:
      serverName: httpbin.org
```
{% endpolicy_yaml %}

Running this should result in printing httpbin.org HTML in the terminal:

```bash
curl http://mes-https.svc.meshext.local
```

### gRPC

This is a simple example using plaintext gRPC.

{% policy_yaml grpc %}
```yaml
type: MeshExternalService
name: mes-grpc
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9000
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9000
```
{% endpolicy_yaml %}

Running this should result in printing grpcbin.test.k6.io available methods:

```bash
grpcurl -plaintext -v mes-grpc.svc.meshext.local:9000 list
```

### gRPCS

This example builds up on the previous example adding TLS verification with default system CA.
Notice that we're using a different port `9001`.

{% policy_yaml grpcs %}
```yaml
type: MeshExternalService
name: mes-grpcs
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9001
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9001
  tls:
    enabled: true
    verification:
      serverName: grpcbin.test.k6.io
```
{% endpolicy_yaml %}

Running this should result in printing grpcbin.test.k6.io available methods:

```bash
grpcurl -plaintext -v mes-grpcs.svc.meshext.local:9001 list # this is using plaintext because Envoy is doing TLS origination
```

## All policy configuration settings

{% json_schema MeshExternalServices %}
