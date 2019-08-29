<template>
  <div class="page-container page-container--install">

    <header class="page-header text-center bg-gradient">
      
      <div class="inner">
        <h1>Install {{$site.title}}</h1>
      
        <div v-if="getInstallMethods && getInstallMethods.length" class="version-selector-wrapper">

          <select
            name="version-selector"
            class="version-selector version-selector--large"
            id="version-selector"
            v-model="defaultSelectedInstallVersion">
            <option 
              v-for="tag in releasesAsSelectValues" 
              :value="tag.version" 
              :key="tag.version" 
              :selected='$route.meta.version === tag.version'
            >
              {{tag.text}}
            </option>
          </select>
          <!-- .version-selector -->

          <div v-if="getSelectedInstallVersion" class="version-selector__version-notifier">
            <p class="page-sub-title">You are viewing installation instructions for <strong>{{getSelectedInstallVersion}}</strong>.</p>
          </div>
          <!-- .version-selector__version-notifier -->

          <div v-if="getSelectedInstallVersion !== getLatestRelease" class="version-alert">
            <div class="warning custom-block">
              <p class="custom-block-title">Careful!</p>
              <p>You are viewing installation instructions for an outdated version of {{getSiteData.title}}.</p>
              <p><router-link :to="{ path: `/install/${getLatestRelease}/` }">Go here</router-link> 
              to view installation instructions for the latest version.</p>
            </div>
          </div>
          <!-- .version-alert -->

        </div>
        <!-- .version-selector-wrapper -->
        
      </div>
      <!-- .inner -->

    </header>

    <div class="inner">

      <div v-if="getInstallMethods" class="install-methods-wrapper">
        <ul class="install-methods flex flex-wrap justify-center -mx-4">
          <li v-for="(item, index) in getInstallMethods" :key="index" class="install-methods__item w-full sm:w-1/2 lg:w-1/3 px-4 mb-8">
            <router-link
              :to='`/${getSiteData.themeConfig.docsDir}/${getSelectedInstallVersion}/installation/${item.slug}/`'
              class="install-methods__item-link flex flex-wrap justify-center items-center"
            >
              <div class="install-methods__item-logo w-full sm:w-1/4 px-3">
                <img :src="item.logo" class="object-contain w-full">
              </div>
              <div class="install-methods__item-title w-full sm:w-3/4 px-3">
                <h3>{{item.label}}</h3>
              </div>
            </router-link>
          </li>
        </ul>
      </div>
      <!-- .install-methods-wrapper -->

    </div>
    <!-- .inner -->
    
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
      'getLatestRelease',
      'getSelectedInstallVersion',
      'releasesAsSelectValues'
    ]),

    // this is used as the model for the version selector
    defaultSelectedInstallVersion: {
      get() {
        return this.getSelectedInstallVersion
      },
      set(value) {
        this.updateInstallPath(value)
      }
    }
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