export default ({
  Vue,
  options,
  router,
  siteData
}) => {

  /**
   * Site styles
   */
  require('./theme/styles/custom/styles.scss')
  
  /**
   * Global Mixins
   */
  Vue.mixin({
    computed: {
      // Creates an easy way to access site data globally
      getSiteData() {
        return siteData
      }
    }
  })
}
