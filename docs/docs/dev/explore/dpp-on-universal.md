# Data plane on Universal

As mentioned previously in universal you need to create a dataplane definition and pass it to the `kuma-dp run` command.

When transparent proxying is not enabled, the outbound service dependencies have to be manually specified in the [`Dataplane`](#dataplane-entity) entity.
This also means that with transparent proxying **you must update** your codebases to consume those external services on `127.0.0.1` on the port specified in the `outbound` section.

For example, this is how we start a `Dataplane` for a hypothetical Redis service and then start the `kuma-dp` process:

```sh
cat dp.yaml
type: Dataplane
mesh: default
name: redis-1
networking:
  address: 192.168.0.1
  inbound:
  - port: 9000
    servicePort: 6379
    tags:
      kuma.io/service: redis

kuma-dp run \
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-file=dp.yaml
  --dataplane-token-file=/tmp/kuma-dp-redis-1-token
```

In the example above, any external client who wants to consume Redis will have to make a request to the DP on address `192.168.0.1` and port `9000`, which internally will be redirected to the Redis service listening on address `127.0.0.1` and port `6379`.

::: tip
Note that in Universal dataplanes need to start with a token for authentication. You can learn how to generate tokens in the [security section](../security/dp-auth.md#data-plane-proxy-token).
:::

Now let's assume that we have another service called "Backend" that internally listens on port `80`, and that makes outgoing requests to the `redis` service:

```sh
cat dp.yaml
type: Dataplane
mesh: default
name: {{ name }}
networking:
  address: {{ address }}
  inbound:
  - port: 8000
    servicePort: 80
    tags:
      kuma.io/service: backend
      kuma.io/protocol: http
  outbound:
  - port: 10000
    tags:
      kuma.io/service: redis

kuma-dp run \
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-file=dp.yaml \
  --dataplane-var name=`hostname -s` \
  --dataplane-var address=192.168.0.2 \
  --dataplane-token-file=/tmp/kuma-dp-backend-1-token
```

In order for the `backend` service to successfully consume `redis`, we specify an `outbound` networking section in the `Dataplane` configuration instructing the DP to listen on a new port `10000` and to proxy any outgoing request on port `10000` to the `redis` service.
For this to work, we must update our application to consume `redis` on `127.0.0.1:10000`.


::: tip
You can parametrize your `Dataplane` definition, so you can reuse the same file for many `kuma-dp` instances or even services.
:::

## Envoy concurrency setting

Envoy on Linux, by default, starts with the flag `--cpuset-threads`. In this case, cpuset size is used to determine the number of worker threads on systems. When the value is not present then the number of worker threads is based on the number of hardware threads on the machine. `Kuma-dp` allows tuning that value by providing a `--concurrency` flag with the number of worker threads to create.

```sh
kuma-dp run \
  [..]
  --concurrency=5
```
