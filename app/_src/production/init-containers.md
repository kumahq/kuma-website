---
title: Init Containers
---

Due to the way how {{site.mesh_product_name}} implements transparent proxying, running Kubernetes init containers with network calls can be a challenge.

### The destination of the network call is outside the mesh

The common pitfall is the idea that we can order init containers so that the mesh init container is run after other init containers.
However, if those init containers are injected into Pod via webhooks (like Vault init container) there is no guarantee of the order.
Ordering of init containers is also not a solution when CNI is used, because traffic redirection to the sidecar is applied even before any init container is run.

The solution is to start the init container with a specific user id and exclude specific ports from being intercepted.
Remember also about excluding port of DNS interception. Here is an example of annotations to enable HTTPS traffic for a container running as user id `1234`.
```yaml
apiVersion: v1
king: Deployment
metadata:
  name: my-deployment
spec:
  template:
    metadata:
      labels:
        traffic.kuma.io/exclude-outbound-tcp-ports-for-uids: "443:1234"
        traffic.kuma.io/exclude-outbound-udp-ports-for-uids: "53:1234"
    spec:
      initContainers:
      - name: my-init-container
        ...
        securityContext:
          runAsUser: 1234
```

### The destination of the network call is in the mTLSed mesh

In this case, it's simply impossible to use the init container, because kuma-dp is responsible to encrypt the traffic, and it is run after all init containers.
This might be solved in the future when [Kubernetes Sidecar KEP](https://github.com/kubernetes/enhancements/issues/753) is implemented.
