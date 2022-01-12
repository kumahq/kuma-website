/**
 * Install page version URL builder
 *
 * This pulls all of the versions from the releases
 * JSON and builds the routes accordingly.
 *
 * This method leverages the `additionalPages`
 * feature of VuePress:
 *
 * https://v1.vuepress.vuejs.org/plugin/option-api.html#additionalpages
 *
 * @todo figure out how to get this to work via
 * `router.addRoutes` instead (ran into problems
 * with it in VuePress)
 *
 * @returns { array }
 *
 */

const releases = require("../public/releases.json");

module.exports = function() {
  const releaseArray = [{
    path: "/install/draft/",
      meta: {
        version: "draft"
      },
      frontmatter: {
        sidebar: false,
        layout: "Install"
      }
    }
  ]

  /**
   * This builds the URLs for the installation
   * page. The `latest` route is handled as a raw Vue
   * route in `enhanceApp.js` so that we can give it 
   * an `alias`, among other parameters.
   */

  releases
    .forEach(item => {
      releaseArray.push({
        path: `/install/${item}/`,
        meta: {
          version: item
        },
        frontmatter: {
          sidebar: false,
          layout: "Install"
        }
      });
    })

  return releaseArray
}