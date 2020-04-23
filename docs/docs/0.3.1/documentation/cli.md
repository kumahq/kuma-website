# CLI

Kuma ships in a bundle that includes a few executables:

* `kuma-cp`: this is the main Kuma executable that runs the control plane (CP).
* `kuma-dp`: this is the Kuma data-plane executable that - under the hood - invokes `envoy`.
* `envoy`: this is the Envoy executable that we bundle for convenience into the archive.
* `kumactl`: this is the the user CLI to interact with Kuma (`kuma-cp`) and its data.
* `kuma-tcp-echo`: this is a sample application that echos back the requests we are making, used for demo purposes.

According to the [installation instructions](/install/0.3.1), some of these executables are automatically executed as part of the installation workflow, while some other times you will have to execute them directly.

You can check the usage of the executables by running the `-h` flag, like:

```sh
$ kuma-cp -h
```

and you can check their version by running the `version [--detailed]` command like:

```sh
$ kuma-cp version --detailed
```