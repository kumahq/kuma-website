# Writing documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work 
as you write your documentation.

## Versions

The code uses trunk based development where `master` is the `trunk` branch.

A single sourced folder in [app/_src](app/_src) is used for each version of Kuma. We use a Jekyll plugin to dynamically generate pages from a single source file.

For the future non-patch versions of Kuma, changes can be made to the [docs_nav_kuma_dev.yml](app/_data/docs_nav_kuma_dev.yml) file. 

## Writing docs for a new feature

If you are writing docs for a new feature you'll want to add it in the [src](app/_src) folder.

Since content is single sourced, you must use [conditional rendering](link_to_cond_rendering) to ensure that the new feature content only displays for that version. For example:

```
{% if_version eq:2.1.x %}
This will only show for version 2.1.x
{% endif_version %}
```

## Diagrams

The team is moving diagrams to [Google slides](https://docs.google.com/presentation/d/1qvIKeYfcuowrHW1hV9fk9mCptt3ywroPBUYFjMj9gkk/edit#slide=id.g13d0c1ffb72_0_67).
Instructions are in the first slide.
Ask a maintainer to get write access.

## Cutting a new release

To cut the dev release, create a duplicate of the [docs_nav_kuma_dev.yml](app/_data/docs_nav_kuma_dev.yml) file and then rename one of the files to "docs_nav_kuma_[version].yml". Update the `release: dev` metadata in the new release file with the release version.

Update the `app/_data/versions.yml` file with metadata specific to this release, for example: actual patches released, helm versions.

## Set up local builds with yarn

Before start, make sure that installed Ruby version is the same as in the `.ruby-version` file.

1.  Install:

    ```bash
    make install
    ```

1.  Build:

    ```bash
    make build
    ```

1.  Serve:

    ```bash
    make serve
    ```

You will need to run `make build` after making any changes to the content. Automatic rebuilding will be added in November 2022.

## Set up local builds with Netlify

If you get errors on the Netlify server, it can help to [set up a local Netlify environment](https://docs.netlify.com/cli/get-started/).

It has happened, however, that `make build` and the local Netlify build succeed, and the build still fails upstream. At which point … sometimes the logs can help, but not always.

WARNING: when you run a local Netlify build it modifies your local `netlify.toml`. Make sure to revert/discard the changes before you push your local.

## Add generated docs from protobufs

If you create a new policy resource for Kuma, you should rebuild the generated policy reference documentation.

## Markdown features
For more information about the Markdown features and formatting that is supported, see the following:

* [Markdown rules and formatting](https://docs.konghq.com/contributing/markdown-rules/)
* [Reusable content](https://docs.konghq.com/contributing/includes/)

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
