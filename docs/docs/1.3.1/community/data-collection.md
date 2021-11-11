# Kuma data collection

By default, Kuma collects some data about your deployment when you install. This data is sent to Kong servers.

## Disable data collection on Kubernetes

Set the following environment variable:

```
KUMA_REPORTS_ENABLED=false
```

:::: tabs
::: tab "kumactl"

Pass the environment variable to the `--env-var` argument when you install:

```shell
kumactl install control-plane \
  --env-var KUMA_REPORTS_ENABLED=false
```

:::
::: tab "Helm"

Set the environment variable:

```shell
helm install --version 0.7.1 --namespace kuma-system \
  --set controlPlane.envVars.KUMA_REPORTS_ENABLED=false \
   kuma kuma/kuma
```

:::
::::

## What data is collected

| Data field  | Definition   | 
|---|---|---|---|---|
| version  | The installed version of Kuma you're running | 
| product  |   | 
| unique_id  |   | 
| backend  | Where your config is stored. One of in memory, etcd, Postgres | 
| mode    | One of standalone or multizone |
| hostname | The hostname of your service mesh |
| signal |      | 
| cluster_id |     |
| dps_total | The total number of data plane proxies in your mesh | 
| meshes_total | The total number of meshes deployed | 
| zones_total | The total number of zones deployed | 
| internal_services | Tne total number of services running inside your meshes | 
| external_services | The total number of external services configured for your meshes |
| services_ total | The total number of services in your mesh network | 

