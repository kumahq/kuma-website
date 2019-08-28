<template>
  <aside class="sidebar">
    <VersionNav/>

    <!-- <AlgoliaSearchBox
      v-if="isAlgoliaSearch"
      :options="algolia"
    /> -->
    <!-- <SearchBox v-else-if="$site.themeConfig.search !== false && $page.frontmatter.search !== false"/> -->

    <NavLinks/>

    <slot name="top"/>
    <SidebarLinks :depth="0" :items="items"/>
    <slot name="bottom"/>
  </aside>
</template>

<script>
import AlgoliaSearchBox from '@AlgoliaSearchBox'
import SearchBox from '@SearchBox'
import VersionNav from '@theme/global-components/VersionNav'
import SidebarLinks from '@theme/components/SidebarLinks'
import NavLinks from '@theme/components/NavLinks'

export default {
  name: 'Sidebar',
  components: {
    AlgoliaSearchBox,
    SearchBox,
    SidebarLinks,
    NavLinks,
    VersionNav
  },
  props: ['items']
}
</script>