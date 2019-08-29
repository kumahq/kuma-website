# Welcome to Kuma

Kuma is a modern and easy to use L4/L7 traffic management platform for Service Mesh and Microservices.

Built on top of Envoy, Kuma ships with a fast Data Plane (DP) and Control Plane (CP) that are meant to be used by the entire organization, and that can run on any platform to build modern cloud-native architectures: run on Kubernetes, VMs and any cloud vendor in a breeze.

Built by Envoy contributors at Kong 🦍.

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