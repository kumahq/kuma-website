---
title: Kubernetes Gateway API
---

To get traffic from outside your mesh inside it (North/South) with {{site.mesh_product_name}} you can use
a builtin gateway.

In the [quickstart](/docs/{{ page.version }}/quickstart/kubernetes-demo/), traffic was only able to get in the mesh by port-forwarding to an instance of an app
inside the mesh.
In production, you typically set up a gateway to receive traffic external to the mesh.
In this guide you will add [a built-in gateway](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/builtin/) in front of the demo-app service and expose it publicly.
We will deploy and configure Gateway using [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).

Service graph of the demo app with a builtin gateway on front:
{% mermaid %}
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

## Install Gateway API CRDs

To install Gateway API please refer to [official installation instruction](https://gateway-api.sigs.k8s.io/guides/#install-standard-channel).

You also need to manually install {{site.mesh_product_name}} [GatewayClass](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/):

```sh
echo "apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma
spec:
  controllerName: gateways.kuma.io/controller" | kubectl apply -f -
```

At this moment, when you install Gateway API CRDs after installing {{site.mesh_product_name}} control plane you need to restart
it to start Gateway API controller. To do this run: 

```sh
kubectl rollout restart deployment {{site.mesh_product_name_path}}-control-plane -n {{ site.mesh_namespace }}
```

## Start a gateway

The [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) resource represents the proxy instance that handles
traffic for a set of Gateway API routes. You can create gateway with a single listener on port 8080 by running:

```sh
echo "apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kuma
  namespace: kuma-demo
spec:
  gatewayClassName: kuma
  listeners:
   - name: proxy
     port: 8080
     protocol: HTTP" | kubectl apply -f -
```

{% warning %}
The Kubernetes cluster needs to support `LoadBalancer` for this to work.

If you are running `minikube` you will want to open a [tunnel](https://minikube.sigs.k8s.io/docs/handbook/accessing/#loadbalancer-access) with `minikube tunnel -p mesh-zone`.

You may not have support for `LoadBalancer` if you are running locally with `kind` or `k3d`.
One option for `kind` is [kubernetes-sigs/cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind).
{% endwarning %}

You can now check if the gateway is running in the demo app `kuma-demo` namespace:
```sh
kubectl get pods -n kuma-demo
```
Observe the gateway pod:
```sh
NAME                       READY   STATUS    RESTARTS   AGE
demo-app-d8d8bdb97-vhgc8   2/2     Running   0          5m
kuma-cfcccf8c7-hlqz5       1/1     Running   0          20s
redis-5484ddcc64-6gbbx     2/2     Running   0          5m
```

Retrieve the public URL for the gateway with:
```sh
export PROXY_IP=$(kubectl get svc --namespace kuma-demo kuma -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP
```

Check the gateway is running:
```sh
curl -v ${PROXY_IP}:8080
```

Which outputs:
```sh
*   Trying 127.0.0.1:8080...
* Connected to 35.226.116.24 (35.226.116.24) port 8080
> GET / HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.7.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 404 Not Found
< content-length: 62
< content-type: text/plain
< vary: Accept-Encoding
< date: Mon, 04 Nov 2024 13:21:07 GMT
< server: Kuma Gateway
<
This is a Kuma MeshGateway. No routes match this MeshGateway!
* Connection #0 to host 35.226.116.24 left intact
```
Notice the gateway says that there are no routes configured.

## Define a route using `HTTPRoute`

[HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/) resources contain a set of matching criteria for HTTP 
requests and upstream `Services` to route those requests to.
```yaml
echo "apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: kuma-demo
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kuma
      namespace: kuma-demo
  rules:
    - backendRefs:
      - kind: Service
        name: demo-app
        port: 5000
        weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /" | kubectl apply -f -
```

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

To fix this, add a [`MeshTrafficPermission`](/docs/{{ page.version }}/policies/meshtrafficpermission):

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo 
  name: allow-gateway
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: demo-app
  from:
    - targetRef:
        kind: MeshSubset
        tags: 
          kuma.io/service: kuma_kuma-demo_svc 
      default:
        action: Allow" | kubectl apply -f -
```

Check it works with:
```sh
curl -XPOST -v ${PROXY_IP}:8080/increment
```

Now it returns a 200 OK response:
```sh
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
{"counter":1,"zone":"local","err":null}
```

## Securing your public endpoint with a certificate

The application is now exposed to a public endpoint thanks to the gateway.
We will now add TLS to our endpoint.

### Create a certificate

Create a self-signed certificate:

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=${PROXY_IP}"
```

Create Kubernetes secret with generated certificate:

```sh
echo "apiVersion: v1
kind: Secret
metadata:
  name: my-gateway-certificate
  namespace: kuma-demo
type: kubernetes.io/tls
data:
  tls.crt: "$(cat tls.crt | base64)"
  tls.key: "$(cat tls.key | base64)"" | kubectl apply -f - 
```

Now update the gateway to use this certificate:

```sh
echo "apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kuma
  namespace: kuma-demo
spec:
  gatewayClassName: kuma
  listeners:
    - name: proxy
      port: 8080
      protocol: HTTPS
      tls:
        certificateRefs:
          - name: my-gateway-certificate" | kubectl apply -f -
```

Check the call to the gateway:
```sh
curl -X POST -v --insecure https://${PROXY_IP}:8080/increment
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
{"counter":5,"zone":"local","err":null}%
```

Note that we're using `--insecure` as we have used a self-signed certificate.

## Next steps

* Further explore [Gateway API documentation](https://gateway-api.sigs.k8s.io/)
* Learn more about how to customize [{{site.mesh_product_name}} Gateway with Gateway API](/docs/{{ page.version }}/using-mesh/managing-ingress-traffic/gateway-api/) 
* Learn about setting up [observability](/docs/{{ page.version }}/explore/observability/) to get full end to end visibility of your mesh.