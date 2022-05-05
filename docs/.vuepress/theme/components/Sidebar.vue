<template>
  <div class="sidebar-wrapper">
    <aside class="sidebar">
      <VersionNav/>
      <AlgoliaSearchBox v-if="$site.themeConfig.algolia.indexName && $page.frontmatter.search === true"
                        :options="algolia" class="nav-item"/>

      <NavLinks/>

      <slot name="top"/>
      <SidebarLinks :depth="0" :items="items"/>
      <slot name="bottom"/>
    </aside>
  </div>
</template>

<script>
import AlgoliaSearchBox from '@vuepress/theme-default/components/AlgoliaSearchBox.vue'
import VersionNav from '@theme/global-components/VersionNav'
import SidebarLinks from '@theme/components/SidebarLinks'
import NavLinks from '@theme/components/NavLinks'

export default {
  name: 'Sidebar',
  components: {
    AlgoliaSearchBox,
    SidebarLinks,
    NavLinks,
    VersionNav
  },
  props: ['items'],

  computed: {
    algolia() {
      let cfg = this.$themeLocaleConfig.algolia || this.$site.themeConfig.algolia || {};
      if (this.$page.version) {
        cfg.algoliaOptions = {
          facetFilters: ["section:docs", `docsversion:${this.$page.version}`],
        };
      }
      return cfg
    },
  },
}
</script>
