---
title: Migration to the new policies
description: Migrate from legacy source/destination policies to new targetRef-based policies using shadow mode.
keywords:
  - policy migration
  - targetRef
  - shadow mode
---

{{site.mesh_product_name}} provides two set of policies to configure proxies.
The original [source/destination](/docs/{{ page.release }}/policies/general-notes-about-kuma-policies/) policies,
while provided a lot of features, haven't met users expectations in terms of flexibility and transparency.
The new [targetRef](/docs/{{ page.release }}/policies/introduction) policies were designed to preserve what already worked well,
and enhance the matching functionality and overall UX.

In this guide, we're going to setup a demo with old policies and then perform a migration to the new policies.

## Prerequisites
- [`helm`](https://helm.sh/) - a package manager for Kubernetes
- [`kind`](https://kind.sigs.k8s.io/) - a tool for running local Kubernetes clusters
- [`jq`](https://jqlang.github.io/jq/) - a command-line JSON processor
- [`jd`](https://github.com/josephburnett/jd) - a command-line utility to visualise JSONPatch

## Start Kubernetes cluster

Start a new Kubernetes cluster on your local machine by executing:

```sh
kind create cluster --name=mesh-zone
```

{% tip %}
You can skip this step if you already have a Kubernetes cluster running.
It can be a cluster running locally or in a public cloud like AWS EKS, GCP GKE, etc.
{% endtip %}

## Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} control plane with `skipMeshCreation` set to `true` by executing:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{site.mesh_namespace}} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} --set "{{site.set_flag_values_prefix}}controlPlane.defaults.skipMeshCreation=true"
```

Make sure the list of meshes is empty:

```sh
kubectl get meshes
```
Expected output:
```
No resources found
```

## Setup demo with old policies

In the first half of this guide we're going to deploy a demo app in the `default` mesh and configure it using old policies.

### Create `default` mesh

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  # for the purpose of this guide we want to setup mesh with old policies first,
  # that is why we are skipping the default policies creation
  skipCreatingInitialPolicies: ["*"] ' | kubectl apply -f-
```

### Deploy demo application

1.  Deploy the application
    ```sh
    kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
    kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
    ```

2.  Port-forward the service to the namespace on port 5000:

    ```sh
    kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
    ```

3.  In a browser, go to [127.0.0.1:5000](http://127.0.0.1:5000) and increment the counter.

### Enable mTLS and deploy TrafficPermissions

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ["*"]
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin' | kubectl apply -f-
```

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  name: app-to-redis
spec:
  sources:
    - match:
        kuma.io/service: demo-app_kuma-demo_svc_5000
  destinations:
    - match:
        kuma.io/service: redis_kuma-demo_svc_6379' | kubectl apply -f -
```

### Deploy TrafficRoute

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: TrafficRoute
mesh: default
metadata:
  name: route-all-default
spec:
  sources:
    - match:
        kuma.io/service: "*"
  destinations:
    - match:
        kuma.io/service: "*"
  conf:
    destination:
      kuma.io/service: "*"' | kubectl apply -f-
```

### Deploy Timeouts

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Timeout
mesh: default
metadata:
  name: timeout-global
spec:
  sources:
    - match:
        kuma.io/service: "*"
  destinations:
    - match:
        kuma.io/service: "*"
  conf:
    connectTimeout: 21s
    tcp:
      idleTimeout: 22s
    http:
      idleTimeout: 22s
      requestTimeout: 23s
      streamIdleTimeout: 25s
      maxStreamDuration: 26s' | kubectl apply -f-
```

### Deploy CircuitBreaker

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: CircuitBreaker
mesh: default
metadata:
  name: cb-global
spec:
  sources:
  - match:
      kuma.io/service: "*"
  destinations:
  - match:
      kuma.io/service: "*"
  conf:
    interval: 21s
    baseEjectionTime: 22s
    maxEjectionPercent: 23
    splitExternalAndLocalErrors: false
    thresholds:
      maxConnections: 24
      maxPendingRequests: 25
      maxRequests: 26
      maxRetries: 27
    detectors:
      totalErrors:
        consecutive: 28
      gatewayErrors:
        consecutive: 29
      localErrors:
        consecutive: 30
      standardDeviation:
        requestVolume: 31
        minimumHosts: 32
        factor: 1.33
      failure:
        requestVolume: 34
        minimumHosts: 35
        threshold: 36' | kubectl apply -f-
```

## Migration steps

It's time to migrate the demo app to the new policies.

Each type of policy can be migrated separately; for example, once we have completely finished with the `Timeout`s,
we will proceed to the next policy type, `CircuitBreakers`.
It's possible to migrate all policies at once, but small portions are preferable as they're easily reversible.

The generalized migration process roughly consists of 4 steps:

1. Create a new [targetRef](/docs/{{ page.release }}/policies/introduction) policy as a replacement for existing [source/destination](/docs/{{ page.release }}/policies/general-notes-about-kuma-policies/) policy (do not forget about default policies that might not be stored in your source control).
The corresponding new policy type can be found in [the table](/docs/{{ page.release }}/policies/introduction).
Deploy the policy in {% if_version lte:2.12.x %}[shadow mode](/docs/{{ page.release }}/policies/introduction/#applying-policies-in-shadow-mode){% endif_version %}{% if_version gte:2.13.x %}shadow mode (apply with `kuma.io/effect: shadow` label){% endif_version %} to avoid any traffic disruptions.
2. Using Inspect API review the list of changes that are going to be created by the new policy.
3. Remove `kuma.io/effect: shadow` label so that policy is applied in a normal mode.
4. Observe metrics, traces and logs. If something goes wrong change policy's mode back to shadow and return to the step 2.
If everything is fine then remove the old policies.

{% warning %}
The order of migrating policies generally doesn't matter, except for the TrafficRoute policy,
which should be the last one deleted when removing old policies.
This is because many old policies, like Timeout and CircuitBreaker, depend on TrafficRoutes to function correctly.
{% endwarning %}

### TrafficPermission -> MeshTrafficPermission

1. Create a replacement policy for `app-to-redis` TrafficPermission and apply it with `kuma.io/effect: shadow` label:

    ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     namespace: {{site.mesh_namespace}}
     name: app-to-redis
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: MeshService
       name: redis_kuma-demo_svc_6379
     from:
       - targetRef:
           kind: MeshSubset
           tags:
             kuma.io/service: demo-app_kuma-demo_svc_5000
         default:
           action: Allow' | kubectl apply -f -
    ```

2. Check the list of changes for the `redis_kuma-demo_svc_6379` `kuma.io/service` in Envoy configuration using `kumactl`, `jq` and `jd`:

    ```sh
   DATAPLANE_NAME=$(kumactl get dataplanes -ojson | jq '.items[] | select(.networking.inbound[0].tags["kuma.io/service"] == "redis_kuma-demo_svc_6379") | .name')
   kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
    ```
    Expected output:
    ```
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","inbound:10.42.0.13:6379","filterChains","0","filters","0","typedConfig","rules","policies","allow-all-default"]
   - {"permissions":[{"any":true}],"principals":[{"authenticated":{"principalName":{"exact":"spiffe://default/demo-app_kuma-demo_svc_5000"}}}]}
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","inbound:10.42.0.13:6379","filterChains","0","filters","0","typedConfig","rules","policies","MeshTrafficPermission"]
   + {"permissions":[{"any":true}],"principals":[{"authenticated":{"principalName":{"exact":"spiffe://default/demo-app_kuma-demo_svc_5000"}}}]}
    ```

    As we can see, the only difference is the policy name `MeshTrafficPermission` instead of `allow-all-default`.
    The value of the policy is the same.

3. Remove the `kuma.io/effect: shadow` label:

    ```sh
    kubectl label -n kuma-system meshtrafficpermission app-to-redis kuma.io/effect-
    ```

    Even though the old TrafficPermission and the new MeshTrafficPermission are both in use, the new policy takes precedence, making the old one ineffective.

4. Check that the demo app behaves as expected. If everything goes well, we can safely remove TrafficPermissions:

    ```sh
   kubectl delete trafficpermissions --all
    ```

### Timeout -> MeshTimeout

1. Create a replacement policy for `timeout-global` Timeout and apply it with `kuma.io/effect: shadow` label:

    ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTimeout
   metadata:
     namespace: {{site.mesh_namespace}}
     name: timeout-global
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: Mesh
     to:
     - targetRef:
         kind: Mesh
       default:
         connectionTimeout: 21s
         idleTimeout: 22s
         http:
           requestTimeout: 23s
           streamIdleTimeout: 25s
           maxStreamDuration: 26s
     from:
     - targetRef:
         kind: Mesh
       default:
         connectionTimeout: 10s
         idleTimeout: 2h
         http:
           requestTimeout: 0s
           streamIdleTimeout: 2h' | kubectl apply -f-
    ```

2. Check the list of changes for the `redis_kuma-demo_svc_6379` `kuma.io/service` in Envoy configuration using `kumactl`, `jq` and `jd`:

    ```sh
   kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
    ```
    Expected output:
    ```
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","demo-app_kuma-demo_svc_5000","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","maxConnectionDuration"]
   + "0s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.43.146.6:5000","filterChains","0","filters","0","typedConfig","commonHttpProtocolOptions","idleTimeout"]
   - "22s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.43.146.6:5000","filterChains","0","filters","0","typedConfig","commonHttpProtocolOptions","idleTimeout"]
   + "0s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.43.146.6:5000","filterChains","0","filters","0","typedConfig","routeConfig","virtualHosts","0","routes","0","route","idleTimeout"]
   + "25s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.43.146.6:5000","filterChains","0","filters","0","typedConfig","requestHeadersTimeout"]
   + "0s"
    ```

    Review the list and ensure the new MeshTimeout policy won't change the important settings.
    The key differences between old and new timeout policies:

    * Previously, there was no way to specify `requestHeadersTimeout`, `maxConnectionDuration` and `maxStreamDuration` (on inbound).
    These timeouts were unset. With the new MeshTimeout policy we explicitly set them to `0s` by default.
    * `idleTimeout` was configured both on the cluster and listener. MeshTimeout configures it only on the cluster.
    * `route/idleTimeout` is duplicated value of `streamIdleTimeout` but per-route. Previously we've set it only per-listener.

    These 3 facts perfectly explain the list of changes we're observing.

3. Remove the `kuma.io/effect: shadow` label.

   ```sh
   kubectl label -n kuma-system meshtimeout timeout-global kuma.io/effect-
   ```

   Even though the old Timeout and the new MeshTimeout are both in use, the new policy takes precedence, making the old one ineffective.

4. Check that the demo app behaves as expected. If everything goes well, we can safely remove Timeouts:

   ```sh
   kubectl delete timeouts --all
   ```

### CircuitBreaker -> MeshCircuitBreaker

1. Create a replacement policy for `cb-global` CircutBreaker and apply it with `kuma.io/effect: shadow` label:

    ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshCircuitBreaker
   metadata:
     namespace: {{site.mesh_namespace}}
     name: cb-global
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: Mesh
     to:
     - targetRef:
         kind: Mesh
       default:
         connectionLimits:
           maxConnections: 24
           maxPendingRequests: 25
           maxRequests: 26
           maxRetries: 27
         outlierDetection:
           interval: 21s
           baseEjectionTime: 22s
           maxEjectionPercent: 23
           splitExternalAndLocalErrors: false
           detectors:
             totalFailures:
               consecutive: 28
             gatewayFailures:
               consecutive: 29
             localOriginFailures:
               consecutive: 30
             successRate:
               requestVolume: 31
               minimumHosts: 32
               standardDeviationFactor: "1.33"
             failurePercentage:
               requestVolume: 34
               minimumHosts: 35
               threshold: 36' | kubectl apply -f-
    ```

2. Check the list of changes for the `redis_kuma-demo_svc_6379` `kuma.io/service` in Envoy configuration using `kumactl`, `jq` and `jd`:

    ```sh
   kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
    ```

    The expected output is empty. CircuitBreaker and MeshCircuitBreaker configures Envoy in the exact similar way.

3. Remove the `kuma.io/effect: shadow` label.

   ```sh
   kubectl label -n kuma-system meshcircuitbreaker cb-global kuma.io/effect-
   ```

   Even though the old CircuitBreaker and the new MeshCircuitBreaker are both in use, the new policy takes precedence, making the old one ineffective.

4. Check that the demo app behaves as expected. If everything goes well, we can safely remove CircuitBreakers:

   ```sh
   kubectl delete circuitbreakers --all
   ```

### TrafficRoute -> MeshTCPRoute

It's safe to simply remove `route-all-default` TrafficRoute.
Traffic will flow through the system even if there are neither TrafficRoutes nor MeshTCPRoutes/MeshHTTPRoutes.

### MeshGatewayRoute -> MeshHTTPRoute/MeshTCPRoute

The biggest change is that there are now 2 protocol specific routes, one for TCP
and one for HTTP. `MeshHTTPRoute` always takes precedence over `MeshTCPRoute` if
both exist.

Otherwise the high-level structure of the routes hasn't changed, though there are a number
of details to consider.
Some enum values and some field structures were updated, largely to reflect Gateway API.

Please first read the [`MeshGatewayRoute` docs](/docs/{{ page.release
}}/policies/meshgatewayroute), the [`MeshHTTPRoute` docs](/docs/{{ page.release }}/policies/meshhttproute)
and the [`MeshTCPRoute` docs](/docs/{{ page.release }}/policies/meshtcproute).
Always refer to the spec to ensure your new resource is valid.

Note that `MeshHTTPRoute` has precedence over `MeshGatewayRoute`.

We're going to start with a gateway and simple legacy `MeshGatewayRoute`,
look at how to migrate `MeshGatewayRoutes` in general
and then finish with migrating our example `MeshGatewayRoute`.

Let's start with the following `MeshGateway` and `MeshGatewayInstance`:

```sh
echo "---
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: demo-app
  labels:
    kuma.io/origin: zone
spec:
  conf:
    listeners:
    - port: 80
      protocol: HTTP
      tags:
        port: http-80
  selectors:
  - match:
      kuma.io/service: demo-app-gateway_kuma-demo_svc
---
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: demo-app-gateway
  namespace: kuma-demo
spec:
  replicas: 1
  serviceType: LoadBalancer" | kubectl apply -f-
```

and the following initial `MeshGatewayRoute`:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGatewayRoute
mesh: default
metadata:
  name: demo-app-gateway
spec:
  conf:
   http:
    hostnames:
    - example.com
    rules:
    - matches:
      - path:
          match: PREFIX
          value: /
      backends:
      - destination:
          kuma.io/service: demo-app_kuma-demo_svc_5000
        weight: 1
  selectors:
  - match:
      kuma.io/service: demo-app-gateway_kuma-demo_svc" | kubectl apply -f-
```

#### Targeting

The main consideration is specifying which gateways are affected by the route.
The most important change is that instead of
solely using tags to select `MeshGateway` listeners,
new routes target `MeshGateways` by name and optionally with tags for specific
listeners.

So in our example:

```yaml
spec:
  selectors:
    - match:
        kuma.io/service: demo-app-gateway_kuma-demo_svc
        port: http-80
```

becomes:

```yaml
spec:
  targetRef:
    kind: MeshGateway
    name: demo-app
    tags:
      port: http-80
  to:
```

because we're now using the _name_ of the `MeshGateway`
instead of the `kuma.io/service` it matches.

#### Spec

As with all new policies, the spec is now merged under a `default` field.
`MeshTCPRoute` is very simple, so the rest of this is focused on
`MeshHTTPRoute`.

Note that for `MeshHTTPRoute` the `hostnames` are directly under the `to` entry:

```yaml
  conf:
    http:
      hostnames:
        - example.com
      # ...
```

becomes:

```yaml
  to:
    - targetRef:
        kind: Mesh
      hostnames:
        - example.com
      # ...
```

##### Matching

Matching works the same as before. Remember that for `MeshHTTPRoute` that merging is done on a match
basis. So it's possible for one route to define `filters` and another
`backendRefs` for a given match, and the resulting rule would both apply the filters and route to the
backends.

Given two routes, one with:

```yaml
  to:
      rules:
        - matches:
            - path:
                match: PathPrefix
                value: /
          default:
            filters:
              - type: RequestHeaderModifier
                requestHeaderModifier:
                  set:
                    - name: x-custom-header
                      value: xyz
```

and the other:

```yaml
  to:
      rules:
        - matches:
            - path:
                match: PathPrefix
                value: /
          default:
            backendRefs:
              - kind: MeshService
                name: backend
                namespace: kuma-demo
                port: 3001
```

Traffic to `/` would have the `x-custom-header` added and be sent to the `backend`.

##### Filters

Every `MeshGatewayRoute` filter has an equivalent in `MeshHTTPRoute`.
Consult the documentation for both resources to
find out how each filter looks in `MeshHTTPRoute`.

##### Backends

Backends are similar except that instead of targeting with tags, the `targetRef`
structure with `kind: MeshService`/`kind: MeshServiceSubset` is used.

##### Equivalent MeshHTTPRoute

So all in all we have:

1. Create the equivalent MeshHTTPRoute

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshHTTPRoute
   metadata:
     name: demo-app
     namespace: kuma-system
     labels:
       kuma.io/origin: zone
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: MeshGateway
       name: demo-app
     to:
     - targetRef:
         kind: Mesh
       hostnames:
         - example.com
       rules:
       - default:
           backendRefs:
           - kind: MeshService
             name: demo-app_kuma-demo_svc_5000
         matches:
         - path:
             type: PathPrefix
             value: /" | kubectl apply -f -
   ```

2. Check that traffic is still working.

3. Delete the previous MeshGatewayRoute:

   ```sh
   kubectl delete meshgatewayroute --all
   ```


## Next steps

* Further explore [new policies](/docs/{{ page.release }}/policies/introduction)
