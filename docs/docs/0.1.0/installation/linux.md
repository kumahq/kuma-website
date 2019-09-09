# Linux

To install and run Kuma on Linux execute the following steps:

## 1. Download and run Kuma

You can download Kuma from [here]() or by running:

```sh
$ wget downloads.kuma.io/0.1.0/kuma-linux.amd64.tar.gz
```

You can extract the archive and check the contents by running:

```sh
$ tar xvzf kuma-linux.amd64.tar.gz
$ ls
envoy		kuma-cp		kuma-dp		kuma-injector	kumactl
```

As you can see Kuma already ships with an [envoy](http://envoyproxy.io) executable ready to use.

To run Kuma execute:

```sh
$ kuma-cp run
```

By default this will run Kuma with a `memory` [backend](/docs/#backends), but you can change this to use PostgreSQL.

## 2. Create and connect data-planes

Kuma automatically creates a `Mesh` entity with name `default`. 

Now that the control-plane is running, you can now deploy your services and - for each replica of your service - you can register a `Dataplane` entity to the control-plane:

```bash
$ echo "type: Dataplane
mesh: default
name: example-1
networking:
  inbound:
  - interface: 127.0.0.1:11011:11012
    tags:
      service: example" | kumactl apply -f -
```

And run the actual data-plane process with:

```sh
$ KUMA_CONTROL_PLANE_BOOTSTRAP_SERVER_URL=http://127.0.0.1:5682 \
  KUMA_DATAPLANE_MESH=default \
  KUMA_DATAPLANE_NAME=example-1 \
  kuma-dp run
```



## 3. Apply Policies

Now you can start applying policies to your `default` Service Mesh, like Mutual TLS:

```sh
echo "type: Mesh
mesh: default
name: default
mtls:
  enabled: true 
  ca:
    builtin: {}" | kumactl apply -f -
```

## 4. Done!

You can now review the entities created by Kuma by using the `kumactl` CLI. For example you can list the Meshes:

```sh
$ kumactl get meshes
```

and you can list the data-planes that have been registered, and their status:

```sh
$ kumactl get dataplanes
$ kumactl inspect dataplanes
```





