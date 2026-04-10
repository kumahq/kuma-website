# Anti-patterns

- Editing `app/docs/2.x.x/*.md` directly — generated from `app/_src/`, overwritten on next build.
- Editing `app/docs/dev/crds`, `app/docs/dev/protos`, `app/docs/raw/` — synced from the Kuma repo by `.github/workflows/` update jobs.
- Hardcoded version URLs (`/docs/2.10.x/...`) — use `/docs/{{ page.release }}/...`; caught by `tools/check-version-urls.sh`.
- Omitting `{% if_version %}` for features that only exist in some versions — content leaks into older versions.
- Adding pages without updating `app/_data/docs_nav_kuma_<version>.yml` — page builds but is invisible in the sidebar.
- Treating `mise run build` as the full check — build passing ≠ lint/tests passing. Run `mise run check` and `mise run test`.
- Modifying `netlify.toml` during local `netlify dev` — it mutates the file; revert before pushing.
- Suppressing linter errors with inline disable directives — add Vale terms to `.github/styles/Vocab/`, restructure markdown for markdownlint, fix code for shellcheck/rubocop.
- More than 3 keywords in policy frontmatter — Algolia search constraint.
