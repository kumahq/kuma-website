---
title: Manage and restrict control plane permissions on Kubernetes
content_type: tutorial
---

{% capture docs %}/docs/{{ page.release }}{% endcapture %}
{% assign Kuma = site.mesh_product_name %}
{% assign kuma = site.mesh_install_archive_name | default: "kuma" %}

By default, {{ Kuma }} deployed on Kubernetes reacts to events and observes all resources at the cluster scope. This approach benefits first-time users who want to explore its functionality and simplifies migration into the mesh. However, in production environments, restricting access to specific resources can enhance security and ensure that {{ Kuma }} does not impact running applications.

Starting from version 2.11, {{ Kuma }} includes new features that let you limit the permissions it needs in Kubernetes.

## Restrict permissions to selected namespaces

One of the new features allows you to define a list of namespaces that {{ Kuma }}'s control plane can access. When this list is set, {{ Kuma }} will only have permissions in those selected namespaces and in its own system namespace. It won't be able to access or manage resources in any other namespace.

### Set allowed namespaces during installation

To restrict {{ Kuma }} to a specific set of namespaces, set the following option during installation:

{% cpinstall envars %}
namespaceAllowList={kuma-demo}
{% endcpinstall %}

Replace `kuma-demo` with a comma-separated list of namespaces you want {{ Kuma }} to manage.

This will create a `RoleBinding` in each listed namespace, binding the `{{ kuma }}-control-plane-write` `ClusterRole` to that namespace. It will also configure {{ Kuma }}'s mutating and validating webhooks to only work within the specified namespaces.

<!-- vale Google.Headings = NO -->
## Manually manage RBAC resources
<!-- vale Google.Headings = YES -->

If you want full control over the RBAC resources used by {{ Kuma }}, follow these steps to set them up manually before installation.

1. **Create required ClusterRoles**

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: {{ kuma }}-control-plane
   rules:
   - apiGroups:
     - ""
     resources:
     - namespaces
     - pods
     - nodes
     - services
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - discovery.k8s.io
     resources:
     - endpointslices
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - apps
     resources:
     - deployments
     - replicasets
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - batch
     resources:
     - jobs
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - gateway.networking.k8s.io
     resources:
     - gateways
     - referencegrants
     - httproutes
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - gateway.networking.k8s.io
     resources:
     - gatewayclasses
     verbs:
     - create
     - delete
     - get
     - list
     - patch
     - update
     - watch
   - apiGroups:
     - gateway.networking.k8s.io
     resources:
     - gatewayclasses/status
     verbs:
     - get
     - patch
     - update
   - apiGroups:
     - kuma.io
     resources:
     - dataplanes
     - dataplaneinsights
     - meshes
     - zones
     - zoneinsights
     - zoneingresses
     - zoneingressinsights
     - zoneegresses
     - zoneegressinsights
     - meshinsights
     - serviceinsights
     - proxytemplates
     - ratelimits
     - trafficpermissions
     - trafficroutes
     - timeouts
     - retries
     - circuitbreakers
     - virtualoutbounds
     - containerpatches
     - externalservices
     - faultinjections
     - healthchecks
     - trafficlogs
     - traffictraces
     - meshgateways
     - meshgatewayroutes
     - meshgatewayinstances
     - meshgatewayconfigs
     - meshaccesslogs
     - meshcircuitbreakers
     - meshfaultinjections
     - meshhealthchecks
     - meshhttproutes
     - meshloadbalancingstrategies
     - meshmetrics
     - meshpassthroughs
     - meshproxypatches
     - meshratelimits
     - meshretries
     - meshtcproutes
     - meshtimeouts
     - meshtlses
     - meshtraces
     - meshtrafficpermissions
     - hostnamegenerators
     - meshexternalservices
     - meshmultizoneservices
     - meshservices
     verbs:
     - get
     - list
     - watch
     - create
     - update
     - patch
     - delete
   - apiGroups:
     - kuma.io
     resources:
     - meshgatewayinstances/status
     - meshgatewayinstances/finalizers
     - meshes/finalizers
     - dataplanes/finalizers
     verbs:
     - get
     - patch
     - update
   - apiGroups:
     - authentication.k8s.io
     resources:
     - tokenreviews
     verbs:
     - create
   ```
   
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: {{ kuma }}-control-plane-writer
   rules:
   - apiGroups:
     - ""
     resources:
     - events
     verbs:
     - create
     - patch
   - apiGroups:
     - apps
     resources:
     - deployments
     - replicasets
     verbs:
     - create
     - delete
     - get
     - list
     - patch
     - update
     - watch
   - apiGroups:
     - batch
     resources:
     - jobs
     verbs:
     - get
     - list
     - watch
   - apiGroups:
     - ""
     resources:
     - services
     verbs:
     - get
     - delete
     - list
     - watch
     - create
     - update
     - patch
   - apiGroups:
     - ""
     resources:
     - pods/finalizers
     verbs:
     - get
     - patch
     - update
   - apiGroups:
     - gateway.networking.k8s.io
     resources:
     - gateways
     - referencegrants
     - httproutes
     verbs:
     - create
     - delete
     - get
     - list
     - patch
     - update
     - watch
   - apiGroups:
     - gateway.networking.k8s.io
     resources:
     - gateways/status
     - httproutes/status
     verbs:
     - get
     - patch
     - update
   ```

2. **Create ClusterRoleBinding**

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: {{ kuma }}-control-plane
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: {{ kuma }}-control-plane
   subjects:
   - kind: ServiceAccount
     name: {{ kuma }}-control-plane
     namespace: {{ kuma }}-system
   ```

3. **Create RoleBinding in the system namespace**

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: {{ kuma }}-control-plane
     namespace: {{ kuma }}-system
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: Role
     name: {{ kuma }}-control-plane
   subjects:
   - kind: ServiceAccount
     name: {{ kuma }}-control-plane
     namespace: {{ kuma }}-system
   ```

4. **(Optional) Create RoleBindings for selected namespaces**

   If you’re also restricting {{ Kuma }} to specific namespaces (using `namespaceAllowList`), you must create a `RoleBinding` in each of those namespaces. For example, for the `kuma-demo` namespace:
   
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: {{ kuma }}-control-plane-writer
     namespace: kuma-demo
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: {{ kuma }}-control-plane-writer
   subjects:
   - kind: ServiceAccount
     name: {{ kuma }}-control-plane
     namespace: {{ kuma }}-system
   ```

5. **Install {{ Kuma }} with RBAC creation disabled**

   To prevent {{ Kuma }} from creating any RBAC resources automatically, set:

{% capture skipRBAC %}
{% cpinstall skipRBAC %}
skipRBAC=true
{% endcpinstall %}
{% endcapture %}

   {{ skipRBAC | indent }}
   
   If your environment only restricts cluster-scoped RBAC resources and you want to skip just those, use:

{% capture skipClusterRoleCreation %}
{% cpinstall skipClusterRoleCreation %}
controlPlane.skipClusterRoleCreation=true
{% endcpinstall %}
{% endcapture %}

   {{ skipClusterRoleCreation | indent }}
