import Vuex from 'vuex'
import store from './theme/store/index'
import Layout from './theme/layouts/Layout'
import 'vuepress-plugin-tabs/dist/themes/default.styl'
import './theme/styles/styles.scss'

export default ({
  Vue,
  options,
  router,
  siteData
}) => {

  Vue.use(Vuex)
  
  /**
   * Global Mixins
   */
  Vue.mixin({
    store: store,
    computed: {
      // Creates an easy way to access site data globally
      getSiteData() {
        return siteData
      }
    }
  })

  /**
   * Get the latest version
   * Good for use in pages, etc.
   */
  Vue.mixin({
    computed: {
      latestVer() {
        return siteData.themeConfig.latestVer
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
      alias: `/install/${siteData.themeConfig.latestVer}/`,
      name: 'InstallLatest'
    },
    // {
    //   path: '/docs/latest/',
    //   alias: `/docs/${siteData.themeConfig.latestVer}/`,
    //   name: 'DocsLatest'
    // }
  ])
}
