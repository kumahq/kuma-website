# kuma-website

Use `mise run ...` for repo workflows.

## Commands

- `mise run install` - install Ruby, Node, yarn, gems, and npm packages
- `mise run dev` - local Jekyll + Vite + Netlify-style development server
- `mise run serve` - serve with Netlify
- `mise run build` - production build
- `mise run check` - Vale + version URL check + frontmatter validation + markdownlint + shellcheck
- `mise run test` - root RSpec suite
- `mise run test:plugins` - `jekyll-kuma-plugins` RSpec suite
- `mise run test:tools` - ShellSpec for `tools/`

## Single-test commands

- Root RSpec: `bundle exec rspec spec/kuma_plugins/liquid/tags/schema_viewer_spec.rb`
- Root RSpec at a line: `bundle exec rspec spec/kuma_plugins/liquid/tags/schema_viewer_spec.rb:12`
- Plugin gem spec: `cd jekyll-kuma-plugins && bundle exec rspec spec/jekyll/kuma_plugins/liquid/tags/policyyaml_spec.rb`
- ShellSpec file: `shellspec tools/spec/validate_frontmatter_spec.sh`

## Architecture

- Jekyll reads from `app/` and writes the site to `dist/`.
- Docs source lives in `app/_src/`; versioned docs under `app/docs/<version>/` are generated and should not be edited directly.
- `jekyll-generator-single-source` expands `app/_src/` into versioned docs using `app/_data/versions.yml` and `app/_data/docs_nav_kuma_*.yml`.
- Frontend assets live in `app/_assets/` and are built by Vite (`vite.config.ts`, `config/vite.json`).
- Custom Jekyll behavior is split between in-tree plugins in `app/_plugins/` and the extracted gem in `jekyll-kuma-plugins/`.
- Netlify config in `netlify.toml` is the production-serving reference; local `mise run serve` mirrors it more closely than raw Jekyll.

## Key conventions

- Edit `app/_src/`, never `app/docs/<version>/`.
- Version-gate divergent docs with `{% if_version %}`.
- Never hardcode docs version URLs; use `/docs/{{ page.release }}/...`.
- New docs pages must also be added to the latest `app/_data/docs_nav_kuma_<version>.yml`.
- For new policy/resource reference docs, start from `mise run new:policy ...` or `mise run new:resource ...`.
- Prefer existing Liquid helpers such as `{% schema_viewer %}`, `{% policy_yaml %}`, `{% inc %}`, and `{% mermaid %}` instead of hand-rolled equivalents.

## Verification

- Run `mise run check` after doc changes, not just `mise run build`.
- If you changed markdown, run `mise run mdlint:branch` early. It lints the entire changed file, not just your edited lines, so touching legacy files such as `app/_src/policies/introduction.md` can surface pre-existing violations.
- Use `mise run mdlint:branch:fix` for safe autofixes when appropriate.
- When using inline HTML in markdown (for example `<sup>`), do not rely on Markdown links inside the HTML tag. Use plain HTML links such as `<sup><a href="#section">note</a></sup>` and preview the rendered result in `mise run dev`.
