# kuma-website

Jekyll + Vite docs site for Kuma ([kuma.io](https://kuma.io)), deployed on Netlify.

## Tech stack

- Jekyll 4.4.1 (Ruby 4.0.2) — site generator, config in `jekyll.yml` / `jekyll-dev.yml`
- Vite 8 + vite-plugin-ruby + WindiCSS + SCSS/Stylus — assets from `app/_assets/`
- Custom Jekyll plugins: in-tree `app/_plugins/` (tags/filters/generators/hooks/blocks) + extracted gem `jekyll-kuma-plugins/`
- mise — task runner (`mise.toml`); yarn + bundle under the hood
- Lint: Vale 3.13, markdownlint-cli2, shellcheck, rubocop
- Test: RSpec (`spec/`, `jekyll-kuma-plugins/spec/`), shellspec (`tools/spec/`)

## Layout

- `app/_src/` — single-sourced docs content (**edit here**; `app/docs/2.x.x/` is generated)
- `app/_data/docs_nav_kuma_*.yml` — per-version sidebar nav; update when adding pages
- `app/_plugins/` — in-tree Jekyll plugins (hot-reloaded)
- `jekyll-kuma-plugins/` — extracted gem, RSpec-tested
- `templates/` — gomplate scaffolds for new policy/resource docs
- `tools/` — shell tooling (`check-version-urls.sh`, `validate-frontmatter.sh`)

## Critical editing rules

- **Edit `app/_src/`, never `app/docs/<version>/`** — the latter is generated.
- **Version-gate divergent content** with `{% if_version %}`.
- **Never hardcode version URLs** — use `/docs/{{ page.release }}/...`.
- **Register new pages in `app/_data/docs_nav_kuma_<latest>.yml`** or they stay invisible.

Full rules: [.claude/rules/editing.md](.claude/rules/editing.md). Anti-patterns: [.claude/rules/anti-patterns.md](.claude/rules/anti-patterns.md).

## Commands

- `mise run install` — yarn + bundle
- `mise run dev` — Jekyll + Vite + livereload at `localhost:4000` (`dev:clean` cleans first)
- `mise run serve` — Netlify CLI (closer to prod)
- `mise run build` / `mise run clean`
- `mise run new:policy PolicyName` / `mise run new:resource ResourceName` — scaffold docs
- `mise run mdlint:branch:fix` — auto-fix markdownlint on changed files

## Quality gates (pre-commit)

Run before you commit. Lint scope is **changed files vs `origin/master`**, not the whole repo.

```bash
mise run check           # vale:branch + vale:version-urls + frontmatter:validate + mdlint:branch + shellcheck
mise run test            # RSpec suite (app/_plugins + spec/)
mise run test:plugins    # jekyll-kuma-plugins gem specs
```

Additional when relevant: `mise run test:tools` (shellspec), `mise run build` (generation/plugin changes), `mise run links:check` (slow link check).

## Workflows

### New policy doc

1. `mise run new:policy MeshFoo`
2. Edit `app/_src/policies/meshfoo.md` (template: [.claude/rules/templates.md](.claude/rules/templates.md))
3. Add nav entry to latest `app/_data/docs_nav_kuma_<version>.yml`
4. Version-gate with `{% if_version %}` where needed; embed schema via `{% schema_viewer MeshFoo %}`
5. `mise run check && mise run test`

### New resource doc

Same as above with `mise run new:resource ResourceName`, editing `app/_src/resources/`.

### Editing existing docs

Source in `app/_src/`, preview with `mise run dev`, lint via `mise run check`.

### Plugin / frontend / tools changes

- Jekyll plugins: in-tree under `app/_plugins/` (hot-reloaded), gem at `jekyll-kuma-plugins/` (`mise run test:plugins`)
- Frontend: entrypoints `app/_assets/`, config `vite.config.ts` + `config/vite.json`, dev via `bundle exec foreman start` (`Procfile`)
- Shell tools: `tools/*.sh` must pass shellcheck; tests in `tools/spec/` (`mise run test:tools`)

## Liquid plugin reference

`{% if_version %}`, `{% schema_viewer %}`, `{% inc %}`, `{% policy_yaml %}`, `{% mermaid %}`, `{% json_schema %}` — see [.claude/rules/liquid-plugins.md](.claude/rules/liquid-plugins.md).
