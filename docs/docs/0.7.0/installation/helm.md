# Helm

Kuma support a fully automated way to manage its deplyment lifecycle on Kubernetes through [helm charts](https://kumahq.github.io/charts).

### Adding the Kuma charts repo

Follow this simple command to add the Kuma charts repository to your local helm deployment:

```bash
helm repo add kuma https://kumahq.github.io/charts
```

Once the repo is added, all following updates can be fetched with `helm repo update`.

### Installing the basic standalone mode

Note that the Helm charts do not create the namespace. We are using `kuma-system` here, but it can be replaced with any Kubernetes compliant namespace: 

```bash
kubectl create namespace kuma-system
helm install --namespace kuma-system kuma kuma/kuma
```

### Installing Kuma in a distribute mode

The provided Helm charts, do support installing Kuma in a [`Multi-zone Mode`](../documentation/deployments/#multi-zone-mode).

#### Global Control Plane
To install the Global Control Plane, just set the `controlPlane.mode` value to `global` when installing the chart. That can be in a provided value file or on the command line:
```bash
helm install kuma --namespace kuma-system --set controlPlane.mode=global kuma/kuma
```

#### Remote Control Plane
Similarly, to install the Remote Control plane we need to provide `controlPlane.mode=remote`,`controlPlane.zone=<zone-name>`, `ingress.enabled=true` and `controlPlane.kdsGlobalAddress=grpcs://<global-kds-address>`

```bash
helm install kuma --namespace kuma-system --set controlPlane.mode=remote,controlPlane.zone=zone-1,ingress.enabled=true,controlPlane.kdsGlobalAddress=grpcs://10.0.0.1:5685  kuma/kuma
```

### More settings
For more information on the available parameters fetch the README content from the chart in the Helm repo:

```bash
helm show readme kuma/kuma
```

Make sure you use the latest version of the chart by running `helm repo update`.
