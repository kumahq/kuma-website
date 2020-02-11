# Traffic Metrics

`Kuma` facilitates consistent traffic metrics across all dataplanes in your mesh.

A user can enable traffic metrics by editing a `Mesh` resource and providing the desired `Mesh`-wide configuration. If necessary, metrics configuration can be customized for each `Dataplane` individually, e.g. to override the default metrics port that might be already in use on that particular machine.

Out-of-the-box, `Kuma` provides full integration with `Prometheus`:
* if enabled, every dataplane will expose its metrics in `Prometheus` format
* furthemore, `Kuma` will make sure that `Prometheus` can automatically find every dataplane in the mesh

## On Universal

### Enable Prometheus metrics per Mesh

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

### Override Prometheus settings per Dataplane

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

### Configure dataplane discovery by Prometheus

Although dataplane metrics are now exposed, `Prometheus` doesn't know anything about it just yet.

To help `Prometheus` to automatically discover dataplanes, `Kuma` provides a helper tool - `kuma-prometheus-sd`.

::: tip
`kuma-prometheus-sd` is meant to run alongside `Prometheus` instance.

It knows where `Kuma` Control Plane is, it knows how to talk to it, it knows how to fetch an up-to-date list of dataplanes from it.

It then transforms that information into a format that `Prometheus` can understand, and saves it into a file on disk.

`Prometheus` watches for changes to that file and updates its scraping configuration accordingly.
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
  - files:
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

## On Kubernetes

### Enable Prometheus metrics per Mesh

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

### Override Prometheus settings per Dataplane

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

### Configure dataplane discovery by Prometheus

On `kubernetes`, there are two ways of configuring dataplane discovery.

### Annotations

`Kuma` will automatically annotate your `Pod` to be discovered by `Prometheus`, e.g.

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

Although it's easy and works without any extra configuration, those annotations supports only one address to scrape.
If you also have an application next to Kuma DP which exposes metrics through `prometheus.io/*` annotations,
you have to use the other way to expose metrics for both the application and Kuma DP.

### Kuma Prometheus SD

You can deploy `kuma-prometheus-sd` container next to you Prometheus instance just like in Universal setup.

First, add a volume to your Prometheus deployment to which `kuma-prometheus-sd` will write a file with the list of the dataplanes and from which `Prometheus` will read the list.

```yaml
volumes:
- name: kuma-prometheus-sd-volume
  emptyDir: {}
```

Then add a new container with `kuma-prometheus-sd`. It will connect to the control plane at given address and produce file to `/var/run/kuma.io/prometheus-sd/kuma.file_sd.json` in created volume.

```yaml
  containers:
- name: kuma-prometheus-sd
  image: kong-docker-kuma-docker.bintray.io/kuma-prometheus-sd:0.3.2
  imagePullPolicy: Always
  args:
    - run
    - --name=kuma-prometheus-sd
    - --cp-address=http://kuma-control-plane.kuma-system:5681
    - --output-file=/var/run/kuma.io/prometheus-sd/kuma.file_sd.json
  volumeMounts:
    - mountPath: "/var/run/kuma.io/prometheus-sd"
      name: kuma-prometheus-sd-volume
```

Next step is to mount the volume to the Prometheus container
```yaml
volumeMounts:
- mountPath: "/var/run/kuma.io/prometheus-sd"
  name: kuma-prometheus-sd-volume
```

Finally, modify your Prometheus config to use generated file
```yaml
- job_name: 'kuma-dataplanes'
  scrape_interval: "5s"
  file_sd_configs:
  - files:
    - /var/run/kuma.io/prometheus-sd/kuma.file_sd.json
```

Refer to full example of the [deployment](/snippets/prom-deployment-with-kuma-sd.yaml) and the [configuration](/snippets/prom-configmap.yaml).

In this way of integrating Kuma with Prometheus, you can still use `prometheus.io/*` for your applications.