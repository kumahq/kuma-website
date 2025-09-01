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

* `deny` list – list of matches for clients that must always be denied.
* `allow` list – list of matchers for clients that are explicitly allowed.
* `allowWithShadowDeny` list – list of matchers that are allowed, but also logged as if they were denied.
Useful for testing a policy to ensure no legitimate clients are denied.

Evaluation rules are:

1. If a request matches at least one `deny` matcher – `DENY`.
2. Else, if it matches at least one `allow` or `allowWithShadowDeny` matcher – `ALLOW`.
3. If no matchers apply – `DENY` (default).

## Examples

## All policy options

{% json_schema MeshTrafficPermissions %}
