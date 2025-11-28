# Contributing to Kuma's Website

Hello, and welcome. Whether you are looking for help, trying to report a bug, thinking about getting involved in the project or about to submit a patch, this document is for you. Its intent is to be both an entry point for newcomers to the community (with various technical backgrounds), and a guide/reference for contributors and maintainers.

## Where to seek help?

[Slack](https://kuma-mesh.slack.com) is the main chat channel used by the community and the maintainers of this project. If you do not have an existing account, please [sign up here](https://join.slack.com/t/kuma-mesh/shared_invite/zt-1rcll3y6t-DkV_CAItZUoy0IvCwQ~jlQ).

**Please avoid opening GitHub issues for general questions or help**, as those should be reserved for actual bug reports. The Kuma community is welcoming and more than willing to assist you on Slack.

## Where to report bugs?

Feel free to [submit an issue](https://github.com/kumahq/kuma-website/issues/new/choose) on the GitHub repository, we would be grateful to hear about it. Please provide a direct link to the webpage that contains the issue and make sure to respect the GitHub issue template, and include:

1. A summary of the issue
2. A list of steps to reproduce the issue

If you wish, you are more than welcome to propose a patch to fix the issue. See the [Submit a patch](#submitting-a-patch) section for more information on how to best do so.

## Contributing

We welcome contributions of all kinds, you do not need to code to be helpful. All of the following tasks are noble and worthy contributions that you can make without coding:

- Reporting a bug (see the [report bugs](#where-to-report-bugs) section)
- Helping other members of the community on Slack
- Fixing a typo in the documentation
- Providing your feedback on the proposed features and designs
- Reviewing Pull Requests

If you wish to contribute code (features or bug fixes), see the [Submitting a patch](#submitting-a-patch) section.

### Submitting a patch

Feel free to contribute fixes or minor features, we love to receive Pull Requests. If you are planning to develop a larger feature, come talk to us first on [Slack](#where-to-seek-help).

When contributing, please follow the guidelines provided in this document and [WRITING-DOCUMENTATION.md](WRITING-DOCUMENTATION.md). They will cover topics such as the different Git branches we use, the commit message format to use or the appropriate code style.

Once you have read them, and you are ready to submit your Pull Request, be sure to verify a few things:

- Run `mise check` to validate your changes (runs Vale, version urls, frontmatter, `markdownlint`, `shellcheck`)
- We do trunk based development so the only valid branch to open a PR against is `master`.
- Your commit history is clean: changes are atomic and the git message format was respected
- `Rebase` your work on top of the base branch (seek help online on how to use `git rebase`; this is important to ensure your commit history is clean and linear)

#### Linting and style checks

This repository uses automated linting to ensure consistency:

**Vale Linter** - Detects hardcoded values that should use Jekyll variables:

- Product names (`Kuma` → `{{site.mesh_product_name}}`)
- namespace names (`kuma-system` → `{{site.mesh_namespace}}`)
- Component names (`kuma-control-plane` → `{{site.mesh_cp_name}}`)
- Docker organization (`kumahq` → `{{site.mesh_docker_org}}`)
- Helm repository urls and names
- Style guide violations

**`markdownlint`** - Enforces consistent markdown formatting. Most issues can be auto-fixed with `mise mdlint:branch:fix`.

**Version url checker** - Detects hardcoded version urls:

- `/docs/X.Y.x/` format (e.g., `/docs/2.9.x/`) <!-- no-version-lint -->
- `/docs/X.Y.Z/` format (e.g., `/docs/2.9.0/`) <!-- no-version-lint -->

To suppress version url warnings for legitimate cases (legacy docs, migration guides), add a comment:

```markdown
See legacy docs at /docs/2.8.x/ <!-- no-version-lint -->
```

Run linting checks:

```sh
mise check              # Run all checks (Vale, version urls, frontmatter, markdownlint, shellcheck)
mise vale:branch        # Run Vale linter only
mise vale:version-urls  # Run version URL checker only
mise mdlint:branch      # Run markdownlint only
mise mdlint:branch:fix  # Fix markdownlint issues automatically
mise shellcheck         # Run shellcheck on tools/*.sh
```

#### Creating new resource docs

To create a new resource reference doc from template:

```sh
mise new:resource MeshService
```

This creates `app/_src/resources/meshservice.md` from the template. Update the nav file after creation.

#### Creating new policy docs

To create a new policy reference doc from template:

```sh
mise new:policy MeshExample
```

This creates `app/_src/policies/meshexample.md` from the template. Update the nav file after creation.

#### Page metadata

All documentation pages should include frontmatter metadata for SEO and search:

```yaml
---
title: Page Title
description: Brief description of the page content (1-2 sentences).
keywords:
  - keyword1
  - keyword2
  - keyword3
---
```

**Guidelines:**

- `description`: Required. Concise summary for search results and social sharing.
- `keywords`: Required. Maximum 3 keywords for optimal search indexing.

If the above guidelines are respected, your Pull Request will be reviewed by a maintainer.

If you are asked to update your patch by a reviewer, please do so. Remember: **you are responsible for pushing your patch forward**. If you contributed it, you are probably the one in need of it. You must be prepared to apply changes to it if necessary.

If your Pull Request was accepted and fixes a bug, adds functionality, or makes it significantly easier to use or understand Kuma's website, congratulations, you are now an official contributor to Kuma. Get in touch with us to receive your very own Contributor T-shirt.

#### Sign your work

The sign-off is a simple line at the end of the explanation for a commit. All commits need to be signed. Your signature certifies that you wrote the patch or otherwise have the right to contribute the material. The rules are pretty simple, if you can certify the below (from [developercertificate.org](https://developercertificate.org/)):

To signify that you agree to the DCO for a commit, you add a line to the git commit message:

```txt
Signed-off-by: Jane Smith <jane.smith@example.com>
```

In most cases, you can add this `signoff` to your commit automatically with the `-s` flag to `git commit`. You must use your real name and a reachable email address (sorry, no pseudonyms or anonymous contributions).

### Setup

#### Prerequisites

1. Install [mise](https://mise.jdx.dev/installing-mise.html).

#### Installation

Clone the repository and run:

```sh
mise run install
```  

#### `macOS` 15 installation issues

After upgrading to `macOS` 15, some users have encountered issues where the installation fails during `mise run install` with errors similar to:

```sh
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

[...]

compiling binder.cpp

[...]

In Gemfile:
  jekyll-contentblocks was resolved to 1.2.0, which depends on
    jekyll was resolved to 4.3.4, which depends on
      em-websocket was resolved to 0.5.3, which depends on
        eventmachine
make: *** [install] Error 5
```

To fix this issue, reinstall Xcode and recompile Ruby:

```sh
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
mise uninstall "ruby@$(cat .ruby-version)"
mise install
ruby -rrbconfig -e 'puts RbConfig::CONFIG["CXX"]' # should print "clang++"
```

If you still encounter issues with Clang when installing gems, try:

```sh
gem install <gem> -- --with-cflags="-Wno-incompatible-function-pointer-types"
```

### Development

To make changes to the docs or assets and see them reflected in the browser, start the site with:

```sh
mise dev
```

This runs `jekyll serve` and `vite` in the background, automatically rebuilding pages when docs or assets change. It also runs `netlify dev` to ensure redirects work locally.

### Production build

Before starting a production build, it’s recommended to clean previous builds to avoid issues.

To clean old static files and start the production build:

```sh
mise run serve:clean
```

Or, if you don't need to clean previous files, simply run:

```sh
mise run serve
```  

This will:

1. Use the `[build]` section from `netlify.toml` to generate the production version of static files using the configured build command.
2. Start a local Netlify server, simulating the production environment with redirects, environment variables, and other settings.

Once running, visit <http://localhost:7777> to browse the documentation.

### Developing kuma-website as a submodule in another Jekyll project

If you are developing `kuma-website` as a Git submodule inside another Jekyll project, you can use [Mutagen](https://mutagen.io) to sync files between repositories. This allows you to work on `kuma-website` while ensuring changes are reflected in the parent project.

To set up file syncing, run:

```sh
# Path to your local kuma-website repository
export SYNC_FROM="$HOME/projects/kumahq/kuma-website"
# Path to where kuma-website is located in the other project
export SYNC_TO="$HOME/projects/other/app/_src/.repos/kuma"

mutagen sync create \
  --mode one-way-replica \
  --name kuma-website \
  --ignore ".idea,node_modules,dist,.netlify,.jekyll-cache,.jekyll-metadata,app/.jekyll-cache,app/.jekyll-metadata,.bundle" \
  "$SYNC_FROM" "$SYNC_TO"
```

To observe the synchronization status, run:

```sh
mutagen sync monitor
```

If you need to stop synchronization, run:

```sh
mutagen sync terminate kuma-website
```

Since `kuma-website` does not use Jekyll’s default ports, you can run both projects simultaneously without conflicts.
