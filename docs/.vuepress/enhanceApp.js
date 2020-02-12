import Vuex from 'vuex'
import store from './theme/store/index'
import Layout from './theme/layouts/Layout'
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
   * Created an aliased route to 'latest'
   * for the Install page
   */
  router.addRoutes([
    {
      path: '/install/latest/',
      alias: `/install/${siteData.themeConfig.latestVer}/`,
      component: Layout,
      meta: {
        version: siteData.themeConfig.latestVer,
        layout: 'Install'
      }
    }
  ])
}
