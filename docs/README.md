---
sidebar: true
home: true
search: false

# custom page data
testimonialPortraitSrc: /images/marco-cropped.jpg
testimonialPortraitAlt: Marco Palladino
---

<!-- page masthead -->

::: slot masthead-main-title
# Build, Secure and Observe your modern L4/L7 Service Mesh
:::

::: slot masthead-sub-title
## The open-source control plane for your Service Mesh, delivering high performance and reliability.
:::

::: slot masthead-diagram
<img src="/images/diagrams/main-diagram.png" srcset="/images/diagrams/main-diagram@2x.png 2x" alt="Konvoy service diagram">
:::

<!-- feature blocks -->

::: slot feature-block-content-1
### Universal Control Plane
<img src="/images/diagrams/diagram-universal-cp.jpg" srcset="/images/diagrams/diagram-universal-cp@2x.jpg 2x" alt="Universal Control Plane diagram">

Built on top of Envoy, Konvoy is a modern control plane to orchestrate L4/L7 traffic, including Microservices and Service Mesh.
:::

::: slot feature-block-content-2
### Easy to Use
<img src="/images/diagrams/diagram-powerful-policies.jpg" srcset="/images/diagrams/diagram-powerful-policies@2x.jpg 2x" alt="Universal Control Plane diagram">

Out of the box Ingress and Service Mesh service management policies for security, observability, routing, and more.
:::

::: slot feature-block-content-3
### Platform Agnostic
<img src="/images/diagrams/diagram-platform-agnostic.jpg" srcset="/images/diagrams/diagram-platform-agnostic@2x.jpg 2x" alt="Platform Agnostic diagram">

Enterprise-ready and platform agnostic with native Kubernetes + CRD support, as well as VM and Bare Metal via YAML + REST.
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
CTO, [Kong, Inc.](https://konghq.com/)
:::

<!-- steps -->

::: slot steps-title
## Build your Service Mesh in 3 easy steps
:::

::: slot step-1-content
### Download and Install Konvoy CP
To get started you can download Konvoy and install it using the Konvoy CLI application: `Konvoyctl`.
:::

::: slot step-1-code-block
```
$ Konvoyctl install control-plane | kubectl apply -f
```
:::

::: slot step-2-content
### Install the sidecar Envoy DP
Once Konvoy is up and running, it's now time to install the Envoy sidecars - that Konvoy will 
later orchestrate - next to any service we want to include into our Service Mesh.
:::

::: slot step-2-code-block
```
$ Konvoyctl install data-plane | kubectl apply -f
```
:::

::: slot step-3-content
### Apply Policies
Congratulations, your Service Mesh is up and running. We can now instruct Konvoy to enhance our 
Service Mesh with powerful policies like mTLS.
:::

::: slot step-3-code-block
```
$ Konvoyctl create policy \
  --name mtls \
  --conf topology=hybrid
```
:::

<!-- before and after -->

::: slot before-after-title
## Unparalleled Productivity
:::

::: slot before-after-diagram-1
<img src="/images/diagrams/diagram-before.jpg" srcset="/images/diagrams/diagram-before@2x.jpg 2x" alt="Before implementing Konvoy">
:::

::: slot before-after-diagram-2
<img src="/images/diagrams/diagram-after.jpg" srcset="/images/diagrams/diagram-after@2x.jpg 2x" alt="After implementing Konvoy">
:::

<!-- newsletter -->

::: slot newsletter-title
## Get Community Updates
:::

::: slot newsletter-content
Sign up to our Konvoy community newsletter to get the most recent updates and product announcements
:::