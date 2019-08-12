<template>
  <div class="page-container page-container--install">

    <header class="page-header">
      <h1>Install {{$site.title}}</h1>
      
      <div v-if="this.getInstallMethods && this.getInstallMethods.length" class="version-selector-wrapper">
        <form>
          <select name="version-selector" id="version-selector" @change="updateInstallPath($event.target.value)">
            <option 
              v-for="tag in releasesAsSelectValues" 
              :value="tag.version" 
              :key="tag.version" 
              :selected='$route.meta.version === tag.version'
            >
              {{tag.text}}
            </option>
          </select>
        </form>

        <div v-if="getSelectedInstallVersion">
          <p>You are viewing installation instructions for <strong>{{getSelectedInstallVersion}}</strong>.</p>
        </div>

      </div>
    </header>

    <div v-if="this.getInstallMethods" class="install-methods-wrapper">
      <ul class="install-methods flex flex-wrap justify-center">
        <li v-for="(item, index) in getInstallMethods" :key="index" class="install-methods__item w-full sm:w-1/2 lg:w-1/4 xl:w-1/5 px-4">
          <router-link :to='`/${getSiteData.themeConfig.docsDir}/${getSelectedInstallVersion}/installation/${item.slug}/`'>
            <img :src="item.logo" class="install-methods__item-logo object-contain w-full">
            <h3 class="install-methods__item-title">{{item.label}}</h3>
          </router-link>
        </li>
      </ul>
    </div>

    <div v-else class="install-methods-wrapper">
      <p><strong>No install methods defined!</strong></p>
    </div>
    
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'

export default {
  name: 'Install',
  methods: {

    ...mapMutations([
      'updateSelectedDocVersion'
    ]),

    updateInstallPath(ev) {
      // update the version accordingly in the UI when the
      // user switches to a different version

      // set the updated install version in the store
      this.$store.commit('updateSelectedInstallVersion', ev)

      // change the URL to reflect the version change
      this.$router.push({
        path: `/install/${ev}`,
        meta: {
          version: ev
        }
      })
    },

    mapVersionMetaToInstallVersion() {
      const metaValue = this.$route.meta.version
      if ( metaValue ) {
        this.$store.commit('updateSelectedInstallVersion', metaValue)
      }
    },

    redirectToLatestVersion() {
      if ( !this.$route.meta.version || this.$route.path === '/install/' ) {
        // redirect to the latest release route
        this.$router.push({
          path: `/install/${this.getLatestRelease}/`,
          meta: {
            version: this.getLatestRelease
          }
        })
      }
    }

  },
  computed: {
    ...mapGetters([
      'getInstallMethods',
      'getReleaseList',
      'getLatestRelease',
      'getSelectedInstallVersion',
      'releasesAsSelectValues'
    ])
  },
  watch: {
    // this ensures that the user is always on the latest version
    // in case they are on the Install page and happen to navigate
    // to it again via the main nav (which sends them to the bare
    // path without a version appended)
    $route (to, from) {
      this.redirectToLatestVersion()
      this.mapVersionMetaToInstallVersion()
    }
  },
  beforeMount() {
    this.redirectToLatestVersion()
    this.mapVersionMetaToInstallVersion()
  }
};
</script>

<style lang="scss" scoped>
.page-header {
  text-align: center;
}
</style>
