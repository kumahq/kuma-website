<template>
  <Shell :sidebarItems="sidebarItems">
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

// specific page templates
import Home from '@theme/components/custom/Home.vue'
import Install from '@theme/components/custom/Install.vue'
import Community from '@theme/components/custom/Community.vue'
import RequestADemo from '@theme/components/custom/RequestADemo.vue'
import UseCases from '@theme/components/custom/UseCases.vue'

export default {
  components: {
    Shell,
    Page,
    Home,
    Install,
    Community,
    RequestADemo,
    UseCases
  },
  computed: {
    layoutComponentSelector() {

      // this function determines which page component
      // to load. if a markdown file has the `layout`
      // attribute defined in its frontmatter, this
      // function will load that template accordingly.
      // otherwise, it will load the homepage, or
      // fallback to the default `Page` component.

      const fm = this.$page.frontmatter
      let layoutComponent

      if( fm.home ) {
        layoutComponent = 'Home'
      } else if( fm.layout ) {
        layoutComponent = fm.layout
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