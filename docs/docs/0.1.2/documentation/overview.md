# Overview

As we have [already learned](../), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

The first step is obviously to [download and install Kuma](/install/0.1.2) on the platform of your choice. Different distributions will present different installation instructions that follow the best practices for the platform you have selected.

Regardless of what platform you decide to use, the fundamental behavior of Kuma at runtime will not change across different distributions. These fundamentals are important to explore in order to understand what Kuma is and how it works.

::: tip
Installing Kuma on Kubernetes is fully automated, while installing Kuma on Linux requires the user to run the Kuma executables. Both ways are very simple, and can be explored from the [installation page](/install/0.1.2).
:::

There are two main components of Kuma that are very important to understand:

* **Control-Plane**: Kuma is first and foremost a control-plane that will accept user input (you are the user) in order to create and configure [Policies](../../policies/introduction) like [Service Meshes](../../policies/mesh), and in order to add services and configure their behavior within the Meshes you have created.
* **Data-Plane**: Kuma also bundles a data-plane implementation based on top of [Envoy](https://www.envoyproxy.io/) for convenience, in order to get up and running quickly. An instance of the data-plane will run alongside every instance of our services, and it will process both incoming and outgoing requests for the service.

::: tip
**Multi-Mesh**: Kuma ships with multi-tenancy support since day one. This means you can create and configure multiple isolated Service Meshes from **one** control-plane. By doing so we lower the complexity and the operational cost of supporting multiple meshes. [Explore Kuma's Policies](../../policies/introduction).
:::

Since Kuma bundles a data-plane in addition to the control-plane, we decided to call the executables `kuma-cp` and `kuma-dp` to differentiate them. Let's take a look at all the executables that ship with Kuma:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

In addition to these binaries, there is another binary that will be executed when running on Kubernetes:

* `kuma-injector`: only for Kubernetes, this is a process that listens to events propagated by Kubernetes, and that automatically injects a `kuma-dp` sidecar container to our services.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data-planes (`kuma-dp`) which will connect to the control-plane as soon as they startup. Kuma supports two modes:

* `universal`: when it's being installed on a Linux compatible machine like MacOS, Virtual Machine or Bare Metal. This also includes those instances where Kuma is being installed on a Linux base machine (ie, a Docker image).
* `kubernetes`: when it's being deployed - well - on Kubernetes.

### Universal mode

When running in **Universal** mode, Kuma will require a PostgreSQL database to store its state. The PostgreSQL database and schema will have to be initialized accordingly to the installation instructions.

Unlike `kubernetes` mode, Kuma won't require the `kuma-injector` executable to run:

<center>
<img src="/images/docs/0.1.2/diagram-09.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Kubernetes mode

When running on **Kubernetes**, Kuma will store all of its state and configuration on the underlying Kubernetes API Server, therefore requiring no dependency to store the data. But it requires the `kuma-injector` executable to run in a Pod (only one instance per Kubernetes cluster) so that it can automatically inject `kuma-dp` on any Pod that belongs to a Namespace that includes the following label:

```
kuma.io/sidecar-injection: enabled
```

When following the installation instructions, `kuma-injector` will be automatically started.

<center>
<img src="/images/docs/0.1.2/diagram-08.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

### Matching Labels in `Pod` and `Service` 

When deploying Kuma on Kubernetes, you must ensure that every `Pod` is part of at least one matching `Service`. For example, in [Kuma's demo application](https://github.com/Kong/kuma-demo/blob/master/kubernetes/), the [`Pod` for the Redis service](https://github.com/Kong/kuma-demo/blob/master/kubernetes/kuma-demo-aio.yaml#L104)  has the following matchLabels:

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

At least one of these labels must match the labels we define in our `Service`. The correct way to define the [corresponding Redis `Service`](https://github.com/Kong/kuma-demo/blob/master/kubernetes/kuma-demo-aio.yaml#L133) would be as follows:

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

### Last but not least

Once the `kuma-cp` process is started, it waits for [data-planes](../../documentation/dps-and-data-model) to connect, while at the same time accepting user-defined configuration to start creating Service Meshes and configuring the behavior of those meshes via Kuma [Policies](../../policies/introduction).

When we look at a typical Kuma installation, at a higher level it works like this:

<center>
<img src="/images/docs/0.1.2/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

When we unpack the underlying behavior, it looks like this:

<center>
<img src="/images/docs/0.1.2/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**xDS APIs**: Kuma implements the [xDS](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/v2_overview) APIs of Envoy in the `kuma-cp` application so that the Envoy DPs can connect to it and retrieve their configuration.
:::