<template>
  <form class="version-nav">
    <label for="doc-version-selector">Version</label>
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
import { mapGetters } from 'vuex'

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
      'releasesAsSelectValues'
    ])
  }
}
</script>
