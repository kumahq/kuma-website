# Data plane on Kubernetes

On Kubernetes the [`Dataplane`](dpp.md#dataplane-entity) entity is automatically created for you, and because transparent proxying is used to communicate between the service and the sidecar proxy, no code changes are required in your applications.

You can control where Kuma automatically injects the dataplane proxy by **labeling** either the Namespace or the Pod with
`kuma.io/sidecar-injection=enabled`, e.g.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-example
  labels:
    # inject Kuma sidecar into every Pod in that Namespace,
    # unless a user explicitly opts out on per-Pod basis
    kuma.io/sidecar-injection: enabled
```

To opt out of data-plane injection into a particular `Pod`, you need to **label** it
with `kuma.io/sidecar-injection=disabled`, e.g.

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
      labels:
        # indicate to Kuma that this Pod doesn't need a sidecar
        kuma.io/sidecar-injection: disabled
    spec:
      containers:
        ...
```
::: warning
In previous versions the recommended way was to use annotations.
While annotations are still supported, we strongly recommend using labels.
This is the only way to guarantee that applications can only be started with sidecar.
:::

Once your pod is running you can see the dataplane CRD that matches it using `kubectl`:

```shell
kubectl get dataplanes <podName>
```

## Tag generation

When `Dataplane` entities are automatically created, all labels from Pod are converted into `Dataplane` tags.
Labels with keys that contains `kuma.io/` are not converted because they are reserved to Kuma.
The following tags are added automatically and cannot be overridden using Pod labels.

* `kuma.io/service`: Identifies the service name based on a Service that selects a Pod. This will be of format `<name>_<namespace>_svc_<port>` where `<name>`, `<namespace>` and `<port>` are from the Kubernetes service that is associated with the particular pod.
  When a pod is spawned without being associated with any Kubernetes Service resource the dataplane tag will be `kuma.io/service: <name>_<namespace>_svc`, where `<name>` and`<namespace>` are extracted from the Pod resource.
* `kuma.io/zone`: Identifies the zone name in a [multi-zone deployment](../deployments/multi-zone.md).
* `kuma.io/protocol`: Identifies [the protocol](../policies/protocol-support-in-kuma.md) that was defined on the Service that selects a Pod.
* `k8s.kuma.io/namespace`: Identifies the Pod's namespace. Example: `kuma-demo`.
* `k8s.kuma.io/service-name`: Identifies the name of Kubernetes Service that selects a Pod. Example: `demo-app`.
* `k8s.kuma.io/service-port`: Identifies the port of Kubernetes Service that selects a Pod. Example: `80`.

## Direct access to services

By default on Kubernetes data plane proxies communicate with each other by leveraging the `ClusterIP` address of the `Service` resources. Also by default, any request made to another service is automatically load balanced client-side by the data plane proxy that originates the request (they are load balanced by the local Envoy proxy sidecar proxy).

There are situations where we may want to bypass the client-side load balancing and directly access services by using their IP address (ie: in the case of Prometheus wanting to scrape metrics from services by their individual IP address).

When an originating service wants to directly consume other services by their IP address, the originating service's `Deployment` resource must include the following annotation:

```yaml
kuma.io/direct-access-services: Service1, Service2, ServiceN
```

Where the value is a comma separated list of Kuma services that will be consumed directly. For example:

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
        kuma.io/direct-access-services: "backend_example_svc_1234,backend_example_svc_1235"
    spec:
      containers:
        ...
```

We can also use `*` to indicate direct access to every service in the Mesh:

```yaml
kuma.io/direct-access-services: *
```

::: warning
Using `*` to directly access every service is a resource intensive operation, so we must use it carefully.
:::

## Lifecycle

### Joining the mesh

On Kubernetes, `Dataplane` resource is automatically created by kuma-cp. For each Pod with sidecar-injection label a new
`Dataplane` resource will be created.

To join the mesh in a graceful way, we need to first make sure the application is ready to serve traffic before it can be considered a valid traffic destination.

When Pod is converted to a `Dataplane` object it will be marked as unhealthy until Kubernetes considers all containers to be ready.

### Leaving the mesh

To leave the mesh in a graceful shutdown, we need to remove the traffic destination from all the clients before shutting it down.

When the Kuma DP sidecar receives a `SIGTERM` signal it does in this order:

1) start draining Envoy listeners
2) wait for the entire draining time
3) stop the sidecar process
During the draining process, Envoy can still accept connections however:
1) It is marked as unhealthy on Envoy Admin `/ready` endpoint
2) It sends `connection: close` for HTTP/1.1 requests and GOAWAY frame for HTTP/2.
   This forces clients to close a connection and reconnect to the new instance.

You can read [Kubernetes docs](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination) to learn how Kubernetes handles pod lifecycle. Here is the summary with relevant parts for Kuma.

Whenever a user or system deletes a Pod, Kubernetes does the following things:
1) It marks the Pod as terminated.
2) Concurrently for every container it
  1) Executes any pre stop hook if defined
  2) Sends a SIGTERM signal
  3) Waits until container is terminated for maximum of graceful termination time (by default 60s)
  4) Sends a SIGKILL to the container
3) It removes the Pod object from the system

When Pod is marked as terminated, Kuma CP updates Dataplane object to be unhealthy which will trigger configuration update to all the clients to remove it as a destination.
This can take a couple of seconds depending on the size of the mesh, available resources for CP, XDS configuration interval, etc.

If the application next to the Kuma DP sidecar quits immediately after the SIGTERM signal, there is a high chance that clients will still try to send traffic to this destination.

To mitigate this, we need to either
* Support graceful shutdown in the application. For example, the application should wait X seconds to exit after receiving the first SIGTERM signal.
* Add a pre-stop hook to postpone stopping the application container. Example:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: redis
  spec:
    template:
      spec:
        containers:
        - name: redis
          image: "redis"
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sleep", "30"]
  ```

When a Pod is deleted its matching `Dataplane` resource is deleted as well. This is possible thanks to the
[owner reference](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/) set on the `Dataplane` resource.
