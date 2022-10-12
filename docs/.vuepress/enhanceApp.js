import Vuex from 'vuex'
import store from './theme/store/index'
// import Layout from './theme/layouts/Layout'

import '@kongponents/styles'
import 'vuepress-plugin-tabs/dist/themes/default.styl'
import './theme/styles/styles.scss'

import VueAnalytics from 'vue-analytics'

export default ({
  Vue,
  isServer,
  router,
  siteData
}) => {

  // setup Vuex
  Vue.use(Vuex)
  
  // setup VueAnalytics for creating GA events and other things
  Vue.use(VueAnalytics, {
    id: siteData.themeConfig.gaCode
  })
  
  /**
   * Global Mixins
   */
  Vue.mixin({
    store: store(siteData.themeConfig.versions, siteData.themeConfig.latestVersion, siteData.themeConfig.installMethods),
    computed: {
      /**
       * Creates an easy way to access site data globally
       */
      getSiteData() {
        return siteData
      },
      /**
       * Get the latest version
       * Good for use in pages, etc.
       */
      latestVersion() {
        return siteData.themeConfig.latestVersion
      }
    }
  })

  /**
   * Creates an aliased route to 'latest'
   * for the Install page. This is not done
   * within `install-route-builder.js` because
   * we need to be able to have an alias on the route
   * and the `additionalPages` feature of VuePress
   * does not allow `alias` on routes.
   */

  router.addRoutes([
    {
      path: '/install/latest/',
      alias: `/install/${siteData.themeConfig.latestVersion}/`,
      name: 'InstallLatest'
    },
    // {
    //   path: '/docs/latest/',
    //   alias: `/docs/${siteData.themeConfig.latestVersion}/`,
    //   name: 'DocsLatest'
    // }    
  ])
}
