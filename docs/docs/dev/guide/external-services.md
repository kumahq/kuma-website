 
# External services
 
The main purpose of this guide is to get you familiar with the concept of [`ExternalServices`](../policies/external-services.md) in Kuma.
 
## Before you start
 
* Install Kuma following the [Standalone deployment instruction](../deployments/stand-alone.md/). Ensure to enable `ZoneEgress`.
* Get familiar with concept of [`ExternalServices`](../policies/external-services.md)
 
 
## Routing to ExternalService
 
1. (Kubernetes only) Create namespace with enabled sidecar injection.
 
```sh
echo "apiVersion: v1
kind: Namespace
metadata:
 name: kuma-demo
 namespace: kuma-demo
 labels:
   kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```
 
2. Create Mesh configuration with TLS
 
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
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
:::
::: tab "Universal"
```sh
echo "type: Mesh
name: default
mtls:
 enabledBackend: ca-1
 backends:
 - name: ca-1
   type: builtin" | kumactl apply -f -
:::
::::
 
3. Deploy client service with `kuma-dp` sidecar
 
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
 name: demo-client
 namespace: kuma-demo
spec:
 selector:
   matchLabels:
     app: demo-client
 template:
   metadata:
     labels:
       app: demo-client
   spec:
     containers:
       - name: app
         image: python:latest
         command: [ "python" ]
         args:
           - -m
           - http.server
         resources:
           limits:
             cpu: 50m
             memory: 128Mi' | kubectl apply -f -
```
:::
::: tab "Universal"
You need to deploy `kuma-dp` sidecar with a transparent proxy configured to get the best everything working. Follow the [instruction](../networking/transparent-proxying.md#universal) to start `kuma-dp` with transparent proxy.
:::
::::
 
4. Let's make a request to `https://example.com`
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
kubectl exec -it deployment/demo-client -n kuma-demo -c app -- curl https://example.com -I
```
:::
::: tab "Universal"
 
```sh
curl https://example.com -I
```
:::
::::
 
You should notice a response similar to this one:
 
```
HTTP/2 200
content-encoding: gzip
accept-ranges: bytes
[...]
```
 
5. Now let's disable [passthrough](../policies/mesh.md#controlling-the-passthrough-mode) mode and try the same request
 
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
 name: default
spec:
 networking:
   outbound:
     passthrough: false
 mtls:
   enabledBackend: ca-1
   backends:
   - name: ca-1
     type: builtin" | kubectl apply -f -
```
```sh
kubectl exec -it deployment/demo-client -n kuma-demo -c app -- curl https://example.com -I
```
:::
::: tab "Universal"
```sh
echo "type: Mesh
name: default
networking:
 outbound:
   passthrough: false
mtls:
 enabledBackend: ca-1
 backends:
 - name: ca-1
   type: builtin" | kumactl apply -f -
```
 
```sh
curl https://example.com -I
```
:::
::::
 
You should notice that the request doesn't work anymore.
 
6. We can add now the `ExternalService` definition and retry the same request
 
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: ExternalService
mesh: default
metadata:
 name: example
spec:
 tags:
   kuma.io/service: example
   kuma.io/protocol: tcp
 networking:
   address: example.com:443
   tls:
     enabled: false" | kubectl apply -f -
```
 
```sh
kubectl exec -it deployment/demo-client -n kuma-demo -c app -- curl https://example.com -I
```
 
:::
::: tab "Universal"
 
```sh
echo "type: ExternalService
mesh: default
name: example
tags:
 kuma.io/service: example
 kuma.io/protocol: tcp
networking:
 address: example.com:443
 tls:
   enabled: false" | kumactl apply -f -
 
```
 
```sh
curl https://example.com -I
```
 
:::
::::
 
Now request should return 200 and traffic goes through Envoy. In this configuration (`kuma.io/protocol: tcp` and `tls.enabled: false`) application itself is responsible for originating and verifying TLS and Envoy is just passing the connection to a proper destination.
 
It's possible to configure Envoy to be responsible for originating and verifying TLS. To make it happen update the `ExternalService` definition. You need `Base64` signed certificate to make validation correct.
 
::: tip
On Linux systems you can use `cat /etc/ssl/certs/<cert_name.pem> | base64 -w 0` and replace `<Base64 signed certificate in one line>` with returned value.
:::
 
:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: ExternalService
mesh: default
metadata:
 name: example
spec:
 tags:
   kuma.io/service: example
   kuma.io/protocol: http
 networking:
   address: example.com:443
   tls:
     enabled: true
     caCert:
       inline: <Base64 signed certificate in one line>" | kubectl apply -f -
```
 
Let's make a request to `example.mesh`:
 
```sh
kubectl exec -it deployment/demo-client -n kuma-demo -c app -- curl http://example.mesh -I
```
:::
::: tab "Universal"
 
```sh
echo "type: ExternalService
mesh: default
name: example
tags:
 kuma.io/service: example
 kuma.io/protocol: http
networking:
 address: example.com:443
 tls:
   enabled: true
   caCert:
     inline: <Base64 signed certificate in one line>" | kumactl apply -f -
```
 
Let's make a request to `example.mesh`:

```sh
curl http://example.mesh -I
```
:::
::::
 
Now Envoy is responsible for TLS origination and you should try to request the http service. You should notice that the request passed and the response looks similar to the one presented below.
 
```
HTTP/1.1 200 OK
content-encoding: gzip
accept-ranges: bytes
[...]
```
 
## What's happened?
 
In the beginning, communication was going through the `passthrough` cluster which allows communicating with any service. Later, you blocked using the `passthrough` cluster and after that operations requests to services outside of the cluster were not possible. After you've created the definition of `ExternalService` requests started to flow.
 