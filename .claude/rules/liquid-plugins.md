# Liquid plugin reference

Plugins live in `app/_plugins/` (in-tree, hot-reloaded) and `jekyll-kuma-plugins/lib/jekyll/` (extracted gem, re-run `mise run test:plugins` after changes).

## `{% if_version %}` — version gating

```liquid
{% if_version gte:2.10.x %}...{% endif_version %}
{% if_version eq:2.9.x %}...{% endif_version %}
{% if_version "gte:2.4.x lte:2.8.x" %}...{% endif_version %}
```

See `app/_plugins/blocks/if_version.rb`.

## `{% schema_viewer %}` — render policy schema from protobuf

```liquid
{% schema_viewer MeshAccessLogs exclude=from exclude.targetRef=tags,proxyTypes,mesh targetRef.kind=Mesh,Dataplane exclude.to.targetRef=tags,proxyTypes,mesh to.targetRef.kind=Mesh,MeshService %}
```

Common patterns:

- Outbound-only: `exclude=from`
- Inbound-only: `exclude=to`
- Restrict targetRef kinds: `targetRef.kind=Mesh,Dataplane`
- Path-based exclusion: `exclude.to.targetRef=tags,mesh,proxyTypes`

Full parameter list: `WRITING-DOCUMENTATION.md`.

## `{% inc %}` — auto-incrementing step counters

```liquid
## Step {% inc step_number %}: Do the thing
## Step {% inc step_number if_version=lte:2.4.x %}: Legacy step
{% inc step_number init_value=5 %}
{% inc step_number get_current %}
```

## `{% policy_yaml %}` — policy example block

Wraps YAML examples. Supports `namespace=<ns>` and `use_meshservice=true`. See `app/_plugins/blocks/policy_yaml.rb`.

## `{% mermaid %}` — Mermaid diagrams

```liquid
{% mermaid %}
flowchart TD
  A --> B
{% endmermaid %}
```

Not supported inside navtabs.

## `{% json_schema %}` — full JSON schema

Used in "All policy options" sections of policy reference pages.
