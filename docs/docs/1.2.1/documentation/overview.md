# Overview

As we have [already learned](../introduction), Kuma is a universal control plane that can run across both modern environments like Kubernetes and more traditional VM-based ones.

The first step is obviously to [download and install Kuma](/install/) on the platform of your choice. Different distributions will present different installation instructions that follow the best practices for the platform you have selected.

Regardless of what platform you decide to use, the fundamental behavior of Kuma at runtime will not change across different distributions. These fundamentals are important to explore in order to understand what Kuma is and how it works.

::: tip
Installing Kuma on Kubernetes is fully automated, while installing Kuma on Linux requires the user to run the Kuma executables. Both ways are very simple, and can be explored from the [installation page](/install/).
:::

There are two main components of Kuma that are very important to understand:

* **Control Plane**: Kuma is first and foremost a control-plane that will accept user input (you are the user) in order to create and configure [Policies](../../policies/introduction) like [Service Meshes](../../policies/mesh), and in order to add services and configure their behavior within the Meshes you have created.
* **Data Plane Proxy**: Kuma also bundles a data plane proxy implementation based on top of [Envoy](https://www.envoyproxy.io/). An instance of the data plane proxy runs alongside every instance of our services (or on every Kubernetes Pod as a sidecar container). This instance processes both incoming and outgoing requests for the service.

::: tip
**Multi-Mesh**: Kuma ships with multi-tenancy support since day one. This means you can create and configure multiple isolated Service Meshes from **one** control-plane. By doing so we lower the complexity and the operational cost of supporting multiple meshes. [Explore Kuma's Policies](/policies).
:::

Since Kuma bundles a data-plane in addition to the control-plane, we decided to call the executables `kuma-cp` and `kuma-dp` to differentiate them. Let's take a look at all the executables that ship with Kuma:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-prometheus-sd`: this is a helper tool that enables native integration between `Kuma` and `Prometheus`. Thanks to it, `Prometheus` will be able to automatically find all dataplanes in your Mesh and scrape metrics out of them.
* `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

A minimal Kuma deployment involves one or more instances of the control-plane (`kuma-cp`), and one or more instances of the data-planes (`kuma-dp`) which will connect to the control-plane as soon as they startup. Kuma supports two modes:

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

In a typical Kubernetes deployment scenario, every `Pod` is part of at least one matching `Service`. For example, in [Kuma's demo application](https://github.com/kumahq/kuma-demo/blob/master/kubernetes/), the [`Pod` for the Redis service](https://github.com/kumahq/kuma-demo/blob/master/kubernetes/kuma-demo-aio.yaml#L104)  has the following matchLabels:

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

### Service pods and service-less pods

In some cases, there might be a need to have Pods which are part of the mesh, yet they do not expose any services themselves. These are typically various containerised utilities, Kubernets jobs etc.
Such Pods are not bound to a Kubernetes Service as they would not have any ports exposed.

#### Pods with a Service

For all Pods associated with a Kubernetes Service resource, Kuma control plane will automatically generate an annotation `kuma.io/service: <name>_<namespace>_svc_<port>` fetching `<name>`, `<namespace>` and `<port>` from the that service. For example, the following resources will generate a dataplane tag
`kuma.io/service: echo-server_kuma-test_svc_80`:

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

When a pod is spawned without exposing a particular service, it may not be associated with any Kubernetes Service resource. In that case, Kuma control plane will generate `kuma.io/service: <name>_<namespace>_svc`, where `<name>` and`<namespace>` are extracted from the Pod resource itself omitting the port. The following resource will generate a dataplane tag 
`kuma.io/service: example-client_kuma-example_svc`:

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

In both cases these tags will be see in the CLI and GUI tools when inspecting the particular Pod dataplane.

### Annotations that can be used by in Kubernetes mode

#### `kuma.io/mesh`

By using this Pod annotation you associate a given Pod with a particular Mesh. Annotation value must be the name of a Mesh resource.

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: backend
 annotations:
   kuma.io/mesh: default
[...]
```

#### `kuma.io/sidecar-injection`

Sidecar Injection annotation defines a Pod/Namespace annotation that gives users an ability to enable or disable sidecar-injection

**Example**

```yaml
apiVersion: v1
kind: Namespace
metadata:
 name: default
 annotations:
   kuma.io/sidecar-injection: enabled
[...]
```

#### `kuma.io/gateway`

Gateway annotation allows to mark Gateway pod, inbound listeners won't be generated in that case

**Example**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
spec:
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
      annotations:
        kuma.io/gateway: enabled
[...]
```

#### `kuma.io/ingress`

When a pod is marked with this annotation it will inform Kuma to treat it as the Zone Ingress which is crucial for Multizone communication as all traffic from other zones will be passing through it.

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
[...]
```

#### `kuma.io/ingress-public-address`

Ingress public address annotation allows you to pick public address for Ingress. If not defined, Kuma will try to pick this address from the Ingress Service

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
   kuma.io/ingress-public-address: custom-address.com
[...]
```

#### `kuma.io/ingress-public-port`

Ingress public port annotation allows to pick public port for Ingress. If not defined, Kuma will try to pick this address from the Ingress Service

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
   kuma.io/ingress-public-port: "1234"
[...]
```

#### `kuma.io/direct-access-services`

Direct access defines a comma-separated list of Services that will be accessed directly

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/direct-access-services: test-app_playground_svc_80,test-app_playground_svc_443
    kuma.io/transparent-proxying: enabled
    kuma.io/transparent-proxying-inbound-port: [...]
    kuma.io/transparent-proxying-outbound-port: [...]
```

::: tip
Transparent Proxy mechanism is based on having 1 IP for cluster (ex. ClusterIP of Kubernetes Service), so consuming apps by their IP addresses is unknown destination from Envoy perspective. Therefore, such request will go through `pass_trough` cluster and won't be encrypted by mTLS.

When annotating a pod with `kuma.io/direct-access-services` annotation Kuma will generate a listener for every IP address and will redirect traffic trough `direct_access` cluster which is configured to encrypt connections.
:::

::: warning
**WARNING**: Generating listeners for every endpoint will cause XDS snapshot to be large therefore it should be used only if really needed.
:::

#### `kuma.io/virtual-probes`

Virtual probes annotation enables automatic converting HttpGet probes to virtual. Virtual probe serves on sub-path of insecure port defined in `kuma.io/virtual-probes-port`, i.e `:8080/health/readiness` -> `:9000/8080/health/readiness` where `9000` is a value of `kuma.io/virtual-probes-port` annotation

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/virtual-probes: enabled
    kuma.io/virtual-probes-port: "9000"
[...]
```

#### `kuma.io/virtual-probes-port`

Virtual probes port annotation is an insecure port for listening virtual probes

#### `kuma.io/sidecar-env-vars`

Sidecar env vars annotation is a `;` separated list of env vars that will be applied on Kuma Sidecar

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/sidecar-env-vars: TEST1=1;TEST2=2 
```

#### `prometheus.metrics.kuma.io/port`

By using this annotation, you can override `Mesh`-wide default port where prometheus should scrape metrics from

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/port: "1234"
```

#### `prometheus.metrics.kuma.io/path`

Metrics prometheus path to override `Mesh`-wide default path where prometheus should scrape metrics from

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/path: "/custom-metrics"
```

#### `kuma.io/builtindns`

Instruct sidecar to use its builtin DNS server

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/builtindns: enabled
```

#### `kuma.io/builtindnsport`

Port where builtin DNS server should listen for DNS queries

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/builtindns: enabled
    kuma.io/builtindnsport: "15053"
```

#### `traffic.kuma.io/exclude-inbound-ports`

List of inbound ports that will be excluded from traffic interception by Kuma sidecar

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    traffic.kuma.io/exclude-inbound-ports: "1234,1235"
```

#### `traffic.kuma.io/exclude-outbound-ports`

List of outbound ports that will be excluded from traffic interception by Kuma sidecar

**Example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    traffic.kuma.io/exclude-outbound-ports: "1234,1235"
```

## Last but not least

Once the `kuma-cp` process is started, it waits for [data-planes](../dps-and-data-model) to connect, while at the same time accepting user-defined configuration to start creating Service Meshes and configuring the behavior of those meshes via Kuma [Policies](../../policies/introduction).

When we look at a typical Kuma installation, at a higher level it works like this:

<center>
<img src="/images/docs/0.4.0/diagram-06.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

When we unpack the underlying behavior, it looks like this:

<center>
<img src="/images/docs/0.4.0/diagram-07.jpg" alt="" style="padding-top: 20px; padding-bottom: 10px;"/>
</center>

::: tip
**xDS APIs**: Kuma implements the [xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) APIs of Envoy in the `kuma-cp` application so that the Envoy DPs can connect to it and retrieve their configuration.
:::
