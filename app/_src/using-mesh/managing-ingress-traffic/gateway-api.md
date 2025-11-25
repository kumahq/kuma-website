---
title: Kubernetes Gateway API
description: Use Kubernetes Gateway API resources to configure built-in gateways and service-to-service routing with GAMMA.
keywords:
  - Gateway API
  - Kubernetes
  - GAMMA
---

{{site.mesh_product_name}} supports [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
for configuring {% if_version gte:2.6.x inline:true %}[built-in gateway](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin){% endif_version %}{% if_version lte:2.5.x inline:true %}[built-in gateway](/docs/{{ page.release }}/explore/gateway){% endif_version %} as well as traffic routing using the experimental
[GAMMA](https://gateway-api.sigs.k8s.io/contributing/gamma/)
[routing spec](https://gateway-api.sigs.k8s.io/geps/gep-1426/).

## Installation

{% if_version gte:2.9.x %}
Checkout our dedicated installation [guide](/docs/{{ page.release }}/guides/gateway-api).
{% endif_version %}

{% if_version lte:2.8.x %}
{% if_version lte:2.6.x %}
{% warning %}
{{ site.mesh_product_name }}'s [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) implementation is beta.
{% endwarning %}
{% warning %}
Gateway API [`Gateways`](https://gateway-api.sigs.k8s.io/api-types/gateway/) aren't supported in multi-zone. To use the builtin Gateway, you need to use the [`MeshGateway` resources](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners).
{% endwarning %}

1. Install the Gateway API CRDs.

   Kubernetes doesn't include Gateway API CRDs, [install them from the standard channel CRD bundle](https://gateway-api.sigs.k8s.io/guides/#install-standard-channel).

2. Enable Gateway API support.

   - With `kumactl`, use the `--experimental-gatewayapi` flag.
   - With Helm, use the `{{site.set_flag_values_prefix}}experimental.gatewayAPI=true` value.
{% endif_version %}
{% if_version gte:2.7.x %}
Kubernetes doesn't include Gateway API CRDs, [install them from the standard channel CRD bundle](https://gateway-api.sigs.k8s.io/guides/#install-standard-channel).
{% endif_version %}

{% if_version lte:2.2.x %}
## Usage
{% endif_version %}
{% if_version gte:2.3.x %}
## Gateways
{% endif_version %}

1. Install the [counter demo](https://github.com/kumahq/kuma-counter-demo).

   ```sh
   kumactl install demo --without-gateway | kubectl apply -f -
   ```

2. Add a [`Gateway`](https://gateway-api.sigs.k8s.io/api-types/gateway/).

   The `Gateway` resource represents the proxy instance that handles traffic for a set of Gateway API routes.

   Every `Gateway` refers to a [`GatewayClass`](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/).
   The `GatewayClass` represents the class of `Gateway`, in this case {{site.mesh_product_name}}'s builtin edge
   gateway, and points to a controller that should manage these `Gateways`. It can also hold
   [additional configuration](#customization).

{% capture gateway %}
{% tabs %}
{% tab usage Standard install %}

For Helm and `kumactl` installations, a `GatewayClass` named `kuma` is automatically installed
if the Gateway API CRDs are present.

{% endtab %}
{% tab usage Custom install %}

If you've installed {{site.mesh_product_name}} some other way, you can create your own `GatewayClass`
using the `controllerName: gateways.kuma.io/controller`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma
spec:
  controllerName: gateways.kuma.io/controller
```
{% endtab %}
{% endtabs %}
{% endcapture %}

{{ gateway | indent }}

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kuma
     namespace: kuma-demo
   spec:
     gatewayClassName: kuma
     listeners:
     - name: proxy
       port: 8080
       protocol: HTTP
   ```
   
   When a user applies a `Gateway` resource, {{site.mesh_product_name}} automatically creates a `Deployment` of built-in gateways with a corresponding `Service`.
   
   ```sh
   kubectl get pods -n kuma-demo
   ```
   
   ```
   NAME                          READY   STATUS    RESTARTS   AGE
   redis-59c9d56fc-6gcbc         2/2     Running   0          2m8s
   demo-app-5845d6447b-v7npw     2/2     Running   0          2m8s
   kuma-4j6wr-58998b5576-25wl6   1/1     Running   0          30s
   ```
   
   ```sh
   kubectl get svc -n kuma-demo
   ```
   
   ```
   NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
   redis        ClusterIP      10.43.223.223   <none>        6379/TCP         3m27s
   demo-app     ClusterIP      10.43.216.203   <none>        5000/TCP         3m27s
   kuma-pfh4s   LoadBalancer   10.43.122.93    172.20.0.3    8080:30627/TCP   87s
   ```
   
   The `Gateway` is now accessible using the external address `172.20.0.3:8080`.

3. Add an [`HTTPRoute`](https://gateway-api.sigs.k8s.io/api-types/httproute/).

   `HTTPRoute` resources contain a set of matching criteria for HTTP requests and upstream `Services` to route those requests to.

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
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
           value: /
   ```

   After creating an `HTTPRoute`, accessing `/` forwards a request to the demo app:

   ```sh
   curl 172.20.0.3:8080/ -i
   ```

   ```
   HTTP/1.1 200 OK
   x-powered-by: Express
   accept-ranges: bytes
   cache-control: public, max-age=0
   last-modified: Tue, 20 Oct 2020 17:16:41 GMT
   etag: W/"2b91-175470350a8"
   content-type: text/html; charset=UTF-8
   content-length: 11153
   date: Fri, 18 Mar 2022 11:33:29 GMT
   x-envoy-upstream-service-time: 2
   server: Kuma Gateway

   <html>
   <head>
   ...
   ```

### TLS termination

Gateway API supports TLS termination by using standard `kubernetes.io/tls` Secrets.

Here is an example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-tls
  namespace: kuma-demo
type: kubernetes.io/tls
data:
  tls.crt: "MIIEOzCCAyO..." # redacted
  tls.key: "MIIEowIBAAKC..." # redacted
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kuma
  namespace: kuma-demo
spec:
  gatewayClassName: kuma
  listeners:
  - name: proxy
    port: 8080
    hostname: test.kuma.io
    protocol: HTTPS
    tls:
      certificateRefs:
      - name: secret-tls
```

Under the hood, {{site.mesh_product_name}} CP copies the `Secret` to `{{site.mesh_namespace}}` namespace and converts it to [{{site.mesh_product_name}} secret](/docs/{{ page.release }}/production/secure-deployment/secrets/).
It tracks all the changes to the secret and deletes it upon deletion of the original secret.

{% endif_version %}
### Customization

Gateway API provides the `parametersRef` field on `GatewayClass.spec`
to provide additional, implementation-specific configuration to `Gateways`.
When using Gateway API with {{site.mesh_product_name}}, you can refer to a `MeshGatewayConfig` resource:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma
spec:
  controllerName: gateways.kuma.io/controller
  parametersRef:
    kind: MeshGatewayConfig
    group: kuma.io
    name: kuma
```

This resource has the same [structure as the `MeshGatewayInstance` resource](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-k8s)
except that the `tags` field is optional.
With a `MeshGatewayConfig` you can then customize
the generated `Service` and `Deployment` resources.

### Multi-mesh

You can specify a `Mesh` for `Gateway` and `HTTPRoute` resources
by setting the [`kuma.io/mesh` annotation](/docs/{{ page.release }}/reference/kubernetes-annotations#kumaiomesh)
Note that `HTTPRoutes` must also have the annotation to reference a
`Gateway` from a non-default `Mesh`.

### Cross-mesh

[Cross-mesh gateways](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners#cross-mesh) are supported with Gateway API.
You'll just need to create a corresponding `GatewayClass`
pointing to a `MeshGatewayConfig` that
sets `crossMesh: true`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma-cross-mesh
spec:
  controllerName: gateways.kuma.io/controller
  parametersRef:
    group: kuma.io
    kind: MeshGatewayConfig
    name: default-cross-mesh
---
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayConfig
metadata:
  name: default-cross-mesh
spec:
  crossMesh: true
```

and then reference it in your `Gateway`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kuma
  namespace: default
spec:
  gatewayClassName: kuma-cross-mesh
  listeners:
  - name: proxy
    port: 8080
    protocol: HTTP
```

### Multi-zone Deployments

{% if_version lte:2.6.x %}

Gateway API isn't supported with multi-zone deployments, use {{site.mesh_product_name}}'s [`MeshGateways`](/docs/{{ page.release }}/using-mesh/managing-ingress-traffic/builtin-listeners)/[`MeshHTTPRoute`](/docs/{{ page.release }}/policies/meshhttproute)/
[`MeshTCPRoute`](/docs/{{ page.release }}/policies/meshtcproute) instead.

{% endif_version %}
{% if_version gte:2.7.x %}

{% capture backendref-limitation %}
{% tip %}
**Important Note**:
This limitation exist because, {{site.mesh_product_name}} currently only allows referencing as `backendRefs` [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/).

This is a temporary limitation. [We're actively working on extending `backendRef` to support {{site.mesh_product_name}}'s `MeshServices`](https://github.com/kumahq/kuma/issues/9894). Once this feature is complete, you'll be able to reference services across different clusters within your mesh.
{% endtip %}
{% endcapture %}

{% capture backendref-limitation-environment %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                b2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Gateway
                listener(:8080)
            end
            subgraph Service
                b1(backend)
            end
        end
    end
{% endmermaid %}
{% endcapture %}

{% capture gapi_multizone_limitation_1 %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                backend2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Service
                backend1(backend)
            end
            subgraph Gateway
                listener(:8080)
            end
            subgraph HTTPRoute
                route1(/)
            end
            route1--"❌"-->backend2
            linkStyle 0 stroke:red,color:red,stroke-dasharray: 5 5;
            route1-->backend1
            listener-->route1
        end
    end
{% endmermaid %}
{% endcapture %}

{% capture gapi_multizone_limitation_2 %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                backend2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Gateway
                listener(:8080)
            end
            subgraph HTTPRoute
                route1(/)
            end
            subgraph Service
                backend1(backend)
            end
            route1--"❌"-->db
            linkStyle 0 stroke:red,color:red,stroke-dasharray: 5 5;
            listener-->route1
        end
    end
{% endmermaid %}
{% endcapture %}

The Gateway API supports multi-zone deployments, but with some limitations:

- Gateway API resources like `Gateway`, `ReferenceGrant`, and `HTTPRoute` must be created in non-global zones.

- Only services deployed within the same Kubernetes cluster, such as the `HTTPRoute`, can be referenced via `backendRef`.

   {{ backendref-limitation | indent }}

   To better visualize this limitation here's an example scenario that describes how you could configure multi-zone deployments with the Gateway API. In this example, you have the following resources:

   - Two zones (`zone-1` and `zone-2`) in separate Kubernetes clusters

   - Gateway with listener on port `8080` deployed in `zone-1`

   - Two services:

      - A service named `backend` deployed in each zone 

      - A service named `db` deployed only in `zone-2`

   {{ backendref-limitation-environment | indent }}

   If you deploy multi-zone with Gateway API, the following will occur:

   - If you create an `HTTPRoute` with a `backendRef` targeting the `backend` service in `k8s-cluster-1`, it will only route traffic to the `backend` service in `k8s-cluster-1`.
     
     {{ gapi_multizone_limitation_1 | indent }}

   - Similarly, if you create an `HTTPRoute` with a `backendRef` pointing to the `db` service in `k8s-cluster-1`, it will result in a `HTTPRoute` with a `ResolvedRefs` status condition of `BackendNotFound` because service `db` is not present in `k8s-cluster-1`.

     {{ gapi_multizone_limitation_2 | indent }}

{% endif_version %}

{% if_version gte:2.3.x %}

## Service to service routing

{{site.mesh_product_name}} also supports routing between services with
`HTTPRoute` in conformance with
[the GAMMA specifications](https://gateway-api.sigs.k8s.io/geps/gep-1426/).

GAMMA is a Gateway API subproject focused on mesh implementations of Gateway API
and extending the Gateway API resources to mesh use cases.

{% if_version lte:2.6.x %}
{% warning %}
GAMMA in {{site.mesh_product_name}} is **experimental**!
{% endwarning %}
{% endif_version %}

The key feature of `HTTPRoute` for mesh routing is specifying a Kubernetes
`Service` as the `parentRef`, as opposed to a `Gateway`.
All requests to this `Service` are then filtered and routed as specified in the
`HTTPRoute`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-demo-app
  namespace: kuma-demo
spec:
  parentRefs:
  - name: demo-app
    port: 5000
    kind: Service
  rules:
  - backendRefs:
    - name: demo-app-v1
      port: 5000
    - name: demo-app-v2
      port: 5000
```

The namespace of the `HTTPRoute` is key. If the route's namespace and the
`parentRef`'s namespace are identical, {{site.mesh_product_name}} applies
the route to _requests from all workloads_.
If the route's namespace differs from its `parentRef`'s namespace,
the `HTTPRoute` applies only to requests
_from workloads in the route's namespace_.

{% tip %}
Remember to tag your `Service` ports with `appProtocol: http` to use
them in an `HTTPRoute`!
{% endtip %}

{% warning %}
Because of [how Kuma maps resources](#how-it-works) at the moment,
the combination of the `HTTPRoute`s name and namespace and
the parent `Service` name and namespace must be no more than 249 characters.
{% endwarning %}

{% endif_version %}

## How it works

{{site.mesh_product_name}} includes controllers that reconcile Gateway API CRDs and convert them into the corresponding {{site.mesh_product_name}} CRDs.
This is why in the GUI, {{site.mesh_product_name}} `MeshGateways`/{% if_version lte:2.6.x inline:true %}`MeshGatewayRoutes`/{% endif_version %}`MeshHTTPRoutes`/`MeshTCPRoutes` are visible and not Kubernetes Gateway API resources.

Kubernetes Gateway API resources serve as the source of truth for {{site.mesh_product_name}} gateways and routes.
Any edits to the corresponding {{site.mesh_product_name}} resources are overwritten.
