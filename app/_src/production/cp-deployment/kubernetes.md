---
title: Kubernetes
content_type: how-to
---

You can find instructions to install on kubernetes for {% if_version gte:2.6.x %}[single-zone](/docs/{{ page.version }}/production/cp-deployment/single-zone){% endif_version %}{% if_version lte:2.5.x %}[standalone](/docs/{{ page.version }}/production/cp-deployment/stand-alone){% endif_version %} or [multi-zone](/docs/{{ page.version }}/production/cp-deployment/multi-zone).
This page covers special steps for some Kubernetes distributions or version and some troubleshooting help.

## Helm

### Adding the {{site.mesh_product_name}} charts repository

To use {{site.mesh_product_name}} with Helm charts, add the [{{site.mesh_product_name}} charts repository]({{site.mesh_helm_repo_url}}) locally:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
```

You can fetch all following updates by running `helm repo update`.

### Helm config

You can find a full [reference of helm configuration](/docs/{{ page.version }}/reference/kuma-cp/#helm-valuesyaml).

You can also set any control-plane configuration by using the prefix: `{{ site.set_flag_values_prefix }}controlPlane.envVars.`. Find detailed explanations in the page: [control plane configuration](/docs/{{ page.version }}/documentation/configuration/#modifying-the-configuration).

### Argo CD

{{site.mesh_product_name}} zones require a certificate to verify a connection between the control plane and a data plane proxy.
{{site.mesh_product_name}} Helm chart autogenerate self-signed certificate if the certificate isn't explicitly set.
[Argo CD](https://argo-cd.readthedocs.io/en/stable/) uses `helm template` to compare and apply Kubernetes YAMLs.
Helm template doesn't work with chart logic to verify if the certificate is present.
This results in replacing the certificate on each Argo redeployment.
The solution to this problem is to explicitly set the certificates.
See ["Data plane proxy to control plane communication"](/docs/{{ page.version }}/production/secure-deployment/certificates/) to learn how to preconfigure {{site.mesh_product_name}} with certificates.

If you use [Argo Rollouts](https://argoproj.github.io/rollouts/) for blue-green deployment [configure the control plane](/docs/{{ page.version }}/documentation/configuration) with `KUMA_RUNTIME_KUBERNETES_INJECTOR_IGNORED_SERVICE_SELECTOR_LABELS` set to `rollouts-pod-template-hash`.
It will enable traffic shifting between active and preview Service without traffic interruption.

{% if_version gte:2.7.x %}
If you are using policies inside Argo managed entities you will want to workaround [argoproj/argo-cd#4764](https://github.com/argoproj/argo-cd/issues/4764).
To do so disable the mesh owner reference by setting `KUMA_RUNTIME_KUBERNETES_SKIP_MESH_OWNER_REFERENCE=true` in your control-plane configuration.
If you do this, deleting a mesh will not delete the resources that are attached to it.
{% endif_version %}

## Sidecars

Check [the notes on DP lifecycle for Kubernetes](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/#kubernetes-sidecar-containers)
for important considerations about sidecars with {{site.mesh_product_name}}.

### CNI

On Kubernetes there are two ways to redirect traffic to the sidecar:

- Init containers which need to run with elevated privileges.
- [CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) which requires a little extra setup.

To use the CNI you can use the detailed [instructions to configure the {{site.mesh_product_name}} CNI](/docs/{{ page.version }}/production/dp-config/cni/). 

## OpenShift

### Transparent proxy

Starting from version 4.1 OpenShift uses `nftables` instead of `iptables`.
So using init container for redirecting traffic to the proxy no longer works and you should use the [`kuma-cni`](/docs/{{ page.version }}/production/dp-config/cni/) instead.

### Webhooks on OpenShift 3.11

By default `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` are disabled on OpenShift 3.11.
In order to make it work add the following `pluginConfig` into `/etc/origin/master/master-config.yaml` on the master node:

```yaml
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
```

After updating `master-config.yaml` restart the cluster and install `control-plane`.

## GKE Autopilot

By default, GKE Autopilot forbids the use of the `NET_ADMIN` linux capability. This is required by Kuma to set up the iptables rules in order to intercept inbound and outbound traffic. 

It is possible to configure a GKE cluster in autopilot mode so that the `NET_ADMIN` capability is authorized with the following option in your gcloud command: `--workload-policies=allow-net-admin`

Full example:
```shell
gcloud beta container \
  --project ${GCP_PROJECT} \
  clusters create-auto ${CLUSTER_NAME} \
  --region ${REGION} \
  --release-channel "regular" \
  --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
  --network "projects/${GCP_PROJECT}/global/networks/default" \
  --subnetwork "projects/${GCP_PROJECT}/regions/${REGION}/subnetworks/default" \
  --no-enable-master-authorized-networks \
  --cluster-ipv4-cidr=/20 \
  --workload-policies=allow-net-admin
```
