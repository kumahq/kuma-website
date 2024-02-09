---
title: Deploy Kuma on Kubernetes
---

To start learning how {{site.mesh_product_name}} works, you run and secure a simple demo application that consists of two services:

- `demo-app`: a web application that lets you increment a numeric counter. It listens on port 5000
- `redis`: data store for the counter


{% mermaid %}
---
title: service graph of the demo app
---
flowchart LR
demo-app(demo-app :5000)
redis(redis :6379)
demo-app --> redis
{% endmermaid %}


## Prerequisites
- [Helm](https://helm.sh/) - a package manager for Kubernetes
- [Kind](https://kind.sigs.k8s.io/) - a tool for running local Kubernetes clusters

## Start Kubernetes cluster

Start a new Kubernetes cluster on your local machine by executing:

```sh
kind create cluster --name=mesh-zone
```

{% tip %}
You can skip this step if you already have a Kubernetes cluster running.
It can be a cluster running locally or in a public cloud like AWS EKS, GCP GKE, etc.
{% endtip %}

## Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} control plane with Helm by executing:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{site.mesh_namespace}} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

## Deploy demo application

1.  Deploy the application
    ```sh
    kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
    kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
    ```

2.  Port-forward the service to the namespace on port 5000:

    ```sh
    kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
    ```

3.  In a browser, go to [127.0.0.1:5000](http://127.0.0.1:5000) and increment the counter.

The demo app includes the `kuma.io/sidecar-injection` label enabled on the `kuma-demo` namespace.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-demo
  labels:
    kuma.io/sidecar-injection: enabled
```

This means that {{site.mesh_product_name}} [already knows](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/) that it needs to automatically inject a sidecar proxy to every Kubernetes pod in the `kuma-demo` namespace.

## Explore GUI

You can view the sidecar proxies that are connected to the {{site.mesh_product_name}} control plane.

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default, the GUI listens on the API port which defaults to `5681`.

To access {{site.mesh_product_name}} we need to first port-forward the API service with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then navigate to [127.0.0.1:5681/gui](http://127.0.0.1:5681/gui) to see the GUI.

## Introduce zero-trust security

By default, the network is insecure and not encrypted. We can change this with {{site.mesh_product_name}} by enabling the [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) policy to provision a Certificate Authority (CA) that will automatically assign TLS certificates to our services (more specifically to the injected data plane proxies running alongside the services).

{% if_version gte:2.6.x %}
Before enabling [Mutual TLS](/docs/{{ page.version }}/policies/mutual-tls/) (mTLS) in your mesh, you need to create a `MeshTrafficPermission` policy that allows traffic between your applications.

{% warning %}
If you enable [mTLS](/docs/{{ page.version }}/policies/mutual-tls/) without a `MeshTrafficPermission` policy, all traffic between your applications will be blocked. 
{% endwarning %}

To create a `MeshTrafficPermission` policy, you can use the following command:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

This command will create a policy that allows all traffic between applications within your mesh. If you need to create more specific rules, you can do so by editing the policy manifest.
{% endif_version %}

We can enable Mutual TLS with a `builtin` CA backend by executing:

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

The traffic is now encrypted with mTLS and each service can reach any other service.

We can then restrict the traffic by default by executing:

```sh
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Deny" | kubectl apply -f -
```

At this point, the demo application should not function, because we blocked the traffic.
You can verify this by clicking the increment button again and seeing the error message in the browser
We can allow the traffic from the `demo-app` to `redis` by applying the following MeshTrafficPermission

```sh
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: redis
spec:
  targetRef:
    kind: MeshService
    name: redis_kuma-demo_svc_6379
  from:
    - targetRef:
        kind: MeshService
        name: demo-app_kuma-demo_svc_5000
      default:
        action: Allow" | kubectl apply -f -
```

You can click the increment button, the application should function once again.
However, the traffic to `redis` from any other service than `demo-app` is not allowed.

## Next steps

* Explore the [Features](/features) available to govern and orchestrate your service traffic.
* Add a gateway to access the demo from the outside by following the [builtin gateway guide](/docs/{{ page.version }}/guides/gateway-builtin/).
* Add Kong as gateway to access the demo from the outside by following the [delegated gateway guide](/docs/{{ page.version }}/guides/gateway-delegated/).
* [Federate](/docs/{{ page.version }}/guides/federate) zone into a multizone deployment.
* Read the [full documentation](/docs/{{ page.version }}/) to learn about all the capabilities of {{site.mesh_product_name}}.
{% if site.mesh_product_name == "Kuma" %}
* Chat with us at the official [Kuma Slack](/community) for questions or feedback.
{% endif %}
