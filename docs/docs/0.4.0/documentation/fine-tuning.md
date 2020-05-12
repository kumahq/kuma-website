# Fine-tuning

## Postgres

If you choose `Postgres` as a configuration store for `Kuma` on Universal,
please be aware of the following key settings that affect performance of Kuma Control Plane.

* `connectionTimeout`  : connection timeout to the Postgres database (default: 5s)
* `maxOpenConnections` : maximum number of open connections to the Postgres database (default: unlimited)

### connectionTimeout

The default `connectionTimeout` will work well in those cases where both `kuma-cp` and Postgres database are deployed in the same datacenter / cloud region.

However, if you're pursuing a more distributed topology, e.g. by hosting `kuma-cp` on premise and using Postgres as a service in the cloud, the default `connectionTimeout` might no longer be enough.

### maxOpenConnections

The more dataplanes join your meshes, the more connections to Postgres database Kuma might need to fetch configurations and update statuses.

The default `maxOpenConnections` (unlimited) allows Kuma to make better use of all available resources.

However, if your Postgres database (e.g., as a service in the cloud) only permits a small number of concurrent connections, you will have to adjust Kuma configuration respectively.
