# Proxy Template

With the `ProxyTemplate` policy you can configure the low-level Envoy resources directly. The policy requires two elements in its configuration:

- `imports`: this field lets you import canned `ProxyTemplate`s provided by Kuma.
  - In the current release, the only available canned `ProxyTemplate` is `default-proxy`
  - In future releases, more of these will be available and it will also be possible for the user to define them to re-use across their infrastructure
- `resources`: the custom resources that will be applied to every [`Dataplane`]() that matches the `selectors`.

On Universal:

```yaml
type: ProxyTemplate
mesh: default
name: template-1
selectors:
  - match:
      service: backend
imports:
  - default-proxy
resources:
  - ..
  - ..
```

On Kubernetes:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ProxyTemplate
mesh: default
metadata:
  namespace: default
  name: template-1
spec:
  selectors:
    - match:
        service: backend
  imports:
    - default-proxy
  resources:
    - ..
    - ..
```

Below you can find an example of what a `ProxyTemplate` configuration could look like:

```yaml
  imports:
    - default-proxy
  resources:
    - name: localhost:9901
      version: v1
      resource: |
        '@type': type.googleapis.com/envoy.api.v2.Cluster
        connectTimeout: 5s
        name: localhost:9901
        loadAssignment:
          clusterName: localhost:9901
          endpoints:
          - lbEndpoints:
            - endpoint:
                address:
                  socketAddress:
                    address: 127.0.0.1
                    portValue: 9901
        type: STATIC
    - name: inbound:0.0.0.0:4040
      version: v1
      resource: |
        '@type': type.googleapis.com/envoy.api.v2.Listener
        name: inbound:0.0.0.0:4040
        address:
          socket_address:
            address: 0.0.0.0
            port_value: 4040
        filter_chains:
        - filters:
          - name: envoy.http_connection_manager
            config:
              route_config:
                virtual_hosts:
                - routes:
                  - match:
                      prefix: /stats/prometheus
                    route:
                      cluster: localhost:9901
                  domains:
                  - '*'
                  name: envoy_admin
              codec_type: AUTO
              http_filters:
                name: envoy.router
              stat_prefix: stats
```