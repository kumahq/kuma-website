<script>
/**
 * Redirect.vue
 * 
 * This is a functional component that simply passes the user
 * to the latest version.
 * 
 * Example:
 * - User navigates to /docs/
 * - This component checks to see what the latest version is
 * - The component then redirects them to /docs/1.2.3/
 *    (or whatever the latest version happens to be)
 */

import { mapGetters } from 'vuex'

export default {
  name: 'Redirect',
  mounted() {
    this.redirectToLatestReleaseDocs()
  },
  render() {},
  methods: {
    ...mapGetters([
      'getLatestRelease'
    ]),

    redirectToLatestReleaseDocs() {
      // let's fetch the releases data so we can grab
      // the latest version in order to build the redirect
      if(process.env.NODE_ENV !== 'development' && this.$page.path === '/docs/') {
        this.$router.push({
          path: `${this.$page.path}/latest/`
        })
      } else {
        this.$router.push({
          path: `${this.$page.path}${this.getLatestRelease()}/`
        })
      }
    }
  }
}
</script>