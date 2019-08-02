<template>
  <form class="version-nav">
    <select name="doc-version-selector" @change="redirectToSelectedDocVersion($event.target.value)">
      <option 
        v-for="item in releasesAsSelectValues" 
        :value="item.version" 
        :key="item.version" 
        :selected='selectedDocVersion === item.version'
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
  data() {
    return {
      selectedDocVersion: this.$route.path.replace(/\//g,'').replace('docs','')
    }
  },
  methods: {
    redirectToSelectedDocVersion(val) {
      this.$store.commit('updateSelectedDocVersion', val)
      this.$router.push({
        path: `/${this.getSiteData.themeConfig.docsDir}/${val}/`,
        params: {
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
