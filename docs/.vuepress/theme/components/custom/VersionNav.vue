<template>
  <form class="version-nav">
    <select name="doc-version-selector" @change="redirectToSelectedDocVersion($event.target.value)">
      <option 
        v-for="item in releasesAsSelectValues" 
        :value="item.version" 
        :key="item.version" 
        :selected='item.version === getSelectedDocVersion'
      >
        {{item.text}}
      </option>
    </select>
  </form>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
import DropdownLink from '@theme/components/DropdownLink'

export default {
  name: 'VersionNav',
  methods: {
    redirectToSelectedDocVersion(val) {
      this.$store.commit('updateSelectedDocVersion', val)
      this.$router.push({
        path: `/${this.getSiteData.themeConfig.docsDir}/${val}/`,
        meta: {
          version: val
        }
      })
    }
  },
  computed: {
    ...mapGetters([
      'releasesAsSelectValues',
      'getReleaseList',
      'getSelectedDocVersion'
    ])
  }
}
</script>
