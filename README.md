[![][kuma-logo]][kuma-url]

[![Netlify Status](https://api.netlify.com/api/v1/badges/28be1f67-3436-4df7-9114-49dce7ca9a4e/deploy-status)](https://app.netlify.com/sites/kuma/deploys)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/kumahq/kuma/blob/master/LICENSE)
[![Slack](https://chat.kuma.io/badge.svg)](https://chat.kuma.io/)
[![Twitter](https://img.shields.io/twitter/follow/KumaMesh.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=KumaMesh)

# Kuma website

This repository contains the source content and tooling for the Kuma website. See also [the source code for Kuma](https://github.com/kumahq/kuma). Kuma provides a control plane for service mesh that supports both Kubernetes and VM environments.

The website is built on [VuePress](https://vuepress.vuejs.org/) and is published with Netlify. It's open-source for the community to contribute to. Feel free to [submit an issue](https://github.com/kumahq/kuma-website/issues/new/choose) to propose changes or submit a patch if you want to write some docs! 

[Contact and chat](https://kuma.io/community) with the community in real-time if you get stuck or need clarification. We are here to help.

## Set up local builds with yarn

1.  Install:

    ```bash
    yarn install
    ```

1.  Run:

    ```bash
    yarn docs:dev
    ```

VuePress automatically opens a browser window and displays the local build after it finishes.

You can also run `yarn docs:build` for more complete output with error details if your builds fail.

## Set up local builds with Netlify

If you get errors on the Netlify server, it can help to [set up a local Netlify environment](https://docs.netlify.com/cli/get-started/).

It has happened, however, that `yarn docs:dev` AND the local Netlify build succeed, and the build still fails upstream. At which point … sometimes the logs can help, but not always.

WARNING: when you run a local Netlify build, your local `netlify.toml` is modified. Make sure to revert/discard the changes before you push your local.

## Add generated docs from protobufs

If you create a new policy resource for Kuma, you should rebuild the generated policyref docs.



## License

```
Copyright 2020 the Kuma Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

[kuma-url]: https://kuma.io/
[kuma-logo]: https://kuma-public-assets.s3.amazonaws.com/kuma-logo-v2.png
