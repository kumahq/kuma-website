<template>
  <Shell :sidebar-items="sidebarItems">
    <template slot="page-content">
      <component
        :is="layoutComponentSelector"
        :sidebar-items="sidebarItems"
      />
    </template>
  </Shell>
</template>

<script>
import Shell from '@theme/global-components/Shell.vue'
import Page from '@theme/components/Page.vue'
import { resolveSidebarItems, redirectToLatestVersion } from '../util'

// reusable page template
import Shell from '@theme/components/custom/Shell.vue'

// specific page templates
import Home from '@theme/components/custom/Home.vue'
import Install from '@theme/components/custom/Install.vue'
import Community from '@theme/components/custom/Community.vue'
import RequestADemo from '@theme/components/custom/RequestADemo.vue'
import UseCases from '@theme/components/custom/UseCases.vue'
import Policies from '@theme/components/custom/Policies.vue'

export default {
  components: {
    Page,
    Sidebar,
    Navbar,
    Shell,
    Home,
    Install,
    Community,
    RequestADemo,
    UseCases,
    Policies
  },
  computed: {
    layoutComponentSelector() {

      /**
       * this function determines which page component
       * to load based on various parameters:
       * 
       * 1. is `home` set to true in the frontmatter?
       * 2. is a custom layout defined in the frontmatter?
       * 3. does the route have `layout` meta defined?
       * 4. if none of the above apply, fallback to the Page component
       * 
       */

      const fm = this.$page.frontmatter
      let layoutComponent

      /**
       * default to home if `home` is 
       * set to true in the frontmatter
       */
      if( fm.home ) {
        layoutComponent = 'Home'
      /**
       * or look for the layout defined in
       * the frontmatter
       */
      } else if( fm.layout ) {
        layoutComponent = fm.layout
      /**
       * otherwise fallback to the Page component
       */
      } else {
        layoutComponent = 'Page'
      }

      return layoutComponent
    },

    sidebarItems () {
      return resolveSidebarItems(
        this.$page,
        this.$page.regularPath,
        this.$site,
        this.$localePath
      )
    },
  }
}
</script>

<style>

</style>