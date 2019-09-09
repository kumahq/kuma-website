import Vuex from 'vuex'
import store from './theme/store/index'
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
}
