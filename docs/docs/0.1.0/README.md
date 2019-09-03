# Welcome to Kuma

Kuma is a universal open-source control plane for Service Mesh and Microservices that can run natively across both Kubernetes and VM environments, in order to be easily adopted by every team in the organization. 

Built on top of Envoy, Kuma can instrument any L4/L7 traffic to secure, observe, route and enhance connectivity between any service or database. It can be used natively in Kubernetes via CRDs or via a RESTful API across other environments, and it doesn't require to change our application's code in order to be used.

While being simple to use for most use-cases, Kuma also provides policies to configure the underlying Envoy data-planes in a more fine grained way, therefore catering to both first time user of Service Mesh, as well as most experienced ones.

TODO: IMAGE DIAGRAM

Built by Kong with feedback from 150+ enterprise organizations running Service Mesh in production, Kuma implements a pragmatic approach that is very different from the 1st generation control planes: it runs with low operational overhead across all the organization, it supports every platform, and it's easy to use while relying on a solid networking foundation delivered by Envoy.

Built by Envoy contributors at Kong 🦍.

# Where to go from here?

You are a few minutes away from being able to run Kuma and build your first Service Mesh! This documentation can help you into understanding the basic concepts and getting up and running quickly.

You can explore the following areas as a next step:

* Dependencies, Concepts and Architecture
* Quickstart: Getting up and running

# Dependencies

Kuma is one single executable that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on Kubernetes: No dependencies required, since it leverages the underlying K8s API server to store its configuration.

* Running on Linux: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any Postgres-As-A-Service offering as well, like AWS RDS or Aurora.

Out of the box, Kuma ships with a bundled Envoy data-plane ready to use for our services, so that you don't have to worry about putting pieces together.

# Service Mesh for everybody

Until now service mesh has been considered to be the last step of architecture modernization after transitioning to containers and perhaps to Kubernetes. This approach is completely backwards, since it makes the adoption and the business value of service mesh available only after implementing other massive transformations that - in the meanwhile - can go wrong.

In reality, we want service mesh to be available *before* we implement other transitions so that we can keep the network both secure and observable in the process. With Kuma, service mesh is indeed the **first step** towards modernization.

Unlike other control planes, Kuma natively runs across any platform and it's not limited in scope (ie, Kubernetes only). Kuma works on both existing brownfield applications (those apps that deliver business value today), as well as new modern greenfield applications that will be the future of our journey.

Unlike other control planes, Kuma is easy to use. Anybody - from any team - can implement Kuma in three simple steps across both traditional monolithic applications and modern microservices.

Finally, by leveraging out of the box policies and Kuma's powerful tagging selectors, we can implement all sort of behaviors when it comes to both simple and complex topologies, like multi-cloud and multi-region architectures.










## Code block example

``` bash
$ curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=example-service'
  --data 'url=http://example.com'
$ curl -i -X POST \
  --url http://localhost:8001/services/example-service/routes/
  --data 'hosts=[]=example.com' \
```

## Include example 
Included markdown partials are relative to the `/docs/.partials/` directory.

!!!include(api-reference.md)!!!

!!!include(architectural-diagrams.md)!!!