[![Netlify Status](https://api.netlify.com/api/v1/badges/28be1f67-3436-4df7-9114-49dce7ca9a4e/deploy-status)](https://app.netlify.com/sites/kuma/deploys)

# Kuma Website
This is the main website and documentation hub for Kuma. It is built on [VuePress](https://vuepress.vuejs.org/).

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

## Building

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