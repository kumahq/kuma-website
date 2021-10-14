# Configuration

Kuma has several parts that are configured separately.

## kuma-cp

The control plane can be configured in two ways
1) By environment variables
2) By YAML configuration file

Environment variables take precedence over a YAML configuration file.

You can find a reference configuration in the `conf/kuma-cp.conf.yml` file distributed with the Kuma package.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes (kumactl)"
When installing control plane via `kumactl`, you can override configuration with `--env-var` flag. For example
```sh
$ kumactl install control-plane \
  --env-var KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL=5s \
  --env-var KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL=5s | kubactl apply -f -
```
:::
::: tab "Kubernetes (HELM)"
When installing control plane via kumactl, you can override configuration with `envVars` key. For example
```sh
$ helm install \
  --set controlPlane.envVars.KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL=5s \
  --set controlPlane.envVars.KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL=5s \
  kuma kuma/kuma
```

or with `Values.yaml` file
```yaml
$ cat Values.yaml 
controlPlane:
  envVars:
    KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL: 5s
    KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL: 5s
$ helm install -f Values.yaml kuma kuma/kuma
```
:::
::: tab "Universal"
Before running `kuma-cp` provide a config file

```sh
$ cat kuma-cp.conf.overrides.yml
xdsServer:
  dataplaneConfigurationRefreshInterval: 5s
  dataplaneStatusFlushInterval: 5s
$ kuma-cp run -c kuma-cp.conf.overrides.yml
```

or provide environment variables

```sh
$ KUMA_XDS_SERVER_DATAPLANE_CONFIGURATION_REFRESH_INTERVAL=5s \
  KUMA_XDS_SERVER_DATAPLANE_STATUS_FLUSH_INTERVAL=5s \
  kuma-cp run
```
:::
::::

::: tip
If you configure `kuma-cp` with a YAML file, make sure to provide only values that you want to override.
Otherwise, upgrading Kuma might be harder, because you need to keep track of your changes when replacing this file on every upgrade.
:::

### Inspecting the configuration

Configuration of `kuma-cp` is logged when `kuma-cp` runs.

Additionally, you can fetch the configuration using Kuma API Server
```sh
$ curl http://<CP_ADDRESS>:5681/config
```
The configuration is also visible in the Diagnostic tab in the bottom left corner of the GUI.

In multizone deployment, Zone CP sends its config to Global CP so you can inspect all configurations using either `kumactl inspect zones -oyaml` or Zone tab in the GUI.

## kuma-dp

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Kubernetes"
In Kubernetes, `kuma-dp` is automatically configured and injected by Kubernetes.
To override the settings of injected `kuma-dp` sidecars, you need to configure `kuma-cp`.
For all the available settings, inspect the `runtime.kubernetes.injector.sidecarContainer` branch of `kuma-cp` configuration.
:::
::: tab "Universal"
`kuma-dp` is configured via command line arguments. Run `kuma-dp run -h` to inspect all available settings.
:::
::::

### Inspecting the configuration

Configuration of `kuma-dp` is logged when `kuma-dp` runs.

## kumactl

The configuration is stored in `$HOME/.kumactl/config`, which is created on the first run of `kumactl`. 
When you add a new control plane with `kumactl config control-planes add`, the file mentioned above is updated.
If you wish to change the path of the configuration file, run `kumactl` with `--config-file /new-path/config`.

### Inspecting the configuration

You can view the current configuration using `kumactl config view`.
