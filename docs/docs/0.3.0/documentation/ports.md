# Ports

When `kuma-cp` starts up, by default it listens on a few ports:

* `5677`: the SDS server being used for propagating mTLS certificates across the data-planes.
* `5678`: the xDS gRPC server implementation that the data-planes will use to retrieve their configuration.
* `5679`: the Dataplane Token Server that serves Dataplane Tokens
* `5680`: the HTTP server that returns the health status of the control-plane.
* `5681`: the HTTP API server that is being used by `kumactl`, and that you can also use to retrieve Kuma's policies and - when runnning in `universal` - that you can use to apply new policies.
* `5682`: the HTTP server that provides the Envoy bootstrap configuration when the data-plane starts up.
* `5683`: the HTTP server that exposes Kuma UI.