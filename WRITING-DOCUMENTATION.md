# Writing documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work 
as you write your documentation.

## Versions

The code uses trunk based development where `master` is the `trunk` branch.

A folder in [docs/docs](docs/docs) exists for each minor version of Kuma. 
There is a special folder for the future non patch version of Kuma which is called [dev](docs/docs/dev).

## Writing docs for a new feature

If you are writing docs for a new feature you'll want to add it in the [dev](docs/docs/dev) folder.

## Diagrams

The team is moving diagrams to [Google slides](https://docs.google.com/presentation/d/1qvIKeYfcuowrHW1hV9fk9mCptt3ywroPBUYFjMj9gkk/edit#slide=id.g13d0c1ffb72_0_67).
Instructions are in the first slide.
Ask a maintainer to get write access.

## Cutting a new release

To cut the dev release copy paste the `dev` folder and rename it to the correct version:

```shell
# Create a 1.5.x release
cp docs/docs/dev docs/docs/1.5.x
```

Update the `docs/docs/<version>/versions.json` with metadata specific to this release e.g: actual patches released, helm versions.

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
If that's the case you can use the backport script to easily apply a patch to multiple versions here's how to do this:

- Fix the highest version
- Identify the list of versions which benefit from this patch
- Use `./backport.sh <versionWithChange> <versionToBackport1> <versionToBackport2>` (.e.g: `./backport.sh dev 1.4.x 1.3.x` applies the changes in dev to 1.4.x and 1.3.x).
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

It has happened, however, that `yarn docs:dev` and the local Netlify build succeed, and the build still fails upstream. At which point … sometimes the logs can help, but not always.

WARNING: when you run a local Netlify build it modifies your local `netlify.toml`. Make sure to revert/discard the changes before you push your local.

## Add generated docs from protobufs

If you create a new policy resource for Kuma, you should rebuild the generated policy reference documentation.

## Markdown features
If you want to see the full set of markdown features VuePress offers, please refer to [the official VuePress
markdown documentation](https://vuepress.vuejs.org/guide/markdown.html).

## Vale

Vale is the tool used for linting the Kuma docs.
The Github action only checks changed lines in your PR.

You can [install Vale](https://vale.sh/docs/vale-cli/installation/)
and run it locally from the repository root with:

```shell
vale sync # only necessary once in order to download the styles
vale <any files changed in your PR or ones you want to check>
```

### Spurious warnings

If Vale warns or errors incorrectly,
the usual fix is to add the word or phrase
to the vocab list in `.github/styles/Vocab`.
