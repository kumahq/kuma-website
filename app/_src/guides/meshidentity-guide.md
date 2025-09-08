---
title: Issuing Identity with MeshIdentity
---

{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}
{% assign kuma-system = site.mesh_namespace | default: "kuma-system" %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma-control-plane = kuma | append: "-control-plane" %}

The [MeshIdentity](TODO) allows you to issue identity for selected data planes. This approach is [Spiffe](https://spiffe.io/docs/latest/spiffe-about/overview/) compliant and can
be used with Spire. In this guide we will take a look on how to issue identities using bundled provider.

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
helm install --create-namespace --namespace {{ kuma-system }} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

### Deploy demo application

1.  Deploy the application
    ```sh
    kubectl apply -f kuma-demo://k8s/000-with-kuma.yaml
    kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
    ```

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

* **Identity** - (Who a workload is) - A workload's identity is expressed as a [SPIFFE ID](https://spiffe.io/docs/latest/spiffe-about/overview/) (the name encoded in its certificate’s Subject Alternative Name).
* **Trust** - (Who to believe) - Trust defines which identities you accept as valid, and is established through trusted 
  certificate authorities (CA) that issue those identities. Trust is attached to trust domain, and there can be multiple Trusts in the cluster.

## Issuing Identity

In {{ Kuma }} we have `MeshIdentity` resource responsible for managing identity. To issue new identity in Mesh,
we need to create resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity
  namespace: {{ kuma-system }}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: '{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}'
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true" | kubectl apply -f -
```

Let's take a closer look at resource we've just applied. MeshIdentity uses `selector` field to select data planes for 
which identity should be issued. In our example, identity will be issued for all data planes in Mesh.

Next is `spiffeID` field. This field contains templates for building spiffeID for our workloads. In this example we will build
trust domain from Mesh name, zone name and `.mesh.local` suffix. Path for spiffeID will be built from namespace and service account name.
Example spiffeID will look like this `spiffe://default.default.mesh.local/ns/kuma-demo/sa/default`. 

Last thing we see in this example is `provider` field. This field contains configuration specific to identity provider. 
In this guide we will be working with `Bundled` provider, but you can also configure Spire provider. This configuration will
enable MeshTrust generation, allow self-signed certificates, and will set cert expiry time to 24 h.

### Inspecting trust configuration

This `MeshIdentity` will create `MeshTrust` resource for us. We can check if it was created by running:

```sh
kubectl get meshtrusts -n {{ kuma-system }}
```

You should get a similar response:

```
NAME       AGE
identity   45s
```

We can now take closer look at the `MeshTrust` resource that was generated. We can get full resource by running:

```sh
kubectl get meshtrust identity -n {{ kuma-system }} -oyaml
```

Generated `MeshTrust` resource should look like this:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  labels:
    kuma.io/env: kubernetes
    kuma.io/mesh: default
    kuma.io/origin: zone
    kuma.io/zone: default
  name: identity
  namespace: {{ kuma-system }}
spec:
  caBundles:
  - pem:
      value: |
        -----BEGIN CERTIFICATE-----
        MIIDgzCCAmugAwIBAgIRAO8psy2B4YbbzSvhSaRYTlMwDQYJKoZIhvcNAQELBQAw
        QzENMAsGA1UEChMES3VtYTENMAsGA1UECxMETWVzaDEjMCEGA1UEAxMaZGVmYXVs
        dC5kZWZhdWx0Lm1lc2gubG9jYWwwHhcNMjUwOTAyMTMxMjA4WhcNMzUwODMxMTMx
        MjE4WjBDMQ0wCwYDVQQKEwRLdW1hMQ0wCwYDVQQLEwRNZXNoMSMwIQYDVQQDExpk
        ZWZhdWx0LmRlZmF1bHQubWVzaC5sb2NhbDCCASIwDQYJKoZIhvcNAQEBBQADggEP
        ADCCAQoCggEBAOERv23rg9mmNdNu2pULOMD5/5IwW7SW9WFdfEYtpuM8OxnpLOZl
        HQo7ZnPhPbpvqNYz8wpgZmOD3zMu4PT2W+Rdv/qC4wSbY1kCrFxbcc88sjmRFVJm
        1fQFgzcu91IZn4cWo7XpNA7a1t46kzAiM5oz6WsLcZ76AhG/A82L60z/k1wvFqMK
        aORPysIMLLEBs1A09iuzqvlp+7iv8BiAVgu3KD1RX5mSOyg91U/g1XhzOrHV1WY5
        VoSs9l6mbJDeVdlaLC5wQzD4E71XWpqnHXxjG695vhxMZLqHIuyxt4WXKEF78ma/
        1V5k/Sc7nUHmFBT1a0B6XCDvzdqGJYa58+sCAwEAAaNyMHAwDgYDVR0PAQH/BAQD
        AgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFIrDUs8m5iAB+f9Jx4gFC7e4
        hKlBMC4GA1UdEQQnMCWGI3NwaWZmZTovL2RlZmF1bHQuZGVmYXVsdC5tZXNoLmxv
        Y2FsMA0GCSqGSIb3DQEBCwUAA4IBAQDZvq4Pz7VxscfP+DkqNJDMKMidbaEnPbac
        nr5RG2YJ4+HuGakvHLc7Of8a3FSYAQX2cgjRrGLAnsC7zrOxYT3kEuXZzbQ545rw
        eZp9I6AdTa5fd0G9vnmUDkJnpQNDg0Ao/vJfv0hSmouJrkp9yvuR0VkLrMSkRUN+
        rHdPHVlnEBDRsZv8a1/ShVffF5mmdX5qifw35Iv+owS+ATWfhOO3nvOMKR4tY9qb
        aZ/Vckmai7QO4BhGUiVnhUdPQCWqQoxE3h8+kMD9BL1Vxpi8uXpLmQpi8HQbaBKO
        lahgDp2cp52Edw5luev1Vx/y23R5F6gxyO1h1lX7mb5qV8PoK0WE
        -----END CERTIFICATE-----
    type: Pem
  origin:
    kri: kri_mid_default_default_{{ kuma-system }}_identity_
  trustDomain: default.default.mesh.local
```

In the generated MeshTrust we can see `caBundle` that was generated by the control plane and trust domain created based on
template from `MeshIdentity` resource. We also have generated `trustDomain`, and `origin` which specifies KRI (Kuma Resource Identifier) 
of MeshIdentity used to generate this trust. 

### MeshIdentity in GUI

In the GUI when you open Mesh view, you will see new sections with `MeshIdentity` and `MeshTrust`, where you can inspect these resources.

<center>
<img src="/assets/images/guides/meshidentity/gui-mi.png" alt="Data Plane Proxies Stats metric for inbound_POD_IP_6379.rbac.allowed"/>
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

To allow traffic in `kuma-demo` we need to create MeshTrafficPermission. Apply this:

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
              value: spiffe://default.default.mesh.local/ns/kuma-demo" | kubectl apply -f -
```

This MeshTrafficPermission uses rules API with spiffeID matching. This policy will allow all traffic from workloads which spiffeID starts with:
`spiffe://default.default.mesh.local/ns/kuma-demo`. This spiffeID is based on template from MeshIdentity we've created earlier, every workload in `default` Mesh.
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

We've learned how to issue identity with MeshIdentity. Also, we've seen how MeshTrust is generated based on MeshIdentity. 
On top of that, we've seen how to allow traffic using MeshTrafficPermission with spiffeID matchers.

## Next steps

- Read more about [MeshIdentity](TODO) and [MeshTrust](TODO)
- Explore [MeshTrafficPermission with spiffeID matchers](TODO)
