# kumactl

The `kumactl` executable is a very important component in your journey with Kuma. It allows to:

* Retrieve the state of Kuma and the configured [policies](/docs/0.2.2/policies) in every environment.
* On **Universal** environments, it allows to change the state of Kuma by applying new policies with the `kumactl apply [..]` command.
* On **Kubernetes** it is **read-only**, because you are supposed to change the state of Kuma by leveraging Kuma's CRDs.
* It provides helpers to install Kuma on Kubernetes, and to configure the PostgreSQL schema on Universal (`kumactl install [..]`).

::: tip
The `kumactl` application is a CLI client for the underlying [HTTP API](#http-api) of Kuma. Therefore, you can access the state of Kuma by leveraging with the API directly. On Universal you will be able to also make changes via the HTTP API, while on Kubernetes the HTTP API is read-only.
:::

Available commands on `kumactl` are:

* `kumactl install [..]`: provides helpers to install Kuma in Kubernetes, or to configure the PostgreSQL database on Universal.
* `kumactl config [..]`: configures the local or remote control-planes that `kumactl` should talk to. You can have more than one enabled, and the configuration will be stored in `~/.kumactl/config`.
* `kumactl apply [..]`: used to change the state of Kuma. Only available on Universal.
* `kumactl get [..]`: used to retrieve the raw state of entities Kuma.
* `kumactl inspect [..]`: used to retrieve an augmented state of entities in Kuma.
* `kumactl help [..]`: help dialog that explains the commands available.
* `kumactl version [--detailed]`: shows the version of the program.