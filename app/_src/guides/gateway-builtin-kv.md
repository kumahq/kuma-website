---
title: Add a builtin gateway 
---

To get traffic from outside your mesh inside it (North/South) with {{site.mesh_product_name}} you can use 
a builtin gateway.

In the [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/), traffic was only able to get in the mesh by port-forwarding to an instance of an app
inside the mesh.
In production, you typically set up a gateway to receive traffic external to the mesh.
In this guide you will add [a built-in gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin/) in front of the demo-app service and expose it publicly.

{% mermaid %}
<!-- vale Google.Headings = NO -->
---
title: service graph of the demo app with a builtin gateway on front
---
<!-- vale Google.Headings = YES -->
flowchart LR
  subgraph edge-gateway
    gw0(/ :8080)
  end
  demo-app(demo-app :5050)
  kv(`kv` :5050)
  gw0 --> demo-app 
  demo-app --> kv
{% endmermaid %}

## Prerequisites
- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application

{% tip %}
If you are already familiar with quickstart you can set up required environment by running:

{% if version == "preview" %}
```sh
helm install --create-namespace --namespace kuma-system kuma kuma/kuma --version {{ page.version }}
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% else %}
```sh
helm install --create-namespace --namespace kuma-system kuma kuma/kuma
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% endif %}
{% endtip %}

## Start a gateway 

### Create a `MeshGatewayInstance` 

A [`MeshGatewayInstance`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-k8s/) configures the pods
that will run the gateway.

Create it by running:
```sh
kubectl apply -f kuma-demo://kustomize/overlays/002-with-gateway/mesh-gateway-instance.yaml
```

{% warning %}
The Kubernetes cluster needs to support `LoadBalancer` for this to work.

If you are running `minikube` you will want to open a [tunnel](https://minikube.sigs.k8s.io/docs/handbook/accessing/#loadbalancer-access) with `minikube tunnel -p mesh-zone`.

You may not have support for `LoadBalancer` if you are running locally with `kind` or `k3d`.
One option for `kind` is [kubernetes-sigs/cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind) may be helpful.
{% endwarning %}

### Define a listener using `MeshGateway`

[`MeshGateway`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners/) defines listeners for the gateway.

Define a single HTTP listener on port 8080:

```sh
kubectl apply -f kuma-demo://kustomize/overlays/002-with-gateway/mesh-gateway.yaml
```

Notice how the selector selects the `kuma.io/service` tag of the previously defined `MeshGatewayInstance`.

Now look at the pods running in the namespace by running: 
```sh
kubectl get pods -n kuma-demo
```

Observe the gateway pod:
```sh
NAME                            READY   STATUS    RESTARTS   AGE
redis-5fdb98848c-5tw62          2/2     Running   0          5m5s
demo-app-c7cd6588b-rtwlj        2/2     Running   0          5m5s
edge-gateway-66c76fd477-ncsp5   1/1     Running   0          18s
```

Retrieve the public url for the gateway with:
```sh
export PROXY_IP=$(kubectl get svc --namespace kuma-demo edge-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP
```

Check the gateway is running:
```sh
curl -v ${PROXY_IP}:8080
```

Which outputs:
```sh
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> GET / HTTP/1.1ó
> Host: 127.0.0.1:8080
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 404 Not Found
< content-length: 62
< content-type: text/plain
< vary: Accept-Encoding
< date: Fri, 09 Feb 2024 10:07:26 GMT
< server: Kuma Gateway
<
This is a Kuma MeshGateway. No routes match this MeshGateway!
```
Notice the gateway says that there are no routes configured.

## Define a route using `MeshHTTPRoute`

[`MeshHTTPRoute`](/docs/{{ page.release }}/policies/meshhttproute/) defines HTTP routes inside your service mesh.
Attach a route to an entire gateway or to a single listener by using `targetRef.kind: MeshGateway` 

{% if_version lte:2.8.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
 name: edge-gateway-route
 namespace: {{site.mesh_namespace}} 
 labels:
   kuma.io/mesh: default
spec:
 targetRef:
   kind: MeshGateway
   name: edge-gateway
 to:
 - targetRef:
     kind: Mesh
   rules:
   - matches:
     - path:
         type: PathPrefix
         value: "/"
     default:
       backendRefs:
       - kind: MeshService
         name: demo-app_kuma-demo_svc_5000" | kubectl apply -f -
```
{% endif_version %}
{% if_version gte:2.9.x %}
{% if site.mesh_namespace != "kuma-system" %}
```sh
curl -s kuma-demo://kustomize/overlays/002-with-gateway/mesh-http-route.yaml | sed 's/kuma-system/{{ site.mesh_namespace }}/g' | kubectl apply -f -
```
{% else %}
```sh
kubectl apply -f kuma-demo://kustomize/overlays/002-with-gateway/mesh-http-route.yaml
```
{% endif %}
{% endif_version %}

Now try to reach our gateway again: 
```sh
curl -v ${PROXY_IP}:8080
```

which outputs:
```sh
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> GET / HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 403 Forbidden
< content-length: 19
< content-type: text/plain
< date: Fri, 09 Feb 2024 10:10:16 GMT
< server: Kuma Gateway
< x-envoy-upstream-service-time: 24
<
* Connection #0 to host 127.0.0.1 left intact
RBAC: access denied%
```

Notice the forbidden error.
This is because the quickstart has very restrictive permissions as defaults.
Therefore, the gateway doesn't have permissions to talk to the demo-app service.

To fix this, add a [`MeshTrafficPermission`](/docs/{{ page.release }}/policies/meshtrafficpermission):

```sh
kubectl apply -f kuma-demo://kustomize/overlays/002-with-gateway/mesh-traffic-permission.yaml
```

Which will create resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo 
  name: demo-app
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  from:
    - targetRef:
        kind: MeshSubset
        tags: 
          kuma.io/service: edge-gateway_kuma-demo_svc 
      default:
        action: Allow" | kubectl apply -f -
```

Check it works with:
```sh
curl -XPOST -v ${PROXY_IP}:8080/api/counter
```

Now returns a 200 OK response:
```sh
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> POST /api/counter HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK
< content-type: application/json; charset=utf-8
< x-demo-app-version: v1
< date: Thu, 29 May 2025 10:14:06 GMT
< content-length: 24
< x-envoy-upstream-service-time: 91
< server: Kuma Gateway
<
{"counter":1,"zone":""}
* Connection #0 to host 127.0.0.1 left intact
```

## Securing your public endpoint with a certificate

The application is now exposed to a public endpoint thanks to the gateway.
We will now add TLS to our endpoint.

### Create a certificate

Create a self-signed certificate:

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=${PROXY_IP}"
```


```sh
echo "apiVersion: v1
kind: Secret
metadata:
  name: my-gateway-certificate
  namespace: {{ site.mesh_namespace }} 
  labels:
    kuma.io/mesh: default
data:
  value: "$(cat tls.key tls.crt | base64)"
type: system.kuma.io/secret" | kubectl apply -f - 
```

Now update the gateway to use this certificate:
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway_kuma-demo_svc
  conf:
    listeners:
      - port: 8080
        protocol: HTTPS
        tls:
          mode: TERMINATE
          certificates:
            - secret: my-gateway-certificate
        tags:
          port: http-8080" | kubectl apply -f -
```

Check the call to the gateway: 
```sh
curl -X POST -v --insecure "https://${PROXY_IP}:8080/api/counter"
```

Which should output a successful call and indicate TLS is being used:
```sh
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256 / [blank] / UNDEF
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=127.0.0.1
*  start date: May 29 10:15:05 2025 GMT
*  expire date: May 29 10:15:05 2026 GMT
*  issuer: CN=127.0.0.1
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://127.0.0.1:8080/api/counter
* [HTTP/2] [1] [:method: POST]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: 127.0.0.1:8080]
* [HTTP/2] [1] [:path: /api/counter]
* [HTTP/2] [1] [user-agent: curl/8.7.1]
* [HTTP/2] [1] [accept: */*]
> POST /api/counter HTTP/2
> Host: 127.0.0.1:8080
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/2 200
< content-type: application/json; charset=utf-8
< x-demo-app-version: v1
< date: Thu, 29 May 2025 10:15:40 GMT
< content-length: 24
< x-envoy-upstream-service-time: 56
< server: Kuma Gateway
< strict-transport-security: max-age=31536000; includeSubDomains
<
{"counter":3,"zone":""}
* Connection #0 to host 127.0.0.1 left intact
```

Note that we're using `--insecure` as we have used a self-signed certificate.

## Next steps

* Read more about the different types of gateways in the [managing ingress traffic docs](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/overview/).
* Learn about setting up [observability](/docs/{{ page.release }}/explore/observability/) to get full end to end visibility of your mesh.
