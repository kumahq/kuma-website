# What is Kuma?

<center>
<img src="/images/docs/main-diagram.png" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Kuma is a universal open-source control plane for Service Mesh and Microservices. It can run and be operated natively across both Kubernetes and VM environments, making it easy to adopt by every team in the organization.

Built on top of [Envoy](https://envoyproxy.io/), Kuma can instrument any L4/L7 traffic to secure, observe, route and enhance connectivity between any service or database. It can be used natively in Kubernetes via CRDs or via a RESTful API across other environments, and it doesn't require a change to your application's code in order to be used.

While being simple to use for most use-cases, Kuma also provides policies to configure the underlying Envoy data-planes in a more fine-grained manner. The result caters to both first-time users of Service Mesh, as well as the most experienced ones.

<center>
<img src="/images/docs/0.1.1/diagram-01.jpg" alt="" style="width: 500px; padding-top: 20px; padding-bottom: 10px;"/>
</center>

Kong built Kuma with feedback from 150+ enterprise organizations running Service Mesh in production. Kuma implements a pragmatic approach that is very different from the first-generation control planes:  
- it runs with low operational overhead across all the organization
- it supports every platform 
- it's easy to use while relying on a solid networking foundation delivered by Envoy.

Built by Envoy contributors at Kong 🦍.

::: tip
**Need help?** Don't forget to check the [Community](/community) section! 
:::