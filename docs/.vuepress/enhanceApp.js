import Vuex from 'vuex'
import store from './theme/store/index'

export default ({
  Vue,
  options,
  router,
  siteData
}) => {

  Vue.use(Vuex)

  /**
   * Site styles
   */
  require('./theme/styles/custom/styles.scss')
  
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
}
