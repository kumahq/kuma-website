# Dependencies

Kuma (`kuma-cp`) is one single executable written in GoLang that can be installed anywhere, hence why it's both universal and simple to deploy. 

* Running on **Kubernetes**: No external dependencies required, since it leverages the underlying K8s API server to store its configuration. A `kuma-injector` service will also start in order to automatically inject sidecar data-plane proxies without human intervention.

* Running on **Universal**: Kuma requires a PostgreSQL database as a dependency in order to store its configuration. PostgreSQL is a very popular and easy database. You can run Kuma with any managed PostgreSQL offering as well, like AWS RDS or Aurora. Out of sight, out of mind!

Out of the box, Kuma ships with a bundled [Envoy](https://www.envoyproxy.io/) data-plane ready to use for our services, so that you don't have to worry about putting all the pieces together.

::: tip
Kuma ships with an executable `kuma-dp` that will execute the bundled `envoy` executable in order to execute the data-plane proxy. The behavior of the data-plane executable is being explained in the [Overview](../overview).
:::

[Install Kuma](/install/0.3.1) and follow the instructions to get up and running in a few steps.