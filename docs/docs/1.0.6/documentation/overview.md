# Overview

For high-level background and context, see [the introductory overview](docs/1.0.6/overview/what-is-kuma/) and the explanation of [how Kuma works with the sidecar proxy model](/docs/1.0.6/overview/why-kuma/).

Kuma includes the following components:

* `kuma-cp`: main Kuma executable that runs the control plane (CP).
* `kuma-dp`: Kuma data plane proxy executable, which invokes `envoy`. A set of `kuma-dp` proxies that share a single configuration comprises a data plane. 
* `envoy`: Envoy executable included in the Kuma archive.
* `kumactl`: CLI for managing Kuma (`kuma-cp`) and its data.
* `kuma-prometheus-sd`: helper tool that enables native integration with Prometheus. Enables `Prometheus` to automatically find all data planes in your Mesh and scrape metrics from them.
* `kuma-tcp-echo`: sample application that echos back requests, used for demo purposes.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data plane proxies (`kuma-dp`) that connect to the control plane when they start. 

After the `kuma-cp` process starts, it waits for [data plane proxies](../dps-and-data-model) to connect. It accepts user-defined configurations to create service meshes and apply Kuma [Policies](../../policies/introduction) to them.

High-level view of a typical Kuma installation:

<center>
<img src="/images/docs/0.4.0/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

And a more detailed view:

<center>
<img src="/images/docs/0.4.0/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**xDS APIs**: Kuma implements the [xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) APIs of Envoy in the `kuma-cp` application so that the Envoy DPs can connect to it and retrieve their configuration.
:::

Kuma supports two modes:

* `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
* `kubernetes`: when it's being deployed - well - on Kubernetes.

## Universal mode

When running in **Universal** mode, Kuma will require a PostgreSQL database to store its state. The PostgreSQL database and schema will have to be initialized accordingly to the installation instructions:

<center>
<img src="/images/docs/0.5.0/diagram-09.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

## Kubernetes mode

When running on **Kubernetes**, Kuma will store all of its state and configuration on the underlying Kubernetes API Server, therefore requiring no dependency to store the data. Kuma will automatically inject the dataplane proxy `kuma-dp` on any Pod that belongs to a Namespace that includes the following annotation:

```
kuma.io/sidecar-injection: enabled
```

You can learn more about sidecar injection in the section on [Dataplanes](./dps-and-data-model/#kubernetes).

<center>
<img src="/images/docs/0.5.0/diagram-08.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Specify Mesh for Pods

When deploying services in Kubernetes, you can determine which Mesh you want the service to be in by using the `kuma.io/mesh: $MESH_NAME` annotation. This annotation would be applied to a deployment like so:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        # indicate to Kuma that this Pod will be in a mesh called 'new-mesh'
        kuma.io/mesh: new-mesh
    spec:
      containers:
        ...
```

This `kuma.io/mesh` annotation also could be set in Namespace. In this case all Pods from the Namespace will belong to specified mesh.
 
### Matching Labels in `Pod` and `Service` 

When deploying Kuma on Kubernetes, you must ensure that every `Pod` is part of at least one matching `Service`. For example, in [Kuma's demo application](https://github.com/kumahq/kuma-demo/blob/master/kubernetes/), the [`Pod` for the Redis service](https://github.com/kumahq/kuma-demo/blob/master/kubernetes/kuma-demo-aio.yaml#L104)  has the following matchLabels:

```yaml
...
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
...
```

At least one of these labels must match the labels we define in our `Service`. The correct way to define the [corresponding Redis `Service`](https://github.com/kumahq/kuma-demo/blob/master/kubernetes/kuma-demo-aio.yaml#L133) would be as follows:

```yaml
kind: Service
metadata:
  name: redis
  namespace: kuma-demo
  labels:
    app: redis
    role: master
    tier: backend
```

::: tip
**Full CRD support**: When using Kuma in Kubernetes mode you can create [Policies](../../policies/introduction) with Kuma's CRDs applied via `kubectl`.
:::
