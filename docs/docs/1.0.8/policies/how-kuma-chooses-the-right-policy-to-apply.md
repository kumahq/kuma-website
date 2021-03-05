# How Kuma chooses the right policy to apply

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