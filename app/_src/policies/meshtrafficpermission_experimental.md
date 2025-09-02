---
title: MeshTrafficPermission
---

{% tip %}
[Mutual TLS](/docs/{{ page.release }}/policies/mutual-tls) has to be enabled to make MeshTrafficPermission work.
{% endtip %}

## Overview

`MeshTrafficPermission` policy defines which clients are allowed or denied access to services inside a mesh based on their identities.
By default, if no policy is present, all requests are denied.

It enables:

* denying all requests by default, or blocking specific clients (by SPIFFE ID)
  so that no service owner can override them
* allowing groups of clients, such as everything in the `observability` namespace,
  to access all services by default, while still letting individual services opt out
* giving service owners control to allow specific clients, and the ability to block abusive ones
  even if they were previously allowed

Here is a common example:

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
name: my-app-permissions
mesh: my-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: my-app
  rules:
    - default:
        deny:
          - spiffeId:
              type: Prefix
              value: "spiffe://other-mesh.us-east-2.mesh.local/ns/legacy-ns"
          - spiffeId:
              type: Exact
              value: "spiffe://other-mesh.us-east-2.mesh.local/ns/test/sa/client"
        allow:
          - spiffeId:
              type: Prefix
              value: "spiffe://other-mesh.us-east-2.mesh.local"
```
{% endpolicy_yaml %}

With this policy in place, workloads labeled `app: my-app` will reject connections from identities under the `legacy-ns` namespace
as well as the specific `test/client` identity, while continuing to accept connections from all other identities within the `other-mesh.us-east-2.mesh.local` trust domain.

## Configuration

`MeshTrafficPermission` policy provides a way to specify 3 lists:

* `deny` list -- list of matches for clients that must always be denied.
* `allow` list -- list of matchers for clients that are explicitly allowed.
* `allowWithShadowDeny` list -- list of matchers that are allowed, but also logged as if they were denied.
Useful for testing a policy to ensure no legitimate clients are denied.

Evaluation rules are:

1. If a request matches at least one `deny` matcher -- `DENY`.
2. Else, if it matches at least one `allow` or `allorWithShadowDeny` matcher -- `ALLOW`.
3. If no matchers apply -- `DENY` (default).

## Examples

### Denying requests from a group of clients mesh-wide

During the incident, if one of the namespaces is compromised, Mesh Operator can apply the following policy:

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
name: deny-malicious-ns
mesh: my-mesh
spec:
  rules:
    - default:
        deny:
          - spiffeId:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/malicious"
```
{% endpolicy_yaml %}

Such policy when applied globally prevents any service in the mesh `my-mesh` to receive requests from any client in `malicious` namespace.
There is no way for Service Owner to opt-out from this rule.

### Allowing requests from a group of clients mesh-wide

By default, when there are no `MeshTrafficPermission` policies, all requests are denied.
Mesh Operator can apply the following policy mesh-wide:

{% policy_yaml %}
```yaml
type: MeshTrafficPermission
name: allow-observability-ns
mesh: my-mesh
spec:
  rules:
    - default:
        allow:
          - spiffeId:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/observability"
```
{% endpolicy_yaml %}

This policy allows any client in `observability` namespace to consume any service in `my-mesh`.
Service Owner can opt-out and deny requests from `observability` if they need to:

{% policy_yaml namespace=backend-ns %}
```yaml
type: MeshTrafficPermission
name: deny-observability-ns
mesh: my-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
    sectionName: backend-admin-api
  rules:
    - default:
        deny:
          - spiffeId:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/observability"
```
{% endpolicy_yaml %}

The following policy overrides the rules specified in `allow-observability-ns` 
and denies requests from clients in `observability` namespace on `backend-admin-api` port of `backend` app.

## All policy options

{% json_schema MeshTrafficPermissions %}
