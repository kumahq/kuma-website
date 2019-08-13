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
## Build your Service Mesh in 3 steps
:::

::: slot step-1-content
### Add your Service and Route
After [installing](/install/) and starting Kong, use the Admin API on port 8001 to add a new Service and Route. 
In this example, Kong will reverse proxy every incoming request with the specified incoming host to the associated 
upstream URL. You can implement very complex routing mechanisms beyond simple host matching.
:::

::: slot step-1-code-block
``` bash
$ curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=example-service' \
  --data 'url=http://example.com'
$ curl -i -X POST \
  --url http://localhost:8001/services/example-service/routes/ \
  --data 'hosts=[]=example.com' \
```
:::

::: slot step-2-content
### Add Plugins on the Service
Then add extra functionality by using Kong Plugins. You can also create your own plugins!
:::

::: slot step-2-code-block
``` bash
$ curl -i -X POST \
  --url http://localhost:8001/services/example-service/plugins/ \
  --data 'name=rate-limiting' \
  --data 'config.minute=100'
```
:::

::: slot step-3-content
### Make a Request
...and then you can consume the Service on port 8000 by requesting the specified host. In production setup the public 
host DNS to point to your Kong cluster. Kong supports much more functionality, explore the Hub and the documentation.
:::

::: slot step-3-code-block
``` bash
$ curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: example.com'
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