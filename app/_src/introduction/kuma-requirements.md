---
title: Kuma Requirements
---

This page exposes the different requirements to run {{site.mesh_product_name}}.

## Architecture

{{site.mesh_product_name}} supports machines with `x86_64` and `arm64` architecture. 

## Kubernetes

{{site.mesh_product_name}} is validated against Kubernetes `1.27.x`, `1.23.x`. For the specific Kubernetes version refer to the {{site.mesh_product_name}} [Makefile](https://github.com/kumahq/kuma/blob/master/mk/dev.mk#L24-L25).

## Envoy

{% if_version lte:2.1.x %}
Versions of envoy supported are: `~1.22.0` which means `>=1.22.0` and `<1.23.0`.
{% endif_version %}
{% if_version gte:2.2.x %}
Versions of envoy supported are: `~1.25.0` which means `>=1.25.0` and `<1.26.0`.
{% endif_version %}
{% if_version gte:2.7.x %}
The lowest Envoy version we support is the Envoy shipped in the minor - 2 of Kuma. For example, in Kuma `2.7.x`, we support Envoy shipped in the Kuma `2.5.0`, which is version `1.28.0`.
{% endif_version %}
You can find the current version in the [version.sh](https://github.com/kumahq/kuma/blob/master/tools/releases/version.sh#L11) file.

## Sizing your control-plane

In short, a control-plane with 4vCPU and 2GB of memory will be able to accommodate more than 1000 data planes.

While it's really hard to give a precise number, a good rule of thumb is to assign about 1MB of memory per data plane.
When it comes to CPUs {{site.mesh_product_name}} handles parallelism extremely well (its architecture uses a lot of shared nothing go-routines) so more CPUs usually enable quicker propagation of changes.

That being said we highly recommend you to run your own load tests prior to going to production.
There are many ways to run workloads and deploy applications and while we test some of them, you are in the best place to build a realistic benchmark of what you do.

To see if you may need to increase your control-plane's spec, there are two main metrics to pay attention to:

- propagation time (xds_delivery): this is the time it takes between a change in the mesh and the dataplane receiving its updated configuration. Think about it as the "reactivity of your mesh".
- configuration generation time (xds_generation): this is the time it takes for the configuration to be generated.

For any large mesh using transparent-proxy it's highly recommended to use {% if_version lte:2.1.x %}[reachable-services](/docs/{{ page.version }}/networking/transparent-proxying#reachable-services){% endif_version %}{% if_version gte:2.2.x %}[reachable-services](/docs/{{ page.version }}/production/dp-config/transparent-proxying/#reachable-services){% endif_version %}.

You can also find tuning configuration in the {% if_version lte:2.1.x %}[fine-tuning](/docs/{{ page.version }}/documentation/fine-tuning){% endif_version %}{% if_version gte:2.2.x %}[fine-tuning](/docs/{{ page.version }}/production/upgrades-tuning/fine-tuning/){% endif_version %} section of the docs.

## Sizing your sidecar container on Kubernetes

When deploying Kuma on Kubernetes, the sidecar is deployed as a separate container, `kuma-sidecar`, in your `Pods`. By default it has the following resource requests and limits:

```yaml
resources:
    requests:
        cpu: 50m
        memory: 64Mi
    limits:
        cpu: 1000m
        memory: 512Mi
```

This configuration should be enough for most use cases. In some cases, like when you cannot scale horizontally or your service handles lots of concurrent traffic, you may need to change these values. You can do this using the {% if_version lte:2.1.x %}[`ContainerPatch` resource](/docs/{{ page.version }}/explore/dpp-on-kubernetes/#custom-container-configuration){% endif_version %}{% if_version gte:2.2.x %}[`ContainerPatch` resource](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/#custom-container-configuration){% endif_version %}. 

For example, you can modify individual parameters under `resources`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: {{site.mesh_namespace}}
spec:
  sidecarPatch:
    - op: add
      path: /resources/requests/cpu
      value: '"1"'
```

you could modify the entire `limits`, `request` or `resources` sections:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: {{site.mesh_namespace}}
spec:
  sidecarPatch:
    - op: add
      path: /resources/limits
      value: '{
        "cpu": "1",
        "memory": "1G"
      }'
```

Check {% if_version lte:2.1.x %}[the `ContainerPatch` documentation](/docs/{{ page.version }}/explore/dpp-on-kubernetes/#workload-matching){% endif_version %}{% if_version gte:2.2.x %}[the `ContainerPatch` documentation](/docs/{{ page.version }}/production/dp-config/dpp-on-kubernetes/#workload-matching){% endif_version %} for how to apply these resources to specific `Pods`.

{% tip %}
**Note**: When changing these resources, remember that they must be described using [Kubernetes resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes)
{% endtip %} 
