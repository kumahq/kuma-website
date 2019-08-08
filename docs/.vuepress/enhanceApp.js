import Vuex from 'vuex'
import store from './theme/store/index'
import './theme/styles/styles.scss'
import InlineIcon from './theme/components/custom/InlineIcon.vue'

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
   * Global components
   */
  Vue.component('InlineIcon', () => import('./theme/components/custom/InlineIcon.vue'))
}
