[![][kuma-logo]][kuma-url]

[![Netlify Status](https://api.netlify.com/api/v1/badges/28be1f67-3436-4df7-9114-49dce7ca9a4e/deploy-status)](https://app.netlify.com/sites/kuma/deploys)

# Kuma Website
This is repository is the source code for [Kuma](http://kuma.io/docs)'s documentation website. Kuma is a universal open source control-plane for Service Mesh and Microservices that can run and be operated natively across both Kubernetes and VM environments, in order to be easily adopted by every team in the organization. If you are looking for the source code instead, please check out [Kuma's main repository](https://github.com/Kong/kuma). 

This website built on [VuePress](https://vuepress.vuejs.org/) and is open-source for the community to contribute to. Feel free to [submit an issue](https://github.com/Kong/kuma/issues/new) to propose changes or submit a patch if you want to write some code! 

[Contact and chat](https://kuma.io/community) with the community in real-time if you get stuck or need clarifications. We are here to help.

## Summary

- [Installation](#installation)
- [Build](#build)
- [Test](#test)

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
the latest version. Because of the order in which Netlify deployment and build functions 
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


[kuma-url]: https://kuma.io/
[kuma-logo]: https://kuma-public-assets.s3.amazonaws.com/kuma-logo.png