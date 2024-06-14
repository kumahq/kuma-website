---
title: MeshExternalService
---

{% warning %}
Do **not** combine with [External Service](/docs/{{ page.version }}/policies/external-services).
{% endwarning %}

This resource allows services running inside the mesh to consume services that are not part of the mesh.
The `MeshExternalService` resource allows you to declare external resources instead of relying on [MeshPassthrough](/docs/{{ page.version }}/policies/meshpassthrough) or [passthrough mode](/docs/{{ page.version }}/networking/non-mesh-traffic#outgoing).
In contrast to passthrough `MeshExternalService` behaves like a normal service as if it was part of the mesh.

{% warning %}
Currently `MeshExternalService` resource does not support targeting by [targetRef policies](/docs/{{ page.version }}/policies/targetref).
This limitation will be lifted in the next release.
{% endwarning %}

## Configuration

### Match

This section specifies the rules for matching traffic that will be routed to external resources defined in `endpoints` section.
The only `type` supported is `HostnameGenerator` and it means that it will match traffic directed to a hostname created by the hostname generator.
The `port` field when omitted means that all traffic will be matched.
Protocols that are supported are: `tcp`, `grpc`, `http`, `http2`.

```yaml
match:
  type: HostnameGenerator
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
      secret: "123"
```

### DNS setup

To be able to access `MeshExternalService` via a hostname you need to define a [HostnameGenerator](/docs/{{ page.version }}/policies/hostnamegenerator) with a `meshExternalService` selector.

## Examples

For the following examples the following `HostnameGenerator` will be used:

{% policy_yaml hostnamegenerator %}
```yaml
type: HostnameGenerator
name: example
mesh: default
spec:
  selector:
    meshExternalService:
      matchLabels: {}
  template: "{{ .Name }}.mesh"
```
{% endpolicy_yaml %}

### TCP

{% policy_yaml tcp %}
```yaml
apiVersion: kuma.io/v1alpha1
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

```bash
echo 'echo this' | nc -q 3 mes-tcp.mesh 4242
```

### TCP with TLS

{% policy_yaml tcp-tls %}
```yaml
apiVersion: kuma.io/v1alpha1
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

```bash
echo 'echo this' | nc -q 3 mes-tcp-tls.mesh 4243
```

### TCP with mTLS

{% policy_yaml tcp-mtls %}
```yaml
apiVersion: kuma.io/v1alpha1
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

```bash
echo 'echo this' | nc -q 3 mes-tcp-mtls.mesh 4244
```

### HTTP

{% policy_yaml http %}
```yaml
apiVersion: kuma.io/v1alpha1
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

```bash
curl http://mes-http.mesh
```

### HTTPS

{% policy_yaml https %}
```yaml
apiVersion: kuma.io/v1alpha1
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
      port: 80
  tls:
    enabled: true
    verification:
      serverName: httpbin.org
```
{% endpolicy_yaml %}

```bash
curl http://mes-https.mesh
```

### gRPC

{% policy_yaml grpc %}
```yaml
apiVersion: kuma.io/v1alpha1
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

```bash
grpcurl -plaintext -v mes-grpc.mesh:9000 list
```

### gRPCS

{% policy_yaml grpcs %}
```yaml
apiVersion: kuma.io/v1alpha1
type: MeshExternalService
name: mes-grpcs
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9000
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9000
  tls:
    enabled: true
    verification:
      serverName: grpcbin.test.k6.io
```
{% endpolicy_yaml %}

```bash
grpcurl -plaintext -v mes-grpcs.mesh:9001 list # this is using plaintext because Envoy is doing TLS origination
```

## All policy configuration settings

{% json_schema MeshExternalServices %}
