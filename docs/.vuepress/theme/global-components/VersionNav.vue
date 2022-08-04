<template>
  <form class="version-nav">
    <label for="doc-version-selector">Version</label>
    <select
      name="doc-version-selector"
      class="version-selector"
      id="version-selector"
      v-model="defaultSelectedInstallVersion">
      <option 
        v-for="item in releasesAsSelectValues" 
        :value="item.version" 
        :key="item.version">
        {{item.text}}
      </option>
    </select>
  </form>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'VersionNav',
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
      'getLatestRelease'
    ]),

    // this is used as the model for the version selector
    defaultSelectedInstallVersion: {
      get() {
        if (this.$page.version) {
         return this.$page.version
        }
        return this.getLatestRelease
      },
      set(value) {
        this.redirectToSelectedDocVersion(value)
      }
    }
  }
}
</script>
