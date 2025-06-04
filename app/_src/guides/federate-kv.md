---
title: Federate zone control plane
content_type: tutorial
---

{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

With {{site.mesh_product_name}} you can first start with just one zone control plane and then federate it to a multi-zone deployment.
This way you can:
- see your mesh deployment in one centralized place
- connect multiple zones and introduce cross zone connectivity
- manage policies that are pushed to all zones

## Prerequisites

- Completed [quickstart](/docs/{{ page.release }}/quickstart/kubernetes-demo-kv/) to set up a zone control plane with demo application
- Have [kumactl installed and in your path](/docs/{{ page.release }}/introduction/install/)

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

## Start a global control plane

### Start a new Kubernetes cluster

Currently, it's not possible to deploy global and zone control plane in the same Kubernetes cluster, therefore we need a new Kubernetes cluster.

{% tip %}
You can skip this step if you already have a Kubernetes cluster running.
It can be a cluster running locally or in a public cloud like AWS EKS, GCP GKE, etc.
{% endtip %}

```sh
minikube start -p mesh-global
```

### Setup the minikube tunnel

If you are using minikube for local testing, you can take advantage of the built-in minikube tunnel command. This command allows load balancer addresses to be provisioned using localhost.

{% tip %}
Using `nohup` will allow the tunnel to continue running should your current terminal session end. 
{% endtip %}

```sh
nohup minikube tunnel -p mesh-global &
```

### Deploy a global control plane

```sh
helm install --kube-context mesh-global --create-namespace --namespace {{site.mesh_namespace}} \
--set {{site.set_flag_values_prefix}}controlPlane.mode=global \
--set {{site.set_flag_values_prefix}}controlPlane.defaults.skipMeshCreation=true \
{{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

We skip default mesh creation as we will bring mesh from zone control plane in the next steps.

### Sync endpoint

Find and save the external IP and port of the `{{site.mesh_cp_zone_sync_name_prefix}}global-zone-sync` service in the `{{site.mesh_namespace}}` namespace:

```shell
export KDS_IP=$(kubectl --context mesh-global get svc -n {{site.mesh_namespace}} {{site.mesh_cp_zone_sync_name_prefix}}global-zone-sync -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

{% tip %}
If you are using minikube, you should use [`host.minikube.internal`](https://minikube.sigs.k8s.io/docs/handbook/host-access/) to ensure networking works correctly.

```sh
export KDS_IP=host.minikube.internal
```
{% endtip %}

## Copy resources from zone to global control plane

To federate zone control plane without any traffic interruption, we need to copy resources like secrets, meshes etc.
First, we need to expose API server of zone control plane:

```sh
kubectl --context mesh-zone port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

Then we export resources:
```sh
export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n {{site.mesh_namespace}} admin-user-token -o json | jq -r .data.value | base64 -d)
kumactl config control-planes add \
  --address http://localhost:5681 \
  --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
  --name "zone-cp" \
  --overwrite  
  
kumactl export --profile federation-with-policies --format kubernetes > resources.yaml
```

And finally, we apply resources on global control plane
```sh
kubectl apply --context mesh-global -f resources.yaml
```

## Connect zone control plane to global control plane

Update Helm deployment of zone control plane to configure connection to the global control plane.

```sh
helm upgrade --kube-context mesh-zone --namespace {{site.mesh_namespace}} \
--set {{site.set_flag_values_prefix}}controlPlane.mode=zone \
--set {{site.set_flag_values_prefix}}controlPlane.zone=zone-1 \
--set {{site.set_flag_values_prefix}}ingress.enabled=true \
--set {{site.set_flag_values_prefix}}controlPlane.kdsGlobalAddress=grpcs://${KDS_IP}:5685 \
--set {{site.set_flag_values_prefix}}controlPlane.tls.kdsZoneClient.skipVerify=true \
{{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

## Verify federation

To verify federation, first port-forward the API service from the global control plane to port 15681 to avoid collision with previous port forward. 

```sh
kubectl --context mesh-global port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 15681:5681
```

And then navigate to [127.0.0.1:15681/gui](http://127.0.0.1:15681/gui) to see the GUI.

You should eventually see
* a zone in list of zones
* policies including `kv` MeshTrafficPermission that we applied in the quickstart guide.
* data plane proxies for the demo application that we installed in the quickstart guide.

### Apply policy on global control plane

We can check policy synchronization from global control plane to zone control plane by applying a policy on global control plane:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshCircuitBreaker
metadata:
  name: demo-app-to-redis
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
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
      connectionLimits:
        maxConnections: 2
        maxPendingRequests: 8
        maxRetries: 2
        maxRequests: 2" | kubectl --context mesh-global apply -f -
```

If we execute the following command:
```sh
kubectl get --context mesh-zone meshcircuitbreakers -A
```
The policy should be eventually available in zone control plane
```
NAMESPACE     NAME                                                TARGETREF KIND   TARGETREF NAME
{{site.mesh_namespace}} demo-app-to-redis-65xb45x2xfd5bf7f        MeshService      demo-app_kuma-demo_svc_5000
{{site.mesh_namespace}} mesh-circuit-breaker-all-default          Mesh
```

## Next steps

* Read the [multi-zone](/docs/{{ page.release }}/production/cp-deployment/multi-zone) docs to learn more about this deployment model and cross-zone connectivity.
