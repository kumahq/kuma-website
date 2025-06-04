---
title: Targeting MeshHTTPRoutes in supported policies
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane-workloads = kuma | append: "-control-plane-workloads" %}

In this guide, you’ll learn how to target [`MeshHTTPRoutes`]({{ docs }}/policies/meshhttproute/) in supported policies like `MeshTimeout`, `MeshRetry`, and `MeshAccessLog`. This lets you apply fine-grained traffic control to specific HTTP methods and paths instead of entire services.

## Prerequisites

{% capture familiarWithQuickstart %}
{% tip %}
If you're already familiar with the quickstart, you can set up the required environment by running:

```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace {{ site.mesh_namespace }} \{% if version == "preview" %}
  --version {{ page.version }} \{% endif %}
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
kubectl apply -f kuma-demo://k8s/001-with-mtls.yaml
kubectl port-forward svc/demo-app -n kuma-demo 5050:5050
```
{% endtip %}
{% endcapture %}

1. Completed [quickstart]({{ docs }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application

   {{ familiarWithQuickstart | indent }}

   To verify that the demo application is working, run:

   ```bash
   curl -XPOST localhost:5050/api/counter
   ```
   
   Expected response:
   
   ```json
   {"counter":1,"zone":""}
   ```

## MeshTimeout

### Limit request time from `demo-app` to `kv` to 1 second

By default, {{ Kuma }} allows a lot of time for requests, which isn't ideal for this guide. We'll shorten the timeout for requests from `demo-app` to `kv` to just 1 second.

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: demo-app-to-kv-meshservice
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshService
      name: kv
    default:
      http:
        requestTimeout: 1s' | kubectl apply -f -
```

Now, when you try to increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you should still see the expected response:

```json
{"counter":2,"zone":""}
```

### Add a MeshHTTPRoute to simulate a delay

Next, create a `MeshHTTPRoute` that targets `POST` requests from `demo-app` to the `/api/key-value/counter` endpoint of the `kv` service. This route simulates a 2-second delay in the response.

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshService
      name: kv
    rules:
    - matches:
      - path:
          type: Exact
          value: "/api/key-value/counter"
        method: POST
      default:
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            set:
            - name: x-set-response-delay-ms
              value: "2000"' | kubectl apply -f -
```

Now, when you try to increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you'll still get a reply, but this time it will fail with a timeout:

```json
{"instance":"524a3cfa480ad670520b646e0eaf8aa1","status":504,"title":"failed sending request","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```

This shows that the 2-second delay exceeds the 1-second timeout, resulting in a `504 Gateway Timeout`.

### Fix the timeout by updating MeshTimeout for the route

Fortunately, we can fix the timeout error by creating another `MeshTimeout` that increases the timeout just for the `MeshHTTPRoute` we created earlier.

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: demo-app-kv-api-meshhttproute
  namespace: kuma-demo
spec:
  to:
  - targetRef:
      kind: MeshHTTPRoute
      name: demo-app-kv-api
    default:
      http:
        requestTimeout: 3s' | kubectl apply -f -
```

Now, when you try to increase the counter again:

```bash
curl -XPOST localhost:5050/api/counter
```

after around 2 seconds, you should get the expected response:

```json
{"counter":3,"zone":""}
```

### Clean up timeout policies and remove the delay

Before moving on to the next steps that describe other policies, clean up the timeout settings and remove the simulated delay from the route.

```bash
kubectl delete meshtimeout demo-app-to-kv-meshservice -n kuma-demo
kubectl delete meshtimeout demo-app-kv-api-meshhttproute -n kuma-demo
```

Now update the `MeshHTTPRoute` to remove the delay filter:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshService
      name: kv
    rules:
    - matches:
      - path:
          type: Exact
          value: "/api/key-value/counter"
        method: POST' | kubectl apply -f -
```

Now, when you call the endpoint to increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you should get the expected response without any delay:

```json
{"counter":4,"zone":""}
```

## MeshAccessLog

### Log traffic using MeshAccessLog with MeshHTTPRoute as a target

You can use the `MeshAccessLog` policy to capture access logs for traffic that matches a specific `MeshHTTPRoute`. This is useful for logging only certain types of traffic, like specific HTTP methods or paths.

For example, the following policy will log `POST` requests from `demo-app` to the `/api/key-value/counter` endpoint of the `kv` service:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshHTTPRoute
      name: demo-app-kv-api
    default:
      backends:
      - type: File
        file:
          path: "/dev/stdout"' | kubectl apply -f -
```

Now, when you increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you should see a log line in the `kuma-sidecar` container of the `demo-app` pod:

```bash
kubectl logs -n kuma-demo -l app=demo-app -c kuma-sidecar
```

Example log output:

```
[2025-06-04T08:54:36.673Z] default "POST /api/key-value/counter HTTP/1.1" 200 - 28 15 2004 2004 "-" "Go-http-client/1.1" "-" "1f69806f-b476-4adc-b224-7450b3ca18fc" "kv.kuma-demo.svc.cluster.local:5050" "demo-app_kuma-demo_svc_5050" "kv" "10.42.0.7" "10.42.0.8:5050"
```

## MeshRetry

### Remove the default MeshRetry policy

To make the retry behavior easier to demonstrate, start by removing the default `MeshRetry` policy:

```bash
kubectl delete meshretry mesh-retry-all-default -n kuma-system
```

### Inject faults into the `kv` service

To simulate failures, create a `MeshFaultInjection` policy that causes 50% of the requests to the `kv` service to return a `503` error:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: kv-503
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  from:
  - targetRef:
      kind: Mesh
    default:
      http:
      - abort:
          httpStatus: 503
          percentage: 50' | kubectl apply -f -
```

To verify the fault injection, try increasing the counter a few times:

```bash
curl -XPOST localhost:5050/api/counter
```

At some point, you should see a `503` error response:

```json
{"instance":"3882f06ac30dac666a5f82e8ea3acfd8","status":503,"title":"failed sending request","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```

### Retry failed POST requests using MeshHTTPRoute

To handle these `503` errors, create a `MeshRetry` policy that targets the `MeshHTTPRoute` matching `POST` requests to `kv`:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: demo-app-kv-http
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshHTTPRoute
      name: demo-app-kv-api
    default:
      http:
        numRetries: 10
        retryOn:
        - "503"' | kubectl apply -f -
```

Now, when you increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you shouldn't see any more `503` errors. However, you might still encounter `500` errors:

```json
{"instance":"5b9c29b41ca20b3486e76bdd9affc880","status":500,"title":"failed to retrieve zone","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```

This happens because the `demo-app` also makes `GET` requests when increasing the counter, and our fault injection affects all requests to `kv`. Since the retry policy above only targets the `MeshHTTPRoute` (POST requests), the `GET` requests are not retried.

### Add a broader retry policy for all requests to `kv`

To fix this, add a more generic `MeshRetry` policy that targets all traffic from `demo-app` to the `kv` service:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: demo-app-kv
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
  - targetRef:
      kind: MeshService
      name: kv
    default:
      http:
        numRetries: 10
        retryOn:
        - 5xx' | kubectl apply -f -
```

Now, when you increase the counter:

```bash
curl -XPOST localhost:5050/api/counter
```

you shouldn't see any `500` errors either.

## What you've learned

In this guide, you have:

* Applied `MeshTimeout` policies targeting `MeshHTTPRoute` to customize request timeouts for specific HTTP traffic
* Used `MeshAccessLog` with a `MeshHTTPRoute` to log only matching requests
* Created `MeshRetry` policies scoped to both `MeshHTTPRoute` and `MeshService` to improve resiliency under failure
* Learned how policy scoping works and how to compose policies together to achieve precise traffic control

## Next steps

To continue learning:

* Explore more about [MeshHTTPRoute]({{ docs }}/policies/meshhttproute/) capabilities like header and query matching
* Try combining `MeshFaultInjection` with `MeshRetry` and `MeshTimeout` to simulate real failure scenarios
* Learn how other policies like `MeshCircuitBreaker` or `MeshRateLimit` can also be scoped to `MeshHTTPRoutes` (where supported) for granular control
