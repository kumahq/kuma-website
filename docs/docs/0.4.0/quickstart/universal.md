# Quickstart in Universal Mode

Congratulations! Now that you have [installed](/install) Kuma, you can get up and running with a few easy steps.

:::tip
Kuma can run in both **Kubernetes** (Containers) and **Universal** mode (for VMs and Bare Metal). You are now looking at the quickstart for Universal mode, but you can also check out the [Kubernetes one](/docs/0.4.0/quickstart/kubernetes).
:::

In order to simulate a real-world scenario, we have built a simple demo application that resembles a marketplace. In this tutorial we will:

* [1. Run the Marketplace demo](#_1-download-kuma)
* [2. Install Mutual TLS and Traffic Permissions](#_2-run-kuma)
* [3. Install Traffic Metrics](#_3-use-kuma)

To deploy the sample marketplace application with Kuma, execute the following steps:

- [Universal Quickstart](#universal-quickstart)
    - [1. Clone Demo Application](#1-clone-demo-application)
    - [2. Deploy Application](#2-deploy-application)
    - [3. Secure Application](#3-secure-application)
    - [4. Visualize Application Metrics](#4-visualize-application-metrics)

### 1. Clone Demo Application

Execute the following command to clone the demo repository which contains all necessary files

```sh
$ git clone https://github.com/Kong/kuma-demo.git
```

### 2. Deploy Application

Once cloned, you will find the contents of universal demo in the `kuma-demo/vagrant` folder. We'll be using Vagrant to deploy our application and demonstrate Kuma's capabilities in universal mode. Please follow Vagrant's installation guide to have it set up correctly before proceeding.

So we enter the `vagrant` folder by executing:

```sh
$ cd kuma-demo/vagrant
```

And we can then proceed to run the demo application with:

```sh
$ vagrant up
```
Once all the virtual machines finish provisioning, you can access the demo application at http://192.168.33.70:8000.

### 3. Secure Application

You can use the kumactl CLI to perform write operation on the Kuma mesh resource to enable mTLS. This will enable automatic encrypted mTLS traffic for all the services in a mesh. 

```sh
$ cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    builtin: {}
EOF
```

If you try to access the marketplace via http://192.168.33.70:8000, it won't work because that traffic goes through the dataplane and is now encrypted via mTLS. To enable traffic once mTLS has been enabled, please add traffic permission policies. 

Traffic Permissions allow you to determine how services communicate. It is a very useful policy to increase security in the mesh and compliance in the organization. Add the following traffic-permission for all services so the marketplace is accessible again:

```sh
$ cat <<EOF | kumactl apply -f -
type: TrafficPermission
name: permission-all
mesh: default
sources:
  - match:
      service: '*'
destinations:
  - match:
      service: '*'
EOF
```

And now if we go back to the marketplace, everything will work since we allow all services to send traffic to one another.

### 4. Visualize Application Metrics

Kuma facilitates consistent traffic metrics across all dataplanes in your mesh. To enable traffic metrics on the mesh, revise the Kuma mesh resource with kumactl CLI:

```sh
$ cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls:
  enabled: true
  ca:
    builtin: {}
metrics:
  prometheus: {}
EOF
```

Now you can visit the built in Grafana dashboard at http://192.168.33.80:3000/ to visualize the metrics scraped by Prometheus.