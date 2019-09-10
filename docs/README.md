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
testimonialPortraitSrc: /images/matt-klein-cropped@2x.jpg
testimonialPortraitAlt: Matt Klein
hideTestimonial: false # change this to `true` if you want to display the testimonial

newsTagline: Come learn and explore Kuma at Kong Summit 2019
newsLink: https://konghq.com/kong-summit
---

<!-- page masthead -->

::: slot masthead-main-title
# Build, Secure and Observe<br> your modern Service Mesh
:::

::: slot masthead-sub-title
## The open-source control plane for your Service Mesh, delivering high performance and reliability.
:::

::: slot masthead-diagram
![Kuma service diagram](/images/diagrams/main-diagram@2x.png)
:::

<!-- feature blocks -->

::: slot feature-block-content-1
### Universal Control Plane
![Universal Control Plane diagram](/images/diagrams/diagram-universal-cp@2x.jpg)

Built on top of Envoy, Kuma is a modern control plane to orchestrate L4/L7 traffic, including Microservices and Service Mesh.
:::

::: slot feature-block-content-2
### Powerful Policies
![Universal Control Plane diagram](/images/diagrams/diagram-powerful-policies@2x.jpg)

Out of the box Ingress and Service Mesh service management policies for security, observability, routing, and more.
:::

::: slot feature-block-content-3
### Platform Agnostic
![Platform Agnostic diagram](/images/diagrams/diagram-platform-agnostic@2x.jpg)

Enterprise-ready and platform agnostic with native Kubernetes + CRD support, as well as VM and Bare Metal via YAML + REST.
:::

<!-- testimonial -->

::: slot testimonial-content 
Kuma brings Kong's proven enterprise developer focus to an Envoy based service mesh, which will make it faster and easier 
for companies to create and manage cloud-native applications.
:::

::: slot testimonial-author
Matt Klein,
:::

::: slot testimonial-author-info
Envoy Proxy Creator, Engineer at Lyft
:::

<!-- tabs -->
::: slot tabs-section-title
## Get Started In 1 Minute
:::

::: slot tab-1-title
Kubernetes
:::

::: slot tab-1-content-step-1
### Start the Control Plane
After [downloading and installing Kuma](/install/0.1.0), you can start the control plane. Kuma automatically creates a `default` [Mesh](/docs/0.1.0/policies/#mesh):
:::

::: slot tab-1-code-block-step-1
```sh
$ kumactl install control-plane | kubectl apply -f -
```
:::

::: slot tab-1-content-step-2
### Deploy your Services
You can now deploy your services, which will be automatically injected with a Kuma sidecar data-plane:
:::

::: slot tab-1-code-block-step-2
```sh
$ kubectl apply -f https://raw.githubusercontent.com/Kong/kuma/master/examples/kubernetes/sample-service.yaml
```
:::

::: slot tab-1-content-step-3
### Apply Policies
You can now apply [Policies](/docs/0.1.0/policies) like Mutual TLS to encrypt the communication within the Mesh. Congratulations! You have secured your Service Mesh!
:::

::: slot tab-1-code-block-step-3
```sh
$ echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  mtls:
    enabled: true
    ca:
      builtin: {}" | kubectl apply -f -
```
:::

::: slot tab-2-title
Universal
:::

::: slot tab-2-content-step-1
### Start the Control Plane
After [downloading and installing Kuma](/install/0.1.0), you can start the control plane. Kuma automatically creates a `default` [Mesh](/docs/0.1.0/policies/#mesh):
:::

::: slot tab-2-code-block-step-1
```sh
$ kuma-cp run &
```
:::

::: slot tab-2-content-step-2
### Start your Services and start the data-plane
For each Service that belongs to the Service Mesh, you must start a [`Dataplane Entity`](/docs/0.1.0/documentation/#dataplane-entity). After configuring the networking, you can start the data-plane process:
:::

::: slot tab-2-code-block-step-2
```sh
$ kuma-tcp-echo --port 9000 # This is a sample service

$ echo "type: Dataplane
mesh: default
name: dp-echo-1
networking:
  inbound:
  - interface: 127.0.0.1:10000:9000
    tags:
      service: echo" | kumactl apply -f -

$ KUMA_CONTROL_PLANE_BOOTSTRAP_SERVER_URL=http://127.0.0.1:5682 \
  KUMA_DATAPLANE_MESH=default \
  KUMA_DATAPLANE_NAME=dp-echo-1 \
  kuma-dp run
```
:::

::: slot tab-2-content-step-3
### Apply Policies
You can now apply [Policies](/docs/0.1.0/policies) like Mutual TLS to encrypt the communication within the Mesh. Congratulations! You have secured your Service Mesh!
:::

::: slot tab-2-code-block-step-3
```sh
$ echo "type: Mesh
name: default
mtls:
  enabled: true 
  ca:
    builtin: {}" | kumactl apply -f -
```
:::


<!-- steps -->

::: slot steps-title
## Build your Service Mesh in 3 steps
:::

::: slot step-1-content
### Download and Install Kuma CP
To get started you can download Kuma and install it using the Kuma CLI application: &#96;kumactl&#96;.
:::

::: slot step-1-code-block
```
$ kumactl install control-plane | kubectl apply -f
```
:::

::: slot step-2-content
### Install the sidecar Envoy DP
Once Kuma is up and running, it's now time to install the Envoy sidecars - that Kuma will 
later orchestrate - next to any service we want to include into our Service Mesh.
:::

::: slot step-2-code-block
```
$ kumactl install data-plane | kubectl apply -f
```
:::

::: slot step-3-content
### Apply Policies
Congratulations, your Service Mesh is up and running. We can now instruct Kuma to enhance our 
Service Mesh with powerful policies like mTLS.
:::

::: slot step-3-code-block
```
$ kumactl create policy \
  --name mtls \
  --conf topology=hybrid
```
:::

<!-- before and after -->

::: slot before-after-title
## Run Services, Not Networks
:::

::: slot before-after-diagram-1
![Before implementing Kuma](/images/diagrams/diagram-before@2x.jpg)
:::

::: slot before-after-diagram-2
![After implementing Kuma](/images/diagrams/diagram-after@2x.jpg)
:::

<!-- newsletter -->

::: slot newsletter-title
## Get Community Updates
:::

::: slot newsletter-content
Sign up for our Kuma community newsletter to get the most recent updates and product announcements.
:::