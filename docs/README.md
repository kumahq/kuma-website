---
sidebar: true
home: true
search: false
pageClass: is-home

# page meta
meta:
  - name: keywords
    content: service mesh microservices open-source

# custom page data
testimonialPortraitSrc: /images/luca-maraschi-cropped@2x.png
testimonialPortraitAlt: Portrait photo of Luca Maraschi
showTestimonial: true # change this to `true` if you want to display the testimonial
showNews: true # change this to `true` if you want to display the news bar
startText: Get Started
startUrl: /install/
whyText: Why Kuma?
whyUrl: /docs/latest/overview/why-kuma/

# tabs
tabs:
  - hash: "#kubernetes"
    title: Kubernetes
  - hash: "#openshift"
    title: OpenShift
  - hash: "#universal"
    title: Universal (VMs)
---

::: slot news

**Kuma 0.7 has been released!** Improved multi-zone deployments, ProxyTemplate policy v2.0, StatefulSet support and more! &mdash; [Get Started](/install/)

:::

<!-- page masthead -->

::: slot masthead-main-title

# The modern control plane<br> for reliable service connectivity

:::

::: slot masthead-sub-title

## The open-source control plane for modern connectivity, <br>delivering high performance and reliability with Envoy.

:::

::: slot masthead-diagram
![Kuma service diagram](/images/diagrams/main-diagram@2x.png)
:::

<!-- feature blocks -->

::: slot feature-block-content-1

### CRD + RESTful Interface

![CRD + RESTful Interface diagram](/images/diagrams/v2/diagram-crd-rest@2x.png)

Built on top of Envoy, Kuma is a modern control plane to orchestrate L4 / L7 traffic, including Microservices and Service Mesh.
:::

::: slot feature-block-content-2

### L4 + L7 Policies

![L4 and L7 Policies chart](/images/diagrams/v2/diagram-l4-l7-policies@2x.png)

Out of the box Ingress and Service Mesh service management policies for security, observability, routing, and more.
:::

::: slot feature-block-content-3

### Platform Agnostic

![Platform Agnostic diagram](/images/diagrams/v2/diagram-platform-agnostic@2x.png)

Enterprise-ready and platform agnostic with native Kubernetes + CRD support, as well as VM and Bare Metal via YAML + REST.
:::

<!-- testimonial -->

::: slot testimonial-content
Kuma reduces complexity and accelerates service reliability with an Envoy-based Service Mesh
:::

::: slot testimonial-author
Luca Maraschi
:::

::: slot testimonial-author-info
Chief Architect at Telus Digital
:::

<!-- tabs -->

::: slot tab-kubernetes

[Install Kuma](/install/) via an available distribution:

``` sh
$ kumactl install control-plane \
  | kubectl apply -f-
```

Visualize the GUI to see your cluster:

``` sh
$ kubectl port-forward svc/kuma-control-plane \
  -n kuma-system 5683:5683
```

Navigate to [127.0.0.1:5683](http://127.0.0.1:5683) to see the GUI.

:::

::: slot tab-openshift

[Install Kuma](/install/) via an available distribution:

``` sh
$ kumactl install control-plane \
  --cni-enabled | oc apply -f -
```

Visualize the GUI to see your cluster:

``` sh
$ oc port-forward svc/kuma-control-plane \
  -n kuma-system 5683:5683
```

Navigate to [127.0.0.1:5683](http://127.0.0.1:5683) to see the GUI.

:::

::: slot tab-universal

[Install Kuma](/install/) via an available distribution:

```sh
$ kuma-cp run
```

Navigate to [127.0.0.1:5683](http://127.0.0.1:5683) to see the GUI.

:::

::: slot tabs-right-col-content

### Start in minutes, not in days

Getting up and running with Kuma only requires three easy steps. Bundled with Envoy proxy, Kuma Delivers zero-configuration policies that can secure, observe, connect, route, log and enhance your service connectivity for the entire application, databases included.

- Bundled with Envoy Proxy
- 10+ Policies ready to use
- For every L4/L7 traffic
:::

<!-- content blocks -->

::: slot feature-focus-1-content

### Connectivity with no boundaries

With Kuma you can build service connectivity and Service Meshes across a large variety of platforms  and clouds. Platform agnostic by nature, Kuma supports modern Kubernetes environments and Virtual Machine workloads in the same cluster, with no effort. 

- K8s + VM native
- Ingress and Mesh
- HA, Distributed, Multicloud
:::

::: slot feature-focus-1-diagram
![Diagram outlining connectivity with no boundaries](/images/diagrams/v2/diagram-connectivity@2x.png)
:::

::: slot feature-focus-2-content

### One cluster for the entire organization

Getting up and running with Kuma only requires three easy steps. Bundled with Envoy proxy, Kuma Delivers zero-configuration policies that can secure, observe, connect, route, log and enhance your service connectivity for the entire application, databases included.

- Multi-Tenant
- Ops complexity is O(1), not O(n)
- One Runtime, scalable horizontally
:::

::: slot feature-focus-2-diagram
![Diagram outlining one cluster for the entire organization](/images/diagrams/v2/diagram-org-cluster@2x.png)
:::

<!-- newsletter -->

::: slot newsletter-title

## Get Community Updates

:::

::: slot newsletter-content
Sign up for our Kuma community newsletter to get the most recent updates and product announcements.
:::
