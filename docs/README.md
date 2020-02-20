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
---

::: slot news

Join us on Zoom February 25 at 5PM PST for our next Kuma Online Meetup! [Register Now!](https://zoom.us/meeting/register/uJUrc-ygqTgsdRJzMWnV4LVb7-RkEFRnlg)

:::

<!-- page masthead -->

::: slot masthead-main-title

# The modern control plane<br> for reliable service connectivity

:::

::: slot masthead-sub-title

## The open-source control plane for modern connectivity, delivering high performance and reliability with Envoy.

:::

::: slot masthead-diagram
![Kuma service diagram](/images/diagrams/main-diagram@2x.png)
:::

<!-- feature blocks -->

::: slot feature-block-content-1

### CRD + RESTful Interface

![CRD + RESTful Interface diagram](/images/diagrams/v2/diagram-crd-rest@2x.png)

Built on top of Envoy, Kuma can be fully operated via simple CRDs on Kubernetes or with a RESTful API on other platforms. GUI included.

:::

::: slot feature-block-content-2

### L4 + L7 Policies

![L4 and L7 Policies chart](/images/diagrams/v2/diagram-l4-l7-policies@2x.png)

Connect your Microservices with Kuma, and apply intuitive policies for security, observability, routing, and more in one command.
:::

::: slot feature-block-content-3

### Platform Agnostic

![Platform Agnostic diagram](/images/diagrams/v2/diagram-platform-agnostic@2x.png)

Kuma can run anywhere, on Kubernetes and VMs, in the cloud or on-premise, in single or multi-datacenter setups.
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

::: slot feature-focus-1-content
### Start in minutes, not in days

Getting up and running with Kuma only requires three easy steps. Bundled with Envoy proxy, Kuma Delivers zero-configuration policies that can secure, observe, connect, route, log and enhance your service connectivity for the entire application, databases included.

* Bundled with Envoy Proxy
* 10+ Policies ready to use
* For every L4/L7 traffic
:::

::: slot feature-focus-1-diagram
![Connectivity with no boundaries diagram](/images/diagrams/v2/diagram-speed-chart@2x.png)
:::

::: slot feature-focus-2-content
### Connectivity with no boundaries

With Kuma you can build service connectivity and Service Meshes across a large variety of platforms  and clouds. Platform agnostic by nature, Kuma supports modern Kubernetes environments and Virtual Machine workloads in the same cluster, with no effort.

* K8s + VM native
* Ingress and esh
* HA, Distributed, Multicloud
:::

::: slot feature-focus-2-diagram
![Diagram outlining connectivity with no boundaries](/images/diagrams/v2/diagram-connectivity@2x.png)
:::

::: slot feature-focus-3-content
### One cluster for the entire organization

Getting up and running with Kuma only requires three easy steps. Bundled with Envoy proxy, Kuma Delivers zero-configuration policies that can secure, observe, connect, route, log and enhance your service connectivity for the entire application, databases included.

* Multi-Tenant
* Ops complexity is 0(1), not 0(n)
* One Runtime, scalable horizontally
:::

::: slot feature-focus-3-diagram
![Diagram outlining one cluster for the entire organization](/images/diagrams/v2/diagram-org-cluster@2x.png)
:::

<!-- newsletter -->

::: slot newsletter-title

## Get Community Updates

:::

::: slot newsletter-content
Sign up for our Kuma community newsletter to get the most recent updates and product announcements.
:::
