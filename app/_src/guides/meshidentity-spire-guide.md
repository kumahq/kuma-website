---
title: Issuing Identity with MeshIdentity bundled provider
---

{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

{% warning %}
This is a guide for experimental feature. 
{% endwarning %}

The [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity) allows you to manage identity for selected data planes.
In this guide we will take a look on how to issue identities using [Spire](https://spiffe.io/docs/latest/spire-about/) provider and how to use them encrypt traffic
in mesh.

## Prerequisites

Before you begin, make sure you have the following tools installed:

* [Helm](https://helm.sh/) – used to install and manage Kubernetes applications
* [minikube](https://minikube.sigs.k8s.io/docs/) – used to run a local Kubernetes cluster for testing

### Start a Kubernetes cluster

Start a local Kubernetes cluster using minikube. The `-p` flag creates a new profile named `mesh-zone`:

```bash
minikube start -p mesh-zone
```

{% tip %}
If you already have a running Kubernetes cluster, either locally or in the cloud (for example, EKS, GKE, or AKS), you can skip this step.
{% endtip %}

### Install {{ Kuma }}

Install {{site.mesh_product_name}} control plane with Helm by executing:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{ kuma-system }} \
  --set "{{site.set_flag_values_prefix}}controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_SPIRE_ENABLED=true" \
  {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

We need to enable Kubernetes Spire injector on control plane for Spire support to work.

<!-- vale Google.Headings = NO -->
### Install Spire
<!-- vale Google.Headings = YES -->

Install Spire CRDs:

```sh
helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
 --repo https://spiffe.github.io/helm-charts-hardened/
```

Install Spire with custom trust domain `default.local-zone.mesh.local`. We will use this trust domain in next steps to configure 
MeshIdentity

```sh
helm upgrade --install -n spire spire spire \
 --repo https://spiffe.github.io/helm-charts-hardened/ \
 --set "global.spire.trustDomain=default.local-zone.mesh.local" \
 --set "global.spire.tools.kubectl.tag=v1.31.11"
```

### Configure Spire to issue identities in kuma-demo namespace

We need to configure Spire to issue identities in `kuma-demo` namespace. 

```sh
echo "apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: spire-registration
spec:
  podSelector:
    matchLabels:
      kuma.io/mesh: default
  spiffeIDTemplate: '{% raw %}spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}{% endraw %}'
  workloadSelectorTemplates:
    - 'k8s:ns:kuma-demo'" | kubectl apply -f -
```

We specify SpiffeID template that will use our configured trust domain, namespace and [service account](https://kubernetes.io/docs/concepts/security/service-accounts/) name.


### Deploy demo application

1.  Deploy the application
    ```sh
    kubectl apply -f kuma-demo://k8s/000-with-kuma.yaml
    kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
    ```

{% warning %}
For the `MeshIdentity` to work you need to have `meshServices.mode: Exclusive` set on Mesh resource. It is already configured
in demo.
{% endwarning %}


2.  Port-forward the service to the namespace on port 5000:

    ```sh
    kubectl port-forward svc/demo-app -n kuma-demo 5050:5050
    ```

3. Try making requests to demo-app
   ```sh
   curl -XPOST localhost:5050/api/counter
   ```
   You should see similar results:
   ```
   {"counter":1,"zone":""}
   ```

## Concepts

In {{ Kuma }} we define two concepts around identity that need to be well understood:

* **Identity** - Who a workload is - A workload's identity is the name encoded in its certificate, and this identity is considered valid only if the certificate is signed by a Trust.
* **Trust** - Who to believe - Trust defines which identities you accept as valid, and is established through trusted
  certificate authorities (CAs) that issue those identities. Trust is attached to trust domain, and there can be mutliple Trusts in the cluster.

## Issuing Identity

In {{ Kuma }} we have `MeshIdentity` resource responsible for managing identity. In our scenario Spire is responsible for 
issuing identity and managing trust, but we still need to create `MeshIdentity` to configure data plane to use identity 
managed by Spire.

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-spire
  namespace: kuma-system
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: default.local-zone.mesh.local
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Spire
    spire: {}" | kubectl apply -f -
```

Let's take a closer look at resource we've just applied. `MeshIdentity` uses `selector` field to select data planes for 
which identity should be issued. In our example, identity will be issued for all data planes in Mesh.

Next is `spiffeID` field. This field contains templates for building spiffeID for our workloads. In this example we
need to use the same trust domain that we configured in Spire: `default.local-zone.mesh.local` with path that will be 
dynamically created from namespace and service account name.
Example spiffeID will look like this `spiffe://default.local-zone.mesh.local/ns/kuma-demo/sa/default`. 

Last thing we see in this example is `provider` field. This field contains configuration specific to identity provider. 
We just need to specify `Spire` as a provider type.

### MeshIdentity in GUI

In the GUI when you open Mesh view, you will see new sections with `MeshIdentity` and `MeshTrust`, where you can inspect these resources.

<center>
<img src="/assets/images/guides/meshidentity/mi-spire.png" alt="Data Plane Proxies Stats metric for inbound_POD_IP_6379.rbac.allowed"/>
</center>

### Testing connectivity with MeshIdentity

We can now make some requests to our demo-app:

```sh
curl -XPOST localhost:5050/api/counter
```

We should see errors like this:

```
{"instance":"d11ee97a4b45ff3a7b59091d1612b7f7","status":500,"title":"failed to retrieve zone","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```

Since we issued identity for our workloads, mTLS was also configured. Zero trust is default behavior in this situation, and because
we don't have any `MeshTrafficPermission` configured we see these errors.

### Allowing traffic in kuma-demo namespace

To allow traffic in `kuma-demo` we need to create `MeshTrafficPermission`. Apply this:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: mtp
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
spec:
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.local-zone.mesh.local/ns/kuma-demo" | kubectl apply -f -
```

This `MeshTrafficPermission` uses rules API with spiffeID matching. This policy will allow all traffic from workloads which spiffeID starts with:
`spiffe://default.local-zone.mesh.local/ns/kuma-demo`. This spiffeID is based on template from `MeshIdentity` we've created earlier, every workload in `default` Mesh.
and in `kuma-demo` namespace will have spiffeID with this prefix. In the future if you want to be more specific you can 
allow only workloads matching its `exact` spiffeID. 

We can now try if traffic works. Run: 

```sh
curl -XPOST localhost:5050/api/counter
```

You should see something similar to:

```
{"counter":3,"zone":""}
```

## What you've learned

We've learned how to issue identity with Spire and `MeshIdentity`. Also, we've seen how to allow traffic using `MeshTrafficPermission` with spiffeID matchers.

## Next steps

- Read more about [MeshIdentity](/docs/{{ page.release }}/policies/meshidentity)
- Explore [MeshTrafficPermission with spiffeID matchers](/docs/{{ page.release }}/policies/meshtrafficpermission_experimental)
