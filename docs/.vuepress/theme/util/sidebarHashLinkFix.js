/**
 * Sidebar hashlink fix
 *
 * This is an identified bug within VuePress
 * Source: https://github.com/vuejs/vuepress/issues/1499
 */

export default {
  watch: {
    $page(newPage, oldPage) {
      if (newPage.key !== oldPage.key) {
        requestAnimationFrame(() => {
          if (this.$route.hash) {
            const element = document.getElementById(this.$route.hash.slice(1))

            if (element && element.scrollIntoView) {
              element.scrollIntoView()
            }
          }
        })
      }
    }
  }
}
