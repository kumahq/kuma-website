<template>
  <div class="page-container page-container--install">
    
    <Content />

    <header class="page-header text-center bg-gradient">
      
      <div class="inner">
        <h1>Install {{ $site.title }}</h1>
      
        <div v-if="getInstallMethods && getInstallMethods.length" class="version-selector-wrapper">

          <select
            name="version-selector"
            class="version-selector"
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
            <p><a href="https://github.com/kumahq/kuma/blob/master/CHANGELOG.md">Changelog</a> • <a href="https://github.com/kumahq/kuma/blob/master/UPGRADE.md">Upgrade Path</a> • <a href="/community">Slack Chat</a></p>
          </div>
          <!-- .version-selector__version-notifier -->

          <div v-if="getSelectedInstallVersion !== getLatestRelease" class="version-alert">
            <div class="warning custom-block">
              <p class="custom-block-title">Careful!</p>
              <p>You are viewing installation instructions for an outdated version of {{getSiteData.title}}.</p>
              <p><router-link :to="{ path: `/install/${getLatestRelease}/` }">Go here</router-link> 
              to view installation instructions for the latest version.</p>
              <p>Looking for even older versions? <router-link :to="{ path: `/blog/2021/_2021-website-reorg/` }">Learn more</router-link>.</p>
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
    
    <div class="newsletter-form-wrap">
      <div class="inner newsletter-form">
        <div class="alt-title content__newsletter-title">
          <h2 id="get-community-updates">Ready to get started?</h2>
        </div>
        <div class="content__newsletter-content">
          <p>Receive a step-by-step onboarding guide delivered directly to your inbox</p>
        </div>
        <NewsletterForm
          formSubmitText="Register Now"
          :simple="true"
        >
          <template v-slot:success>
            <p class="custom-block-title">Thank you!</p>
            <p>Please check your inbox for more info on our {{ getSiteData.title }} onboarding guide.</p>
          </template>
        </NewsletterForm>
      </div>
      <NewsletterWaves />
    </div>
    <!-- newsletter-form-wrap -->
    
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'
import NewsletterWaves from '@theme/components/custom/NewsletterWaves'

export default {
  name: 'Install',
  components: {
    NewsletterWaves
  },
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
      this.$router.replace({
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
        this.$router.replace({
          path: '/install/latest/',
          query: this.$route.query || null,
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

<style lang="scss">
  .content__newsletter-title h2 {
    border: 0;
  }
  
  .theme-container.no-sidebar:not(.is-home):not(.home) .page-footer {
    margin-top: 0;
  }
  
  .newsletter-form-wrap {
    margin-top: 3rem;
  }
</style>