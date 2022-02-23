# Writing Documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work 
as you write your documentation.

## Versions

We do trunk based development (master is the `trunk` branch).

There's a folder in [docs/docs](docs/docs) for each minor version of Kuma. 
There is a special folder for the future non patch version of Kuma which is called [dev](docs/docs/dev).

## Writing docs for a new feature

If you are writing docs for a new feature you'll want to add it in the [dev](docs/docs/dev) folder.

## Cutting a new release

To cut the dev release copy paste the `dev` folder and rename it to the correct version:

```shell
# Create a 1.5.x release
cp docs/docs/dev docs/docs/1.5.x
```

Update the `docs/docs/<version>/versions.json` with metadata specific to this release (actual patches that are released, helm versions...).

Once the release is ready make sure to update the `latest` entry in the `versions.json` file:

```json
{
  "helm": ["0.9.0"],
  "kuma": [
    "1.5.0"
  ],
  "latest": true
}
```

## Fixing typos

Sometimes it's possible that your fix applies to more than 1 version.
If that's the case you can use our backporting script to easily apply a patch to multiple versions here's how to do this:

- Fix the highest version
- Identify the list of versions which benefit from this patch
- Use `./backport.sh <versionWithChange> <versionToBackport1> <versionToBackport2>` (.e.g: `./backport.sh dev 1.4.x 1.3.x` will apply the changes in dev to 1.4.x and 1.3.x).
- Commit your change

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

## Markdown features
If you want to see the full set of markdown features VuePress offers, please refer to [the official VuePress
markdown documentation](https://vuepress.vuejs.org/guide/markdown.html).
