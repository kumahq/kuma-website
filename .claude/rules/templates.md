# Doc templates

Scaffolds live in `templates/` and are invoked via gomplate by `mise run new:policy PolicyName` and `mise run new:resource ResourceName`. See `templates/policy.md` and `templates/resource.md` for canonical structure rather than duplicating it here.

## Policy reference required sections

- Frontmatter: `title`, `description`, `keywords` (**exactly 3** — Algolia perf constraint), `content_type: reference`, `category: policy`
- Intro paragraph
- `## Configuration` — field-by-field with **Type** / **Required** / **Default**
- `## Examples` — wrapped in `{% policy_yaml %}` (use `namespace=` and `use_meshservice=true` where relevant)
- `## See also` — use `/docs/{{ page.release }}/...` links
- `## All policy options` — `{% schema_viewer PolicyName %}`

## Nav entry (`app/_data/docs_nav_kuma_<latest>.yml`)

```yaml
- title: PolicyName
  url: /policies/policyname/
```
