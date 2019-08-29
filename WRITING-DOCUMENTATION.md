# Writing Documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work 
as you write your documentation.

## 1. Creating a new version

1. Copy the most recent release folder and rename it accordingly by its version -- each version folder is located in 
[`/docs/docs/](/docs/docs/) (please see the [latest-semver documentation](https://github.com/sindresorhus/latest-semver) 
for structuring version folders properly)
2. Make your edits in the new release folder you've created -- you can run `yarn docs:dev` to view your changes locally
3. Add your new release number to the `releases.json` file located in `.vuepress/public` -- don't worry too much about ordering version numbers here because the app will always automatically grab the latest version 
via [latest-semver](https://github.com/sindresorhus/latest-semver)

The website will automatically build the release list from the `releases.json` file. This is what is used for things 
like the Install page and the version selector that appears at the top of the sidebar on the Documentation page. 
This file will also automatically create the routes needed for each new release, which is super important.

The Install and Documentation pages will also always redirect to the documentation and installation methods for the 
latest release to ensure that our users are always looking at the latest docs at any time.

## 2. Setting up the initial sidebar for new versions

Because the automatic sidebar functionality of VuePress is not quite perfect, we are using a combination of its 
automatic features, and some manual control. Within the [VuePress `config.js`](config.js) file, you'll see this:

``` js
const sidebarNav = {
  "/docs/0.1.0/": [
    "",
    "getting-started/",
    "documentation/",
    "tutorials/",
    "installation/",
    "community/"
  ],
  "/docs/0.2.0/": [
    "",
    "getting-started/",
    "documentation/",
    "tutorials/",
    "installation/",
    "community/"
  ]
};
```
This is the primary template for each version's sidebar navigation on the documentation pages.

Each new version needs its own navigation block with the primary links below it as seen above. The blank `""` 
below `/docs/0.2.0/` will automatically generate a nav item in the VuePress sidebar to the main page for that 
version. The named sub-pages below each version are controlled by their markdown files that share the same name.

### Example:

- `/docs/0.2.0/getting-started/README.md` - compiles to => `/docs/0.2.0/getting-started/index.html`
- `/docs/0.2.0/community/README.md` - compiles to => `/docs/0.2.0/community/index.html`

**When creating new versions, make sure to add them accordingly to the aforementioned `sidebarNav` array.**

Once the above structure is in place, the sidebar navigation will automatically be populated with anchor links 
that are derived from the headers in your markdown file for each documentation page. We eventually want to 
automate this process as to save time and reduce the chance for error.

You can read more about VuePress' sidebar handling [in the official VuePress documentation](https://vuepress.vuejs.org/default-theme-config/#sidebar)

## 3. Markdown extras and out-of-box features

### Including partials
If you want to include partials into your documentation:

```
!!!include(../.partials/what-is-Kuma.md)!!!
```

### Out-of-box features
If you want to see the full set of markdown features VuePress offers, please refer to [the official VuePress
markdown documentation](https://vuepress.vuejs.org/guide/markdown.html).

---

## VuePress Resources

- [How it works / introduction](https://vuepress.vuejs.org/guide/#how-it-works)
- [Sidebar handling](https://vuepress.vuejs.org/default-theme-config/#sidebar)
- [Markdown features](https://vuepress.vuejs.org/guide/markdown.html)