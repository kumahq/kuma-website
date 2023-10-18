---
title: Init Containers
---

Due to the way that {{site.mesh_product_name}} implements transparent proxying, running Kubernetes init containers with network calls can be a challenge.

### Network calls to outside of the mesh

The common pitfall is the idea that it's possible to order init containers so that the mesh init container is run after other init containers.
However, when injecting these init containers into a Pod via webhooks, such as the Vault init container, there is no assurance of the order.
The ordering of init containers also doesn't provide a solution when the CNI is used, as traffic redirection to the sidecar occurs even before any init container runs

To solve this issue, start the init container with a specific user ID and exclude specific ports from interception.
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

### Network calls inside the mesh with mTLS enabled

In this scenario, using the init container is simply impossible because `kuma-dp` is the one responsible for encrypting the traffic and runs after all init containers.
A potential solution for this may arise in the future once the [Kubernetes Sidecar KEP](https://github.com/kubernetes/enhancements/issues/753) is implemented.
