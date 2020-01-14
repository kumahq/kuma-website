# Policies

::: tip
**Need help?** Installing and using Kuma should be as easy as possible. [Contact and chat](/community) with the community in real-time if you get stuck or need clarifications. We are here to help.
:::

Here you can find the list of Policies that Kuma supports, that will allow you to build a modern and reliable Service Mesh.

## Applying Policies

Once installed, Kuma can be configured via its policies. You can apply policies with [`kumactl`](/docs/DRAFT/documentation/#kumactl) on Universal, and with `kubectl` on Kubernetes. Regardless of what environment you use, you can always read the latest Kuma state with [`kumactl`](/docs/DRAFT/documentation/#kumactl) on both environments.

::: tip
We follow the best practices. You should always change your Kubernetes state with CRDs, that's why Kuma disables `kumactl apply [..]` when running in K8s environments.
:::

These policies can be applied either by file via the `kumactl apply -f [path]` or `kubectl apply -f [path]` syntax, or by using the following command:

```sh
echo "
  type: ..
  spec: ..
" | kumactl apply -f -
```

or - on Kubernetes - by using the equivalent:

```sh
echo "
  apiVersion: kuma.io/v1alpha1
  kind: ..
  spec: ..
" | kubectl apply -f -
```

Below you can find the policies that Kuma supports. In addition to [`kumactl`](/docs/DRAFT/documentation/#kumactl), you can also retrive the state via the Kuma [HTTP API](/docs/DRAFT/documentation/#http-api) as well.

## Mesh

This policy allows to create multiple Service Meshes on top of the same Kuma cluster.

On Universal:

```yaml
type: Mesh
name: default
```

On Kuberentes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
```

## Mutual TLS

This policy enables automatic encrypted mTLS traffic for all the services in a [`Mesh`](#mesh).

Kuma ships with a `builtin` CA (Certificate Authority) which is initialized with an auto-generated root certificate. The root certificate is unique for every [`Mesh`](#mesh) and it used to sign identity certificates for every data-plane. Kuma also supports third-party CA.

The mTLS feature is used for AuthN/Z as well: each data-plane is being assigned with a workload identity certificate, which is SPIFFE compatible. This certificate has a SAN set to `spiffe://<mesh name>/<service name>`. When Kuma enforces policies that require an identity, like [`TrafficPermission`](#traffic-permission), it will extract the SAN from the client certificate and use it for every identity matching operation.

By default, mTLS is **not** enabled. You can enable Mutual TLS by updating the [`Mesh`](#mesh) policy with the `mtls` setting.

On Universal with `builtin` CA:

```yaml
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    builtin: {}
```

You can apply this configuration with `kumactl apply -f [file-path]`.

On Kubernetes with `builtin` CA:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabled: true
    ca:
      builtin: {}
```

You can apply this configuration with `kubectl apply -f [file-path]`.

Along with the self-signed certificates (`builtin`), Kuma also supports third-party certificates (`provided`). To use a third-party CA, change the mesh resource to use the `provided` CA. And then you can utilize `kumactl manage ca` to add or delete your certificates

On Universal with `provided` CA:

```yaml
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    provided: {}
```

On Kubernetes with `provided` CA:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabled: true
    ca:
      provided: {}
```

::: tip
With mTLS enabled, traffic is restricted by default. Remember to apply a `TrafficPermission` policy to permit connections
between Dataplanes.
:::

## Traffic Permissions

Traffic Permissions allow you to determine security rules for services that consume other services via their [Tags](/docs/DRAFT/documentation/#tags). It is a very useful policy to increase security in the Mesh and compliance in the organization.

You can determine what source services are **allowed** to consume specific destination services. The `service` field is mandatory in both `sources` and `destinations`.

::: warning
In Kuma DRAFT the `sources` field only allows for `service` and only `service` will be enforced. This limitation will disappear in the next version of Kuma.
:::

In the example below, the `destinations` includes not only the `service` property, but also an additional `version` tag. You can include any arbitrary tags to any [`Dataplane`](/docs/DRAFT/documentation/dataplane-specification)

On Universal:

```yaml
type: TrafficPermission
name: permission-1
mesh: default
sources:
  - match:
      service: backend
destinations:
  - match:
      service: redis
      version: '5.0'
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  namespace: default
  name: permission-1
spec:
  sources:
    - match:
        service: backend
  destinations:
    - match:
        service: redis
        version: '5.0'
```

::: tip
**Match-All**: You can match any value of a tag by using `*`, like `version: '*'`.
:::

## Traffic Route

`TrafficRoute` policy allows you to configure routing rules for L4 traffic, i.e. blue/green deployments and canary releases. 

To route traffic, Kuma matches via tags that we can designate to `Dataplane` resources. In the example below, the redis destination services have been assigned the `version` tag to help with canary deployment. Another common use-case is to add a `env` tag as you separate testing, staging, and production environments' services. For the redis service, this `TrafficRoute` policy assigns a positive weight of 90 to the v1 redis service and a positive weight of 10 to the v2 redis service. Kuma utilizes positive weights in the traffic routing policy, and not percentages. Therefore, Kuma does not check if it adds up to 100. If you want to stop sending traffic to a destination service, change the weight for that service to 0.

On Universal:

```yaml
type: TrafficRoute
name: route-1
mesh: default
sources:
  - match:
      service: backend
destinations:
  - match:
      service: redis
conf:
  - weight: 90
    destination:
      service: redis
      version: '1.0'
  - weight: 10
    destination:
      service: redis
      version: '2.0'
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficRoute
mesh: default
metadata:
  namespace: default
  name: route-1
spec:
  sources:
    - match:
        service: backend
  destinations:
    - match:
        service: redis
  conf:
    - weight: 90
      destination:
        service: redis
        version: '1.0'
    - weight: 10
      destination:
        service: redis
        version: '2.0'
```

## Traffic Metrics

`Kuma` facilitates consistent traffic metrics across all dataplanes in your mesh.

A user can enable traffic metrics by editing a `Mesh` resource and providing the desired `Mesh`-wide configuration. If necessary, metrics configuration can be customized for each `Dataplane` individually, e.g. to override the default metrics port that might be already in use on that particular machine.

Out-of-the-box, `Kuma` provides full integration with `Prometheus`:
* if enabled, every dataplane will expose its metrics in `Prometheus` format
* furthemore, `Kuma` will make sure that `Prometheus` can automatically find every dataplane in the mesh

#### On Universal

##### Enable Prometheus metrics per Mesh

To enable `Prometheus` metrics on every dataplane in the mesh, configure a `Mesh` resource as follows:

```yaml
type: Mesh
name: default
metrics:
  prometheus: {}
```

which is a convenient shortcut for

```yaml
type: Mesh
name: default
metrics:
  prometheus:
    port: 5670
    path: /metrics
```

Both snippets from above instruct `Kuma` to configure every dataplane in the mesh `default` to expose an HTTP endpoint with `Prometheus` metrics on port `5670` and URI path `/metrics`.

##### Override Prometheus settings per Dataplane

To override `Mesh`-wide defaults on a particular machine, configure `Dataplane` resource as follows:

```yaml
type: Dataplane
mesh: default
name: example
metrics:
  prometheus:
    port: 1234
    path: /non-standard-path
```

As a result, this particular dataplane will expose an HTTP endpoint with `Prometheus` metrics on port `1234` and URI path `/non-standard-path`.

##### Configure dataplane discovery by Prometheus

Although dataplane metrics are now exposed, `Prometheus` doesn't know anything about it just yet.

To help `Prometheus` to automatically discover dataplanes, `Kuma` provides a helper tool - `kuma-prometheus-sd`.

::: tip
`kuma-prometheus-sd` tool is meant to be run next to `Prometheus`.

It knows where `Kuma` Control Plane is, it knows how to talk to it, it knows how to fetch an up-to-date list of dataplanes from it.

It then transforms that information into a format that `Prometheus` can understand, and saves it into a file on disk.

`Prometheus` periodically reads from that file and updates its scraping configuration accordingly.
:::

First, you need to run `kuma-prometheus-sd`, e.g. by using the following command:

```shell
kuma-prometheus-sd run \
  --cp-address=http://kuma-control-plane.internal:5681 \
  --output-file=/var/run/kuma-prometheus-sd/kuma.file_sd.json
```

The above configuration tells `kuma-prometheus-sd` to talk to `Kuma` Control Plane at [http://kuma-control-plane.internal:5681](http://kuma-control-plane.internal:5681) and save the list of dataplanes to `/var/run/kuma-prometheus-sd/kuma.file_sd.json`.

Then, you need to set up `Prometheus` to read from that file, e.g. by using `prometheus.yml` config with the following contents:

```yaml
scrape_configs:
- job_name: 'kuma-dataplanes'
  scrape_interval: 15s
  file_sd_configs:
  - refresh_interval: 1s
    files:
    - /var/run/kuma-prometheus-sd/kuma.file_sd.json
```

and running

```shell
prometheus --config.file=prometheus.yml
```

Now, if you check `Targets` page on `Prometheus` UI, you should see a list of dataplanes from your mesh, e.g.

<center>
<img src="/images/docs/0.3.2/prometheus-targets.png" alt="A screenshot of Targets page on Prometheus UI" style="width: 600px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

#### On Kubernetes

##### Enable Prometheus metrics per Mesh

To enable `Prometheus` metrics on every dataplane in the mesh, configure a `Mesh` resource as follows:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  metrics:
    prometheus: {}
```

which is a convenient shortcut for

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  metrics:
    prometheus:
      port: 5670
      path: /metrics
```

Both snippets from above instruct `Kuma` to configure every dataplane in the mesh `default` to expose an HTTP endpoint with `Prometheus` metrics on port `5670` and URI path `/metrics`.

##### Override Prometheus settings per Dataplane

To override `Mesh`-wide defaults for a particular `Pod`, use `Kuma`-specific annotations:
* `prometheus.metrics.kuma.io/port` - to override `Mesh`-wide default port
* `prometheus.metrics.kuma.io/path` - to override `Mesh`-wide default path

E.g.,

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: kuma-example
  name: kuma-tcp-echo
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        prometheus.metrics.kuma.io/port: "1234"               # override Mesh-wide default port
        prometheus.metrics.kuma.io/path: "/non-standard-path" # override Mesh-wide default path
    spec:
      containers:
      ...
```

As a result, dataplane for this particular `Pod` will expose an HTTP endpoint with `Prometheus` metrics on port `1234` and URI path `/non-standard-path`.

##### Configure dataplane discovery by Prometheus

On `kubernetes`, `Kuma` will automatically annotate your `Pod` to be discovered by `Prometheus`, e.g.

```yaml
apiVersion: v1
kind: Pod
metadata:
  namespace: kuma-example
  name: kuma-tcp-echo
  annotations:
    prometheus.io/scrape: "true"   # will be automatically added by Kuma
    prometheus.io/port: "5670"     # will be automatically added by Kuma
    prometheus.io/path: "/metrics" # will be automatically added by Kuma
spec:
  containers:
  ...
```

Notice usage of `prometheus.io/*` annotations to indicate where `Prometheus` should scrape metrics from.

::: warning
Beware that `Prometheus` itself doesn't have any knowledge about `prometheus.io/*` annotations.

Instead, they're a part of configuration, which might differ from one `Prometheus` installation to another.

In particular, `prometheus.io/*` annotations are part of configuration used by `Prometheus` [Helm chart](https://github.com/helm/charts/tree/master/stable/prometheus).

If you're using a different way to install `Prometheus` on `kubernetes`, those annotations might not have the desired effect.
:::

## Traffic Tracing

::: warning
This is a proposed policy not in GA yet. You can setup tracing manually by leveraging the [`ProxyTemplate`](#proxy-template) policy and the low-level Envoy configuration. Join us on [Slack](/community) to share your tracing requirements.
:::

The proposed policy will enable `tracing` on the [`Mesh`](#mesh) level by adding a `tracing` field.

On Universal:

```yaml
type: Mesh
name: default
tracing:
  enabled: true
  type: zipkin
  address: zipkin.srv:9000
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  tracing:
    enabled: true
    type: zipkin
    address: zipkin.srv:9000
```

## Traffic Log

With the `TrafficLog` policy you can configure access logging on every Envoy data-plane belonging to the [`Mesh`](#mesh). These logs can then be collected by any agent to be inserted into systems like Splunk, ELK and Datadog.
The first step is to configure backends for the `Mesh`. A backend can be either a file or a TCP service (like Logstash). Second step is to create a `TrafficLog` entity to select connections to log.

On Universal:

```yaml
type: Mesh
name: default
mtls:
  ca:
    builtin: {}
  enabled: true
logging:
  defaultBackend: file
  backends:
    - name: logstash
      format: |
        {
            "destination": "%UPSTREAM_CLUSTER%",
            "destinationAddress": "%UPSTREAM_LOCAL_ADDRESS%",
            "source": "%KUMA_DOWNSTREAM_CLUSTER%",
            "sourceAddress": "%DOWNSTREAM_REMOTE_ADDRESS%",
            "bytesReceived": "%BYTES_RECEIVED%",
            "bytesSent": "%BYTES_SENT%"
        }
      tcp:
        address: 127.0.0.1:5000
    - name: file
      file:
        path: /tmp/access.log
```

```yaml
type: TrafficLog
name: all-traffic
mesh: default
sources:
  - match:
      service: '*'
destinations:
  - match:
      service: '*'
# if omitted, the default logging backend of that mesh will be used
```

```yaml
type: TrafficLog
name: backend-to-database-traffic
mesh: default
sources:
  - match:
      service: backend
destinations:
  - match:
      service: database
conf:
  backend: logstash
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    ca:
      builtin: {}
    enabled: true
  logging:
    defaultBackend: file
    backends:
      - name: logstash
        format: |
          {
              "destination": "%UPSTREAM_CLUSTER%",
              "destinationAddress": "%UPSTREAM_LOCAL_ADDRESS%",
              "source": "%KUMA_DOWNSTREAM_CLUSTER%",
              "sourceAddress": "%DOWNSTREAM_REMOTE_ADDRESS%",
              "bytesReceived": "%BYTES_RECEIVED%",
              "bytesSent": "%BYTES_SENT%"
          }
        tcp:
          address: 127.0.0.1:5000
      - name: file
        file:
          path: /tmp/access.log
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-system
  name: all-traffic
spec:
  sources:
    - match:
        service: '*'
  destinations:
    - match:
        service: '*'
  # if omitted, the default logging backend of that mesh will be used
```

```yaml
apiVersion: kuma.io/v1alpha1
kind: TrafficLog
metadata:
  namespace: kuma-system
  name: backend-to-database-traffic
spec:
  sources:
    - match:
        service: backend
  destinations:
    - match:
        service: database
  conf:
    backend: logstash
```

::: tip
If a backend in `TrafficLog` is not explicitly specified, the `defaultBackend` from `Mesh` will be used.
:::

In the `format` field, you can use [standard Envoy placeholders](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log) for TCP as well as a few additional placeholders:

- `%KUMA_SOURCE_ADDRESS%` - source address of the Dataplane
- `%KUMA_SOURCE_SERVICE%` - source service from which traffic is sent
- `%KUMA_DESTINATION_SERVICE%` - destination service to which traffic is sent

## Health Check

The goal of Health Checks is to minimize the number of failed requests due to temporary unavailability of a target endpoint.
By applying a Health Check policy you effectively instruct a dataplane to keep track of health statuses for target endpoints.
Dataplane will never send a request to an endpoint that is considered "unhealthy".

Since pro-active health checking might result in a tangible extra load on your applications,
Kuma also provides a zero-overhead alternative - ["passive" health checking](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier).
In the latter case, a dataplane will be making decisions whether target endpoints are healthy based on "real" requests
initiated by your application rather than auxiliary requests initiated by the dataplanes itself.

As usual, `sources` and `destinations` selectors allow you to fine-tune to which `Dataplanes` the policy applies (`sources`)
and what endpoints require health checking (`destinations`).

At the moment, `HealthCheck` policy is implemented at L4 level. In practice, it means that a dataplane is looking at success of TCP connections
rather than individual HTTP requests.

On Universal:

```yaml
type: HealthCheck
name: web-to-backend
mesh: default
sources:
- match:
    service: web
destinations:
- match:
    service: backend
conf:
  activeChecks:
    interval: 10s
    timeout: 2s
    unhealthyThreshold: 3
    healthyThreshold: 1
  passiveChecks:
    unhealthyThreshold: 3
    penaltyInterval: 5s
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: HealthCheck
metadata:
  namespace: kuma-example
  name: web-to-backend
mesh: default
spec:
  sources:
  - match:
      service: web
  destinations:
  - match:
      service: backend
  conf:
    activeChecks:
      interval: 10s
      timeout: 2s
      unhealthyThreshold: 3
      healthyThreshold: 1
    passiveChecks:
      unhealthyThreshold: 3
      penaltyInterval: 5s
```

## Proxy Template

With the `ProxyTemplate` policy you can configure the low-level Envoy resources directly. The policy requires two elements in its configuration:

- `imports`: this field lets you import canned `ProxyTemplate`s provided by Kuma.
  - In the current release, the only available canned `ProxyTemplate` is `default-proxy`
  - In future releases, more of these will be available and it will also be possible for the user to define them to re-use across their infrastructure
- `resources`: the custom resources that will be applied to every [`Dataplane`]() that matches the `selectors`.

On Universal:

```yaml
type: ProxyTemplate
mesh: default
name: template-1
selectors:
  - match:
      service: backend
conf:
  imports:
    - default-proxy
  resources:
    - ..
    - ..
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ProxyTemplate
mesh: default
metadata:
  namespace: default
  name: template-1
spec:
  selectors:
    - match:
        service: backend
  conf:
    imports:
      - default-proxy
    resources:
      - ..
      - ..
```

Below you can find an example of what a `ProxyTemplate` configuration could look like:

```yaml
  imports:
    - default-proxy
  resources:
    - name: localhost:9901
      version: v1
      resource: |
        '@type': type.googleapis.com/envoy.api.v2.Cluster
        connectTimeout: 5s
        name: localhost:9901
        loadAssignment:
          clusterName: localhost:9901
          endpoints:
          - lbEndpoints:
            - endpoint:
                address:
                  socketAddress:
                    address: 127.0.0.1
                    portValue: 9901
        type: STATIC
    - name: inbound:0.0.0.0:4040
      version: v1
      resource: |
        '@type': type.googleapis.com/envoy.api.v2.Listener
        name: inbound:0.0.0.0:4040
        address:
          socket_address:
            address: 0.0.0.0
            port_value: 4040
        filter_chains:
        - filters:
          - name: envoy.http_connection_manager
            config:
              route_config:
                virtual_hosts:
                - routes:
                  - match:
                      prefix: /stats/prometheus
                    route:
                      cluster: localhost:9901
                  domains:
                  - '*'
                  name: envoy_admin
              codec_type: AUTO
              http_filters:
                name: envoy.router
              stat_prefix: stats
```

## General notes about Kuma policies

You may have already noticed that most `Kuma` policies have very similar structure, namely

```yaml
sources:
- match:
    service: ... # unique name OR '*'
    ... # (optionally) other tags

destinations:
- match:
    service: ... # unique name OR '*'
    ... # (optionally) other tags

conf:
  ... # policy-specific configuration
```

where

* `sources` - a list of selectors to match those `Dataplanes` where network traffic originates
* `destinations` - a list of selectors to match those `Dataplanes` where network traffic destined at
* `conf` - configuration to apply to network traffic between `sources` and `destinations`

To keep configuration model simple and consistent, `Kuma` assumes that every `Dataplane` represents a `service`, even if it's a cron job that doesn't normally handle incoming traffic.

Consequently, `service` tag is mandatory for `sources` and `destinations` selectors.

If you need your policy to apply to every connection between `Dataplane`s, or simply don't know yet what is the right scope for that policy, you can always use `'*'` (wildcard) instead if the exact value.

E.g., the following policy will apply to network traffic between all `Dataplane`s

```yaml
sources:
- match:
    service: '*'

destinations:
- match:
    service: '*'

conf:
  ...
```

In contrast, the next policy will apply only to network traffic between  `Dataplane`s that represent `web` and `backend` services:

```yaml
sources:
- match:
    service: web

destinations:
- match:
    service: backend

conf:
  ...
```

Finally, you can further limit the scope of a policy by including additional tags into `sources` and `destinations` selectors:

```yaml
sources:
- match:
    service: web
    cloud:   aws
    region:  us

destinations:
- match:
    service: backend
    version: v2      # notice that not all policies support arbitrary tags in `destinations` selectors

conf:
  ...
```

::: warning
While all policies support arbitrary tags in `sources` selectors, it's not generally the case for `destinations` selectors.

E.g., policies that get appied on the client side of a connection between 2 `Dataplane`s - such as `TrafficRoute`, `TrafficLog`, `HealthCheck` - only support `service` tag in `destinations` selectors.

In some cases there is a fundamental technical cause for that (e.g., `TrafficRoute`), in other cases it's a simplification of the initial implementation (e.g., `TrafficLog` and `HealthCheck`).

Please let us know if such constraints become critical to your use case.
:::

## How Kuma chooses the right policy to apply

At any single moment, there might be multiple policies (of the same type) that match a connection between `sources` and `destinations` `Dataplane`s.

E.g., there might be a catch-all policy that sets the baseline for your organization

```yaml
type: TrafficLog
mesh: default
name: catch-all-policy
sources:
  - match:
      service: '*'
destinations:
  - match:
      service: '*'
conf:
  backend: logstash
```

Additionally, there might be a more focused use case-specific policy, e.g.

```yaml
type: TrafficLog
mesh: default
name: web-to-backend-policy
sources:
  - match:
      service: web
      cloud:   aws
      region:  us
destinations:
  - match:
      service: backend
conf:
  backend: splunk
```

What does `Kuma` do when it encounters multiple matching policies ?

The answer depends on policy type:

* since `TrafficPermission` represents a grant of access given to a particular client `service`, `Kuma` conceptually "aggregates" all such grants by applying ALL `TrafficPermission` policies that match a connection between `sources` and `destinations` `Dataplane`s
* for other policy types - `TrafficRoute`, `TrafficLog`, `HealthCheck` - conceptual "aggregation" would be too complex for users to always keep in mind; that is why `Kuma` chooses and applies only "the most specific" matching policy in that case

Going back to 2 `TrafficLog` policies described above:
* for connections between `web` and `backend` `Dataplanes` `Kuma` will choose and apply `web-to-backend-policy` policy as "the most specific" in that case
* for connections between all other dataplanes `Kuma` will choose and apply `catch-all-policy` policy as "the most specific" in that case

"The most specific" policy is defined according to the following rules:

1. a policy that matches a connection between 2 `Dataplane`s by a greater number of tags is "more specific"

   E.g., `web-to-backend-policy` policy matches a connection between 2 `Dataplane`s by 4 tags (3 tags on `sources` and 1 tag on `destinations`), while `catch-all-policy` matches only by 2 tags (1 tag on `sources` and 1 tag on `destinations`)
2. a policy that matches by the exact tag value is more specific than policy that matches by a `'*'` (wildcard) tag value

   E.g., `web-to-backend-policy` policy matches `sources` by `service: web`, while `catch-all-policy` matches by `service: *`

3. if 2 policies match a connection between 2 `Dataplane`s by the same number of tags, then the one with a greater total number of matches by the exact tag value is "more specific" than the other

4. if 2 policies match a connection between 2 `Dataplane`s by the same number of tags, and the total number of matches by the exact tag value is the same for both policies, and the total number of matches by a `'*'` (wildcard) tag value is the same for both policies, then a "more specific" policy is the one whoose name comes first when ordered alphabetically

E.g.,

1. match by a greater number of tags

   ```yaml
   sources:
     - match:
         service: '*'
         cloud:   aws
         region:  us
   destinations:
     - match:
         service: '*'
   ```

   is "more specific" than

   ```yaml
   sources:
     - match:
         service: '*'
   destinations:
     - match:
         service: '*'
   ```

2. match by the exact tag value

   ```yaml
   sources:
     - match:
         service: web
   destinations:
     - match:
         service: backend
   ```

   is "more specific" than a match by a `'*'` (wildcard)

   ```yaml
   sources:
     - match:
         service: '*'
   destinations:
     - match:
         service: '*'
   ```

3. match with a greater total number of matches by the exact tag value

   ```yaml
   sources:
     - match:
         service: web
         version: v1
   destinations:
     - match:
         service: backend
   ```

   is "more specific" than

   ```yaml
   sources:
     - match:
         service: web
         version: '*'
   destinations:
     - match:
         service: backend
   ```

4. when 2 matches are otherwise "equally specific"

   ```yaml
   name: policy-1
   sources:
     - match:
         service: web
         version: v1
   destinations:
     - match:
         service: backend
   ```

   `policy-1` is considered "more specific" only due to the alphabetical order of names `"policy-1"` and `"policy-2"`

   ```yaml
   name: policy-2
   sources:
     - match:
         service: web
   destinations:
     - match:
         service: backend
         cloud:   aws
   ```
