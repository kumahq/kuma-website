---
sidebar: true
home: true
search: false

# custom page data
testimonialPortraitSrc: /marco-cropped.jpg
testimonialPortraitAlt: Marco Palladino
---

<!-- page masthead -->

::: slot masthead-main-title
# Secure, Observe and Extend your modern L4/L7 Service Mesh
:::

::: slot masthead-sub-title
## The open-source platform for your Service Mesh, delivering high performance and reliability.
:::

<!-- feature blocks -->

::: slot feature-block-content-1
### Universal Control Plane
Built on top of Envoy, Karavan is a universal cloud-native control plane to
orchestrate L4/L7 traffic, including Microservices and Service Mesh.
:::

::: slot feature-block-content-2
### Policy Oriented
Ingress and Service Mesh management policies for security, tracing, 
routing, and observability out of the box. Decoupled and extensible.
:::

::: slot feature-block-content-3
### Runs anywhere
Karavan natively supports Kubernetes via CRDs, Virtual Machines and Bare Metal 
infrastructures via a REST API. Karavan is built for every team in the organization.
:::

<!-- steps -->

::: slot steps-title
## Build your Service Mesh in 3 easy steps
:::

::: slot step-1-content
### Download and Install Karavan CP
To get started you can download Karavan and install it using the Karavan CLI application: `karavanctl`.
:::

::: slot step-1-code-block
``` bash
$ karavanctl install control-plane | kubectl apply -f
```
:::

::: slot step-2-content
### Install the sidecar Envoy DP
Once Karavan is up and running, it's now time to install the Envoy sidecars - that Karavan will 
later orchestrate - next to any service we want to include into our Service Mesh.
:::

::: slot step-2-code-block
``` bash
$ karavanctl install data-plane | kubectl apply -f
```
:::

::: slot step-3-content
### Apply Policies
Congratulations, your Service Mesh is up and running. We can now instruct Karavan to enhance our 
Service Mesh with powerful policies like mTLS.
:::

::: slot step-3-code-block
``` bash
$ karavanctl create policy \
  --name mtls \
  --conf topology=hybrid
```
:::


<!-- testimonial -->

::: slot testimonial-content
A control plane built for Envoy by Envoy contributors, that brings traffic management
to the modern era.
:::

::: slot testimonial-author
Marco Palladino,
:::

::: slot testimonial-author-info
CTO, [Kong, Inc.](https://twitter.com/thekonginc)
:::