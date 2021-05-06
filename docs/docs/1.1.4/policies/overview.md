# How policies work

TODO: write meaningful introduction

## Applying policies

Once installed, Kuma can be configured via its policies. You can apply policies with [`kumactl`](../../documentation/kumactl) on Universal, and with `kubectl` on Kubernetes. Regardless of what environment you use, you can always read the latest Kuma state with [`kumactl`](../../documentation/kumactl) on both environments.

::: tip
We follow the best practices. You should always change your Kubernetes state with CRDs, that's why Kuma disables `kumactl apply [..]` when running in K8s environments.
:::

These policies can be applied either by file via the `kumactl apply -f [path]` or `kubectl apply -f [path]` syntax, or by using the following command:

```sh
echo "
  type: ..
  spec: ..
" | kumactl apply -f -
```

or - on Kubernetes - by using the equivalent:

```sh
echo "
  apiVersion: kuma.io/v1alpha1
  kind: ..
  spec: ..
" | kubectl apply -f -
```

In addition to [`kumactl`](../../documentation/kumactl), you can also retrieve the state via the Kuma [HTTP API](../../documentation/http-api) as well.

## Common properties

You may have already noticed that most `Kuma` policies have very similar structure, namely

```yaml
sources:
- match:
    kuma.io/service: ... # unique name OR '*'
    ... # (optionally) other tags

destinations:
- match:
    kuma.io/service: ... # unique name OR '*'
    ... # (optionally) other tags

conf:
  ... # policy-specific configuration
```

where

* `sources` - a list of selectors to match those `Dataplanes` where network traffic originates
* `destinations` - a list of selectors to match those `Dataplanes` where network traffic destined at
* `conf` - configuration to apply to network traffic between `sources` and `destinations`

To keep configuration model simple and consistent, `Kuma` assumes that every `Dataplane` represents a `service`, even if it's a cron job that doesn't normally handle incoming traffic.

Consequently, `service` tag is mandatory for `sources` and `destinations` selectors.

If you need your policy to apply to every connection between `Dataplane`s, or simply don't know yet what is the right scope for that policy, you can always use `'*'` (wildcard) instead if the exact value.

E.g., the following policy will apply to network traffic between all `Dataplane`s

```yaml
sources:
- match:
    kuma.io/service: '*'

destinations:
- match:
    kuma.io/service: '*'

conf:
  ...
```

In contrast, the next policy will apply only to network traffic between  `Dataplane`s that represent `web` and `backend` services:

```yaml
sources:
- match:
    kuma.io/service: web

destinations:
- match:
    kuma.io/service: backend

conf:
  ...
```

Finally, you can further limit the scope of a policy by including additional tags into `sources` and `destinations` selectors:

```yaml
sources:
- match:
    kuma.io/service: web
    cloud:   aws
    region:  us

destinations:
- match:
    kuma.io/service: backend
    version: v2      # notice that not all policies support arbitrary tags in `destinations` selectors

conf:
  ...
```

::: warning
While all policies support arbitrary tags in `sources` selectors, it's not generally the case for `destinations` selectors.

E.g., policies that get appied on the client side of a connection between 2 `Dataplane`s - such as `TrafficRoute`, `TrafficLog`, `HealthCheck` - only support `service` tag in `destinations` selectors.

In some cases there is a fundamental technical cause for that (e.g., `TrafficRoute`), in other cases it's a simplification of the initial implementation (e.g., `TrafficLog` and `HealthCheck`).

Please let us know if such constraints become critical to your use case.
:::

## How Kuma chooses the right policy to apply

TODO: consider trimming this page drastically and including in the introduction/overview.

At any single moment, there might be multiple policies (of the same type) that match a connection between `sources` and `destinations` `Dataplane`s.

E.g., there might be a catch-all policy that sets the baseline for your organization

```yaml
type: TrafficLog
mesh: default
name: catch-all-policy
sources:
  - match:
      kuma.io/service: '*'
destinations:
  - match:
      kuma.io/service: '*'
conf:
  backend: logstash
```

Additionally, there might be a more focused use case-specific policy, e.g.

```yaml
type: TrafficLog
mesh: default
name: web-to-backend-policy
sources:
  - match:
      kuma.io/service: web
      cloud:   aws
      region:  us
destinations:
  - match:
      kuma.io/service: backend
conf:
  backend: splunk
```

What does `Kuma` do when it encounters multiple matching policies ?

The answer depends on policy type:

* since `TrafficPermission` represents a grant of access given to a particular client `service`, `Kuma` conceptually "aggregates" all such grants by applying ALL `TrafficPermission` policies that match a connection between `sources` and `destinations` `Dataplane`s
* for other policy types - `TrafficRoute`, `TrafficLog`, `HealthCheck` - conceptual "aggregation" would be too complex for users to always keep in mind; that is why `Kuma` chooses and applies only "the most specific" matching policy in that case

Going back to 2 `TrafficLog` policies described above:
* for connections between `web` and `backend` `Dataplanes` `Kuma` will choose and apply `web-to-backend-policy` policy as "the most specific" in that case
* for connections between all other dataplanes `Kuma` will choose and apply `catch-all-policy` policy as "the most specific" in that case

"The most specific" policy is defined according to the following rules:

1. a policy that matches a connection between 2 `Dataplane`s by a greater number of tags is "more specific"

   E.g., `web-to-backend-policy` policy matches a connection between 2 `Dataplane`s by 4 tags (3 tags on `sources` and 1 tag on `destinations`), while `catch-all-policy` matches only by 2 tags (1 tag on `sources` and 1 tag on `destinations`)
2. a policy that matches by the exact tag value is more specific than policy that matches by a `'*'` (wildcard) tag value

   E.g., `web-to-backend-policy` policy matches `sources` by `kuma.io/service: web`, while `catch-all-policy` matches by `kuma.io/service: *`

3. if 2 policies match a connection between 2 `Dataplane`s by the same number of tags, then the one with a greater total number of matches by the exact tag value is "more specific" than the other

4. if 2 policies match a connection between 2 `Dataplane`s by the same number of tags, and the total number of matches by the exact tag value is the same for both policies, and the total number of matches by a `'*'` (wildcard) tag value is the same for both policies, then a "more specific" policy is the one whoose name comes first when ordered alphabetically

E.g.,

1. match by a greater number of tags

   ```yaml
   sources:
     - match:
         kuma.io/service: '*'
         cloud:   aws
         region:  us
   destinations:
     - match:
         kuma.io/service: '*'
   ```

   is "more specific" than

   ```yaml
   sources:
     - match:
         kuma.io/service: '*'
   destinations:
     - match:
         kuma.io/service: '*'
   ```

2. match by the exact tag value

   ```yaml
   sources:
     - match:
         kuma.io/service: web
   destinations:
     - match:
         kuma.io/service: backend
   ```

   is "more specific" than a match by a `'*'` (wildcard)

   ```yaml
   sources:
     - match:
         kuma.io/service: '*'
   destinations:
     - match:
         kuma.io/service: '*'
   ```

3. match with a greater total number of matches by the exact tag value

   ```yaml
   sources:
     - match:
         kuma.io/service: web
         version: v1
   destinations:
     - match:
         kuma.io/service: backend
   ```

   is "more specific" than

   ```yaml
   sources:
     - match:
         kuma.io/service: web
         version: '*'
   destinations:
     - match:
         kuma.io/service: backend
   ```

4. when 2 matches are otherwise "equally specific"

   ```yaml
   name: policy-1
   sources:
     - match:
         kuma.io/service: web
         version: v1
   destinations:
     - match:
         kuma.io/service: backend
   ```

   `policy-1` is considered "more specific" only due to the alphabetical order of names `"policy-1"` and `"policy-2"`

   ```yaml
   name: policy-2
   sources:
     - match:
         kuma.io/service: web
   destinations:
     - match:
         kuma.io/service: backend
         cloud:   aws
   ```