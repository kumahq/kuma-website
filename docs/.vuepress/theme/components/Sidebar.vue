<template>
  <div class="sidebar-wrapper">
    <aside class="sidebar">
      <VersionNav/>

      <NavLinks/>

      <slot name="top"/>
      <SidebarLinks :depth="0" :items="items"/>
      <slot name="bottom"/>
    </aside>
  </div>
</template>

<script>
import VersionNav from '@theme/global-components/VersionNav'
import SidebarLinks from '@theme/components/SidebarLinks'
import NavLinks from '@theme/components/NavLinks'

export default {
  name: 'Sidebar',
  components: {
    SidebarLinks,
    NavLinks,
    VersionNav
  },
  props: ['items']
}
</script>
