---
title: Use Kong as a delegated Gateway 
---

{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

To get traffic from outside your mesh inside it (North/South) with {{site.mesh_product_name}} you can use 
a delegated gateway.

In the [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/), traffic was only able to get in the mesh by port-forwarding to an instance of an app
inside the mesh.
In production, you typically set up a gateway to receive traffic external to the mesh.
In this guide you will add Kong as a [delegated gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/delegated/) in front of the demo-app service and expose it publicly.

<!-- vale Google.Headings = NO -->
{% mermaid %}
---
title: Service graph of the demo app with a Kong gateway on front
---
flowchart LR
  subgraph Kong Gateway 
    gw0(/ :80)
  end
  demo-app(demo-app :5050)
  kv(kv :5050)
  gw0 --> demo-app 
  demo-app --> kv
{% endmermaid %}
<!-- vale Google.Headings = YES -->

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo/) to set up a zone control plane with demo application

{% tip %}
If you are already familiar with quickstart you can set up required environment by running:

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ site.mesh_namespace }} \{% if version == "preview" %}
  --version {{ page.version }} \{% endif %}
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
kubectl wait -n {{ kuma-system }} --for=condition=ready pod --selector=app={{ kuma-control-plane }} --timeout=90s
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
```
{% endtip %}

## Install Kong ingress controller 

Follow the steps on the [Kong docs website](https://developer.konghq.com/kubernetes-ingress-controller/install/) to install the ingress controller.
You only need to install the controller (`helm install kong kong/ingress -n kong --create-namespace`) and enable the Gateway API.

{% warning %}
The Kubernetes cluster needs to support `LoadBalancer` for this to work.

If you are running `minikube` you will want to open a [tunnel](https://minikube.sigs.k8s.io/docs/handbook/accessing/#loadbalancer-access) with `minikube tunnel -p mesh-zone`.

You may not have support for `LoadBalancer` if you are running locally with `kind` or `k3d`.
When running `kind` cluster you can try [kubernetes-sigs/cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind).
{% endwarning %}

## Enable sidecar injection on the `kong` namespace

The Kong Ingress controller was installed outside the mesh.
For it to work as a delegated gateway restart it with [sidecar injection enabled](/docs/{{ page.release }}/production/dp-config/dpp-on-kubernetes/):

Add the label:
```sh
kubectl label namespace kong kuma.io/sidecar-injection=enabled
```

Restart both the controller and the gateway to leverage sidecar injection:
```sh
kubectl rollout restart -n kong deployment kong-gateway kong-controller
```

Wait until pods are fully rolled out and look at them:
```sh
kubectl get pods -n kong
```

It is now visible that both pods have 2 containers, one for the application and one for the sidecar.
```sh
NAME                              READY   STATUS    RESTARTS      AGE
kong-controller-675d48d48-vqllj   2/2     Running   2 (69s ago)   72s
kong-gateway-674c44c5c4-cvsr8     2/2     Running   0             72s
```

Retrieve the public url for the gateway with:
```sh
export PROXY_IP=$(kubectl get svc -n kong kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP
```

Verify the gateway still works:
```sh
curl -i $PROXY_IP
```

which outputs that there are no routes defined:
```sh
HTTP/1.1 404 Not Found
Date: Fri, 09 Feb 2024 15:25:45 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 103
X-Kong-Response-Latency: 0
Server: kong/3.5.0
X-Kong-Request-Id: e7dfe659c9e46639a382f82c16d9582f

{
  "message":"no Route matched with those values",
  "request_id":"e7dfe659c9e46639a382f82c16d9582f"
}%
```

## Add a route to our `demo-app`

Now add the gateway route in `kuma-demo` namespace which binds to the gateway `kong` defined in the `kong` namespace:
```sh
echo "apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: demo-app
  namespace: kuma-demo
spec:
  parentRefs:
  - name: kong
    namespace: kong
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: demo-app
      namespace: kuma-demo
      kind: Service
      port: 5050 " | kubectl apply -f -
```

{% warning %}
This route is managed by the Kong ingress controller and not by {{site.mesh_product_name}}.
{% endwarning %}

Now call the gateway: 
```sh
curl -i $PROXY_IP/
```

Which outputs:
```sh
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=UTF-8
Content-Length: 19
Connection: keep-alive
date: Fri, 09 Feb 2024 15:51:10 GMT
server: envoy
x-envoy-upstream-service-time: 0
X-Kong-Upstream-Latency: 2
X-Kong-Proxy-Latency: 0
Via: kong/3.5.0
X-Kong-Request-Id: 3b9d7d0db8c4cf25759d95682d6e3573

RBAC: access denied%
```

Notice the "forbidden" error.
The quickstart applies restrictive default permissions, so the gateway can't access the demo-app service.

To fix this, add a [`MeshTrafficPermission`](/docs/{{ page.release }}/policies/meshtrafficpermission):

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
          app.kubernetes.io/name: gateway
          k8s.kuma.io/namespace: kong
      default:
        action: Allow" | kubectl apply -f -
```

Now, call the gateway again:
```sh
curl -i $PROXY_IP/api/counter -XPOST
```

Notice that the call succeeds:
```sh
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 24
Connection: keep-alive
x-demo-app-version: v1
date: Thu, 29 May 2025 11:07:03 GMT
x-envoy-upstream-service-time: 59
server: envoy
X-Kong-Upstream-Latency: 81
X-Kong-Proxy-Latency: 1
Via: 1.1 kong/3.9.0
X-Kong-Request-Id: c63c57656349780c6b63191f80c85541

{"counter":1,"zone":""}
```

## Next steps

* Read more about the different types of gateways in the [managing ingress traffic docs](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/overview/).
* Learn about setting up [observability](/docs/{{ page.release }}/explore/observability/) to get full end to end visibility of your mesh.
