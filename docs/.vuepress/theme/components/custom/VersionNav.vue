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
        const routePath = this.$route.path
        const test = '/docs/'
        
        // first, check to see that we're on a docs page:
        if (routePath.startsWith(test)) {
          // 1. if we're on a docs page, check the router path and extract the version
          // 2. set the version selector to the extracted version
          return this.$route.path.split('/')[2]
        }
        else {
          // if we're on a page outside of the docs, grab the latest release
          // from our Vuex Store and set the version selector value to that instead
          return this.getLatestRelease
        }
      },
      set(value) {
        this.redirectToSelectedDocVersion(value)
      }
    }
  }
}
</script>
