<template>
  <div class="version-nav">
    <DropdownLink :item="{
      text: 'Versions',
      items: this.releasesAsRouterLinks,
      type: 'links'
    }"/>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import DropdownLink from '@theme/components/DropdownLink'
import NavLink from '@theme/components/NavLink'

export default {
  name: 'VersionNav',
  components: {
    DropdownLink
  },
  computed: {
    ...mapGetters([
      'releasesAsRouterLinks'
    ])
  }
}
</script>
