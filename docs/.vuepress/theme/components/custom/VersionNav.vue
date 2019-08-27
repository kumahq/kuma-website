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
      'releasesAsSelectValues',
      'getLatestRelease'
    ]),

    // this is used as the model for the version selector
    defaultSelectedInstallVersion: {
      get() {
        const routePath = this.$route.path
        const test = '/docs/'
        
        if (routePath.startsWith(test)) {
          // if we're on a docs page, check the router path to get the version
          // our user is currently viewing and set the version selector value to it
          return this.$route.path.replace(/\//g,'').replace('docs','')
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
