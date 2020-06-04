[![][kuma-logo]][kuma-url]

[![Netlify Status](https://api.netlify.com/api/v1/badges/28be1f67-3436-4df7-9114-49dce7ca9a4e/deploy-status)](https://app.netlify.com/sites/kuma/deploys)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/Kong/kuma/blob/master/LICENSE)
[![Slack](https://chat.kuma.io/badge.svg)](https://chat.kuma.io/)
[![Twitter](https://img.shields.io/twitter/follow/kumamesh.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=kumamesh)

# Kuma Website
This is repository is the source code for [Kuma](http://kuma.io/docs)'s documentation website. Kuma is a universal open source control-plane for Service Mesh and Microservices that can run and be operated natively across both Kubernetes and VM environments, in order to be easily adopted by every team in the organization. If you are looking for the source code instead, please check out [Kuma's main repository](https://github.com/Kong/kuma). 

This website is built on [VuePress](https://vuepress.vuejs.org/) and is open-source for the community to contribute to. Feel free to [submit an issue](https://github.com/Kong/kuma/issues/new) to propose changes or submit a patch if you want to write some code! 

[Contact and chat](https://kuma.io/community) with the community in real-time if you get stuck or need clarifications. We are here to help.

## Summary

- [🚀 Installation](#installation)
- [🛠 Build](#build)
- [🧪 Test](#test)
- [✂️ Cutting a new release](#cutting-a-new-release)

## Installation

After you forked and cloned the repository, follow the steps below to setup the local dev environment.

### 1. Install the required packages
```bash
yarn install
```

### 2. Run the local dev environment
```bash
yarn docs:dev
```
You can now navigate to [http://localhost:8080/](http://localhost:8080/).

---

## Build

### Building Locally
```bash
yarn docs:build
```
This creates a `dist` folder within `.vuepress`. This script is good in case you want 
to test the compiled site locally with something like [http-server](https://www.npmjs.com/package/http-server).

### Netlify Build Flow
The Docs and Install pages have 301 redirects that ensure their bare URLs always go to 
the latest version of Kuma. Because of the order in which Netlify deployment and build functions 
are run, the full deployment build script is handled within the [netlify.toml](netlify.toml) 
file.

### Netlify, `netlify.toml` and `[build]`
At the top of our [`netlify.toml`](netlify.toml) file, there is a build script under `[build]`.

**It will:**

1. Run the [`setup-redirects`](/setup-redirects/) Node script, which writes the appropriate 
redirects in [Netlify format](https://www.netlify.com/blog/2019/01/16/redirect-rules-for-all-how-to-configure-redirects-for-your-static-site/) 
to the end of the `netlify.toml` file
2. Runs `vuepress build docs` which will build the site accordingly

---

## Test

After you make changes to the code, run the following command to run any existing and new tests:
```bash
yarn test
```

Before submitting a [pull request](https://github.com/Kong/kuma-website/pulls), make sure all tests are passing. 

---

# Cutting a new release

This is a Node script for making the creation of new release documentation easy and painless!

## What does the script do?
* It will clone the `draft` directory located in [/docs/docs/draft/](/docs/docs/draft/) to a new directory 
that is named by the version specified (we'll go into detail on this further down)
* After cloning the directory, it will automatically find and replace all instances of `DRAFT` in the documentation
markdown files, with the new version.
  * A Regular Expression string is used that only looks for `DRAFT` by itself and in all caps
* It will add the new sidebar navigation structure for the new version to the [`sidebar-nav.js`](/docs/.vuepress/site-config/sidebar-nav.js) file. This file controls the documentation sidebar navigation in VuePress via the [`additionalPages`](https://vuepress.vuejs.org/plugin/option-api.html#additionalpages) API option
  * This function will base the page structure on the previous version's page structure. This was the easiest way to ensure they stay uniform since they rarely change. If this page structure changes, we recommend editing the `sidebar-nav.js` configuration by hand for your version. In the future, your new structure will be grabbed and used going forward since the script will always grab the latest version's page structure as a base. So you wouldn't have to make this revision each time
* It will append the new version to the [`releases.json`](/docs/.vuepress/public/releases.json) file. This file is used by the website for handling versioning in the documentation and install pages

## How do I use the script?

First and foremost, run `yarn` to install any new modules. Once you've done this, run `npm link`. This will link the `kumacut` command
to your bin so you can run it globally.

### Command breakdown

```
Usage: kumacut [options] [command]

Options:
  -v, --version     Output the current version of this script.
  -h, --help        output usage information

Commands:
  latest            display the latest version of Kuma
  bump              this will simply cut a new patch and bump the patch number up by 1
  new <type> [ver]  options: major, minor, custom <version>
```

* `kumacut latest` - This will display the latest version from `releases.json`. Good as a reference if needed
* `kumacut bump` - A quick command to increment the patch in the latest version by `1`
* `kumacut new major|minor` - This command offers more control. You can increment the latest version by `1` for a major or minor release
* `kumacut new custom <version>` - If you want to specify the version number yourself, you can replace `<version>` with something like `2.3.4` (don't worry if you happen to write `v2.3.4` - the script is smart enough to strip this out)

[kuma-url]: https://kuma.io/
[kuma-logo]: https://kuma-public-assets.s3.amazonaws.com/kuma-logo-v2.png
