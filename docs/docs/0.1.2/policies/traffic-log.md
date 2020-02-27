# Traffic Logging

With the `TrafficLogging` policy you can configure access logging on every Envoy data-plane belonging to the [`Mesh`](../mesh). These logs can then be collected by any agent to be inserted into systems like Splunk, ELK and Datadog.

On Universal:

```yaml
type: Mesh
name: default
logging:
  accessLogs:
    enabled: true
    filePath: "/tmp/access.log"
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  namespace: kuma-system
  name: default
spec:
  logging:
    accessLogs:
      enabled: true
      filePath: "/tmp/access.log"
```