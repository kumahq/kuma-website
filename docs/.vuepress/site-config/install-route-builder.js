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

module.exports = function() {
  const releases = require("../public/releases.json")
  const releaseArray = []

  for (let i = 0; i < releases.length; i++) {
    releaseArray.push({
      path: `/install/${releases[i]}/`,
      meta: {
        version: releases[i]
      },
      frontmatter: {
        sidebar: false,
        layout: "Install"
      }
    });
  }

  return releaseArray
}