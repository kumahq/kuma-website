# Writing Documentation

After starting the site locally, navigate to `http://localhost:8080/docs/`. This is where you can view your work 
as you create documentation.

All documentation markdown files are stored in versioned folders: `/docs/docs/0.1.0/`. As you write documentation 
the sidebar navigation will automatically update to reflect your markdown file heading structure (please see the 
existing sample documentation files to get an idea of how things are structured).

If you want to include partials into your documentation, you can do this:

```
!!!include(../.partials/what-is-Konvoy.md)!!!
```

This allows you to use the same content across various documentation and saves us from having to repeat content 
that might never (or very rarely) change.

## Creating a new version

1. Copy the most recent release folder and rename it accordingly by its version
2. Make your edits in the new release folder you've created
3. Add your new release number to the `releases.json` file located in `.vuepress/public`

The website will automatically build the release list from the `releases.json` file. This is what is used for things 
like the Install page and the version selector that appears above the sidebar navigation on the Documentation page. 
This file will also automatically create the routes needed for each new release, which is super important.

The Install and Documentation pages will also always redirect to the documentation and installation methods for the 
latest release to ensure that our users are always looking at the latest docs at any time.

### Caveats

The way VuePress handles the automatic sidebar navigation functionality may require some tweaking to make its output 
more ideal for our usage. Since we have multiple folders for each versioned release of Konvoy, the current automatic 
navigation generation is not perfect.