---
title: Add a builtin gateway 
---

To get traffic from outside your mesh inside it (North/South) with {{site.mesh_product_name}} you can use 
a builtin gateway.

In the [quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/), traffic was only able to get in the mesh by port-forwarding to an instance of an app
inside the mesh.
This is not something that can be used in production and you need to set up a gateway to receive traffic external to the mesh.
In this guide you will add a gateway in front of the demo-app service to expose it publicly.

{% mermaid %}
---
title: service graph of the demo app with a builtin gateway on front
---
flowchart LR
  subgraph edge-gateway
    gw0(/ :8080)
  end
  demo-app(demo-app :5000)
  redis(redis :6379)
  gw0 --> demo-app 
  demo-app --> redis
{% endmermaid %}

## Prerequisites
- Completed [quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

## Start a gateway 

### Create a `MeshGatewayInstance` 

A [`MeshGatewayInstance`](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-k8s/) lets you configure the pods
that will run your gateway.

You can do so by running:

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: kuma-demo
spec:
  replicas: 2
  serviceType: LoadBalancer
  tags:
    kuma.io/service: edge-gateway
" | kubectl apply -f -
```

{% warning %}
Your kubernetes cluster needs to support LoadBalancer for this to work.
This may not be the case if you are running kubernetes locally with `kind` or `k3d`. 
{% endwarning %}

### Define a listener using `MeshGateway`

[`MeshGateway`](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin-listeners/) lets you define listeners for your gateway.

Here we will define a single HTTP listener on port 8080:

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: my-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        tags:
          port: http/8080
" | kubectl apply -f -
```

Notice how the selector selects the `kuma.io/service` tag of the previously defined `MeshGatewayInstance`.

Now that you have this running you can see gateway pods running:

```shell
$ kubectl get pods -n kuma-demo
NAME                            READY   STATUS    RESTARTS   AGE
redis-5fdb98848c-5tw62          2/2     Running   0          5m5s
demo-app-c7cd6588b-rtwlj        2/2     Running   0          5m5s
edge-gateway-66c76fd477-ncsp5   1/1     Running   0          18s
edge-gateway-66c76fd477-thxqj   1/1     Running   0          18s
```

You can then retrieve the public url for your gateway with:

```shell
export PROXY_IP=$(kubectl get svc --namespace kuma-demo edge-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP
```

You can check the gateway is running:

```shell
$ curl -v ${PROXY_IP}:8080
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> GET / HTTP/1.1
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

We can see a default response that says there are not routes configured.

## Define a route using `MeshHTTPRoute`

[`MeshHTTPRoute`](/docs/{{ page.version }}/policies/meshhttproute/) lets you define http routes inside your service mesh.
You can attach a route to an entire gateway or to a single listener by using the `targetRef.kind: MeshGateway` 

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
 name: edge-gateway-route
 namespace: {{site.mesh_namespace}} 
 labels:
   kuma.io/mesh: default
spec:
 targetRef:
   kind: MeshGateway
   name: my-gateway
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
         name: demo-app_kuma-demo_svc_5000
" | kubectl apply -f -
```

Now if we try to reach our gateway again: 
```shell
$ curl -v ${PROXY_IP}:8080
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

We see we're getting a forbidden error. This is because we do have permissions from the gateway to talk to our demo-app service.
Let's add a [`MeshTrafficPermission`](/docs/{{ page.version }}/policies/meshtrafficpermission):

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{ site.mesh_namespace }} 
  name: demo-app
spec:
  targetRef:
    kind: MeshService
    name: demo-app_kuma-demo_svc_5000
  from:
    - targetRef:
        kind: MeshService
        name: edge-gateway 
      default:
        action: Allow
" | kubectl apply -f -
```

You can check it works with:

```shell
curl -XPOST -v ${PROXY_IP}:8080/increment
*   Trying 127.0.0.1:8080...
* Connected to 127.0.0.1 (127.0.0.1) port 8080
> POST /increment HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 200 OK
< x-powered-by: Express
< content-type: application/json; charset=utf-8
< content-length: 42
< etag: W/"2a-gDIArbqhTz783Hls/ysnTwRRsmQ"
< date: Fri, 09 Feb 2024 10:24:33 GMT
< x-envoy-upstream-service-time: 6
< server: Kuma Gateway
<
* Connection #0 to host 127.0.0.1 left intact
{"counter":3265,"zone":"local","err":null}
```

See how now the demo-app responds.

## Securing your public endpoint with a certificate

We've exposed our application to a public endpoint thanks to our gateway.
However, we probably now want to add TLS to our endpoint.

### Create a certificate

For this demo we'll create a self-signed certificate:

```shell
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=${PROXY_IP}"
```


```shell
echo "
apiVersion: v1
kind: Secret
metadata:
  name: my-gateway-certificate
  namespace: {{ site.mesh_namespace }} 
  labels:
    kuma.io/mesh: default
data:
  value: "$(cat tls.key tls.cert | base64)"
type: system.kuma.io/secret
" | kubectl apply -f - 
```

Now let's update our gateway to use this certificate

```shell
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: my-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway
  conf:
    listeners:
      - port: 8080
        protocol: HTTPS
        tls:
          mode: TERMINATE
          certificates:
            - secret: my-gateway-certificate
        tags:
          port: http/8080
" | kubectl apply -f -
```

We can now check we can call the API using TLS:

```shell
$ curl -v -k https://127.0.0.1:8080/increment -XPOST
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
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=127.0.0.1
*  start date: Feb  9 10:49:13 2024 GMT
*  expire date: Feb  8 10:49:13 2025 GMT
*  issuer: CN=127.0.0.1
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://127.0.0.1:8080/increment
* [HTTP/2] [1] [:method: POST]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: 127.0.0.1:8080]
* [HTTP/2] [1] [:path: /increment]
* [HTTP/2] [1] [user-agent: curl/8.4.0]
* [HTTP/2] [1] [accept: */*]
> POST /increment HTTP/2
> Host: 127.0.0.1:8080
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/2 200
< x-powered-by: Express
< content-type: application/json; charset=utf-8
< content-length: 42
< etag: W/"2a-BZZq4nXMINsG8HLM31MxUPDwPXk"
< date: Fri, 09 Feb 2024 13:41:11 GMT
< x-envoy-upstream-service-time: 19
< server: Kuma Gateway
< strict-transport-security: max-age=31536000; includeSubDomains
<
* Connection #0 to host 127.0.0.1 left intact
{"counter":3271,"zone":"local","err":null}%
```

Note that we're using `-k` as we have used a self-signed certificate.

## Next steps

* Read more about the different types of gateways in the [managing ingress traffic docs](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/overview/).
* Learn about setting up [observability](/docs/{{ page.version }}/explore/observability/) to get full end to end visibility of your mesh.
