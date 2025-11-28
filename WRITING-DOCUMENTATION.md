<!-- vale off -->
# Writing documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work
as you write your documentation.

## Versions

The code uses trunk based development where `master` is the `trunk` branch.

A single sourced folder in [app/_src](app/_src) is used for each version of Kuma. We use a Jekyll plugin to dynamically generate pages from a single source file.

For the future non-patch versions of Kuma, changes can be made to the [docs_nav_kuma_dev.yml](app/_data/docs_nav_kuma_dev.yml) file.

## Writing docs for a new feature

If you are writing docs for a new feature you'll want to add it in the [src](app/_src) folder.

Since content is single sourced, you must use [conditional rendering](https://docs.konghq.com/contributing/conditional-rendering/) to ensure that the new feature content only displays for that version. For example:

```liquid
{% if_version eq:2.1.x %}
This will only show for version 2.1.x
{% endif_version %}
```

## Diagrams

The team is moving diagrams to [Google slides](https://docs.google.com/presentation/d/1qvIKeYfcuowrHW1hV9fk9mCptt3ywroPBUYFjMj9gkk/edit#slide=id.g13d0c1ffb72_0_67).
Instructions are in the first slide.
Ask a maintainer to get write access.

### Mermaid.js diagrams

You can use Mermaid.js diagrams in our documentation. It can be used with the following syntax:

```liquid
{% mermaid %}
{% endmermaid %}
```

For example, if you wanted to make a flowchart, you can use the following syntax:

```liquid
{% mermaid %}
flowchart TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
{% endmermaid %}
```

This flowchart would render like the following in the docs:

![Mermaid flowchart example](/assets/images/diagrams/mermaid-example.png)

You can use [https://mermaid.live/edit](https://mermaid.live/edit) to generate diagrams and see the rendered output before adding it to docs.

**Note:** Currently, Mermaid isn't supported in navtabs.

## Jekyll plugins

You can use some custom plugins to make writing documentation easier, especially for things Jekyll doesn't support by default:

### `schema_viewer` tag

The `schema_viewer` plugin renders interactive policy schema documentation from protobuf definitions. It automatically displays the complete structure of a policy with type information, allowed values, and filtering capabilities.

#### How to use

Basic usage:

```liquid
{% schema_viewer PolicyName %}
```

With filters:

```liquid
{% schema_viewer PolicyName exclude=from targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService %}
```

#### Available parameters

All parameters are optional and can be combined:

- **`PolicyName`** (required): Name of the policy resource (e.g., `MeshAccessLogs`, `MeshRetries`, `MeshHealthChecks`)
- **`exclude`**: Comma-separated list of sections to hide (e.g., `exclude=from` to hide the `from` section, `exclude=to` to hide the `to` section)
- **`targetRef.kind`**: Comma-separated list of allowed kinds for the top-level `targetRef` selector
- **`to.targetRef.kind`**: Comma-separated list of allowed kinds for the `to[].targetRef` selector
- **`from.targetRef.kind`**: Comma-separated list of allowed kinds for the `from[].targetRef` selector

#### Common patterns

**Outbound-only policies (exclude from):**

```liquid
{% schema_viewer MeshAccessLogs exclude=from targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshExternalService %}
```

**Inbound-only policies (exclude to):**

```liquid
{% schema_viewer MeshRateLimits exclude=to targetRef.kind=Mesh,Dataplane %}
```

**Policies with HTTP route support:**

```liquid
{% schema_viewer MeshRetries targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshExternalService,MeshMultiZoneService,MeshHTTPRoute %}
```

**Route policies:**

```liquid
{% schema_viewer MeshHttpRoutes targetRef.kind=Mesh,Dataplane to.targetRef.kind=MeshService,MeshMultiZoneService,MeshExternalService %}
```

**Load balancing policies:**

```liquid
{% schema_viewer MeshLoadBalancingStrategies targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshMultiZoneService,MeshHTTPRoute %}
```

#### Real-world examples

Outbound policy with multiple target types:

```liquid
{% schema_viewer MeshAccessLogs exclude=from targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshExternalService,MeshMultiZoneService,MeshHTTPRoute %}
```

Health check policy:

```liquid
{% schema_viewer MeshHealthChecks targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshMultiZoneService %}
```

Rate limiting (inbound only):

```liquid
{% schema_viewer MeshRateLimits exclude=from targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh %}
```

Circuit breaker (outbound only):

```liquid
{% schema_viewer MeshCircuitBreakers exclude=from targetRef.kind=Mesh,Dataplane to.targetRef.kind=Mesh,MeshService,MeshMultiZoneService %}
```

### `inc` tag

The `inc` plugin increments a variable (like `step_number`) each time it's called, letting you keep step numbers or counts consistent across your documentation. You can also set conditions to control when it increments based on the Kuma version or set an initial value.

The first parameter, such as `step_number`, is the variable name used to differentiate between counters. This parameter is required for each `inc` tag.

Parameter order doesn’t matter, and values can be wrapped with either `''` or `""`. If you need to specify multiple version requirements for the `if_version` parameter, you must use quotes around the version string, for example: `{% inc step_number if_version="gte:2.4.x lte:2.8.x" %}`.

#### How to use

- **Basic increment**: `{% inc step_number %}` increments `step_number` by 1.
- **Conditional increment**: `{% inc step_number if_version=lte:2.4.x %}` increments only if the Kuma version is `2.4.x` or lower.
- **Set initial value**: `{% inc step_number init_value=5 %}` starts `step_number` at 5.
- **Get current value**: `{% inc step_number get_current %}` returns the current value of `step_number` without incrementing.
- **Get current value with initial value**: `{% inc step_number get_current init_value=7 %}` returns the current value of `step_number` without incrementing, starting at 7 if it hasn’t been set before.

#### Available parameters

- **if_version**: Only increments if the Kuma version matches (works like `{% if_version ... %}`).
- **init_value**: Sets a starting value for the variable.
- **get_current**: If `true`, returns the current value without incrementing.

#### Real-life examples

```liquid
{% if_version lte:2.4.x %}
## Step {% inc step_number if_version=lte:2.4.x %}: Ensure the correct version of iptables.
{% endif_version %}
```

```liquid
To prepare your service environment and start the data plane proxy, follow the [Integrating Transparent Proxy into Your Service Environment](...) guide up to [Step {% inc install_tproxy if_version="lte:2.4.x" init_value=5 %}: Install the Transparent Proxy](...).
```

## Cutting a new release

To cut the dev release, create a duplicate of the [docs_nav_kuma_dev.yml](app/_data/docs_nav_kuma_dev.yml) file and then rename one of the files to "docs_nav_kuma_[version].yml". Update the `release: dev` metadata in the new release file with the release version.

Update the `app/_data/versions.yml` file with metadata specific to this release, for example: actual patches released, helm versions.

## Set up local builds with yarn

Before start, make sure that installed Ruby version is the same as in the `.ruby-version` file.

1. Install:

    ```bash
    mise run install
    ```

1. Build:

    ```bash
    mise run build
    ```

1. Serve:

    ```bash
    mise run serve
    ```

You will need to run `mise run build` after making any changes to the content. Automatic rebuilding will be added in November 2022.

## Set up local builds with Netlify

If you get errors on the Netlify server, it can help to [set up a local Netlify environment](https://docs.netlify.com/cli/get-started/).

It has happened, however, that `mise run build` and the local Netlify build succeed, and the build still fails upstream. At which point … sometimes the logs can help, but not always.

WARNING: when you run a local Netlify build it modifies your local `netlify.toml`. Make sure to revert/discard the changes before you push your local.

## Add generated docs from protobufs

If you create a new policy resource for Kuma, you should rebuild the generated policy reference documentation.

## Markdown features

For more information about the Markdown features and formatting that is supported, see the following:

- [Markdown rules and formatting](https://docs.konghq.com/contributing/markdown-rules/)
- [Reusable content](https://docs.konghq.com/contributing/includes/)

## Vale

Vale is the tool used for linting the Kuma docs.
The Github action only checks changed lines in your PR.

You can [install Vale](https://vale.sh/docs/vale-cli/installation/)
and run it locally from the repository root with:

```shell
vale sync # only necessary once in order to download the styles
vale <any files changed in your PR or ones you want to check>
```

### Spurious warnings

If Vale warns or errors incorrectly,
the usual fix is to add the word or phrase
to the vocab list in `.github/styles/Vocab`.
