---
title: Use Kuma
---

After {{site.mesh_product_name}} is installed, you can access the control plane via the following methods:

| Access method | Mode | Permissions | 
| ---- | ---- | ----- |
| {{site.mesh_product_name}} user interface | Kubernetes and Universal | Read-only |
| HTTP API | Kubernetes and Universal | Read-only |
| `kumactl` | Kubernetes | Read-only |
| `kumactl` | Universal | Read and write |
| `kubectl` | Kubernetes | Read and write |

By accessing the control plane using one of these methods, you can see the current {{site.mesh_product_name}} configuration or with some methods, you can edit the configuration. 


## Use {{site.mesh_product_name}} with Kubernetes

{% tabs use-kuma-kubernetes useUrlFragment=false %}
{% tab use-kuma-kubernetes GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} we need to first port-forward the API service with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% tab use-kuma-kubernetes kubectl (Read & Write) %}

You can use {{site.mesh_product_name}} with `kubectl` to perform **read and write** operations on {{site.mesh_product_name}} resources. For example:

```sh
kubectl get meshes
# NAME          AGE
# default       1m
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% tab use-kuma-kubernetes HTTP API (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** HTTP API that you can use to retrieve {{site.mesh_product_name}} resources.

By default the HTTP API listens on port `5681`. To access {{site.mesh_product_name}} we need to first port-forward the API service with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

And then you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% tab use-kuma-kubernetes kumactl (Read-Only) %}

You can use the `kumactl` CLI to perform **read-only** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API, you will need to first port-forward the API service with:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

and then run `kumactl`, for example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% endtabs %}

## Use {{site.mesh_product_name}} with Universal

{% tabs use-kuma-universal useUrlFragment=false %}
{% tab use-kuma-universal GUI (Read-Only) %}

{{site.mesh_product_name}} ships with a **read-only** GUI that you can use to retrieve {{site.mesh_product_name}} resources. By default the GUI listens on the API port and defaults to `:5681/gui`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681/gui`](http://127.0.0.1:5681/gui) to see the GUI.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% tab use-kuma-universal HTTP API (Read & Write) %}

{{site.mesh_product_name}} ships with a **read and write** HTTP API that you can use to perform operations on {{site.mesh_product_name}} resources. By default the HTTP API listens on port `5681`.

To access {{site.mesh_product_name}} you can navigate to [`127.0.0.1:5681`](http://127.0.0.1:5681) to see the HTTP API.

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% tab use-kuma-universal kumactl (Read & Write) %}

You can use the `kumactl` CLI to perform **read and write** operations on {{site.mesh_product_name}} resources. The `kumactl` binary is a client to the {{site.mesh_product_name}} HTTP API. For example:

```sh
kumactl get meshes
# NAME          mTLS      METRICS      LOGGING   TRACING
# default       off       off          off       off
```

or you can enable mTLS on the `default` Mesh with:

```sh
echo "type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin" | kumactl apply -f -
```

You can configure `kumactl` to point to any zone `kuma-cp` instance by running:

```sh
kumactl config control-planes add --name=XYZ --address=http://{address-to-kuma}:5681
```

You will notice that {{site.mesh_product_name}} automatically creates a [`Mesh`](/docs/{{ page.version }}/production/mesh/) entity with name `default`.

{% endtab %}
{% endtabs %}