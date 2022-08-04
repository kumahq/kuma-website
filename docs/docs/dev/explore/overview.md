# Overview

This sections gives an overview of a Kuma service mesh.
It also covers how to start integrating your services into your mesh.

A Kuma mesh is made up of two main components:

- **Data plane**: The data plane consists of the data plane proxies that run alongside your services.
  All of your mesh traffic flows through these proxies
  on its way to its destination.
  Kuma's data plane proxy is based on [Envoy](https://www.envoyproxy.io/).
- **Control plane**: The control plane tells the data plane proxies how to handle mesh traffic.
  Kuma users create and configure [policies](../../policies/introduction)
  that the Kuma control plane processes to generate configuration for the data plane proxies.

::: tip
**Multi-mesh**: One Kuma control plane deployment can control multiple, isolated data planes using the [`Mesh`](../../policies/mesh) resource. As compared to one control plane per data plane, this option lowers the complexity and operational cost of supporting multiple meshes.
:::

This is a high level visualization of a Kuma service mesh:

<center>
<img src="/images/docs/0.4.0/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

Communication happens between the control and data plane
as well as between the services and their data plane proxies:

<center>
<img src="/images/docs/0.4.0/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**xDS**: Kuma implements the [Envoy xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) so that `kuma-dp` can connect to `kuma-cp` and retrieve its configuration.
:::

## Components

A minimal Kuma deployment involves one or more instances of the control plane executable (`kuma-cp`).
For each service in your mesh, you'll have one or more instances of the data plane proxy (`kuma-dp`).

Users interact with the control plane via the CLI tool `kumactl`.

There are two modes that the Kuma control plane can run in:

- `kubernetes`: Users use Kubernetes resources for configuring Kuma.
  Kuma uses the Kubernetes API server as a data store.
- `universal`: Users always use the Kuma API server for interacting with Kuma
  and must configure PostgreSQL as a data store.
  This mode is used for any infrastructure other than Kubernetes.

## Kubernetes mode

When running in **Kubernetes** mode, Kuma will store all of its state and configuration on the underlying Kubernetes API Server.

<center>
<img src="/images/docs/0.5.0/diagram-08.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

The only step necessary to join your Kubernetes services to the mesh is enabling _sidecar injection_.
For any `Pods` configured with sidecar injection, Kuma will add the `kuma-dp` sidecar container.
The following label on any `Namespace` or `Pod` controls this injection:

```
kuma.io/sidecar-injection: enabled
```

::: tip
**Injection**: Learn more about sidecar injection in the section on [`Dataplanes`](dpp-on-kubernetes.md).

**Annotations**: See [the complete list of the Kubernetes annotations](../reference/kubernetes-annotations/).

**Policies with Kubernetes**: When using Kuma in Kubernetes mode you create [policies](../../policies/introduction) using `kubectl` and `kuma.io` CRDs.
:::

### `Services` and `Pods`

#### `Pods` with a `Service`

For all Pods associated with a Kubernetes `Service` resource, Kuma control plane automatically generates an annotation `kuma.io/service: <name>_<namespace>_svc_<port>` where `<name>`, `<namespace>` and `<port>` come from the `Service`. For example, the following resources will generate `kuma.io/service: echo-server_kuma-test_svc_80`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-server
  namespace: kuma-test
  annotations:
    80.service.kuma.io/protocol: http
spec:
  ports:
    - port: 80
      name: http
  selector:
    app: echo-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
  namespace: kuma-test
  labels:
    app: echo-server
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: echo-server
  template:
    metadata:
      labels:
        app: echo-server
    spec:
      containers:
        - name: echo-server
          image: nginx
          ports:
            - containerPort: 80
```

#### Pods without a Service

In some cases `Pods` don't belong to a corresponding `Service`.
This is typically because they don't expose any consumable services.
Kubernetes `Jobs` are a good example of this.

In this case, the Kuma control plane will generate a `kuma.io/service` tag with the format `<name>_<namespace>_svc`, where `<name>` and`<namespace>` are extracted from the `Pod` resource itself.

The `Pods` created by the following example `Deployment` have the tag `kuma.io/service: example-client_kuma-example_svc`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-client
  labels:
    app: echo-client
spec:
  selector:
    matchLabels:
      app: echo-client
  template:
    metadata:
      labels:
        app: echo-client
    spec:
      containers:
        - name: alpine
          image: "alpine"
          imagePullPolicy: IfNotPresent
          command: ["sh", "-c", "tail -f /dev/null"]
```

## Universal mode

When running in **Universal** mode, Kuma requires a PostgreSQL database to store its state. This replaces the Kubernetes API. With Universal, you use `kumactl` to interact directly with the Kuma API server to manage policies.

<center>
<img src="/images/docs/0.5.0/diagram-09.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Read [the docs about the Postgres backend](https://deploy-preview-870--kuma.netlify.app/docs/dev/explore/backends/#postgres) for more details.
