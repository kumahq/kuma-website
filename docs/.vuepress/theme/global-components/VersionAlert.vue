<template>
  <div>
    <div v-if="showAlert" class="version-alert">
      <div class="warning custom-block">
        <p class="custom-block-title">Careful!</p>
        <p>You are browsing documentation for an outdated version of {{getSiteData.title}}.</p>
        <p><router-link :to="{ path: `/docs/${getLatestRelease}/` }">Go here</router-link> 
        to browse the documentation for the latest version.</p>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'VersionAlert',
  data () {
    return {
      showAlert: false
    }
  },
  computed: {
    ...mapGetters([
      'getLatestRelease'
    ])
  },
  methods: {
    // this will check if the user is viewing an older version
    // of the documentation, and alert them accordingly
    checkIfOldVersion() {
      const routePath = this.$route.path
      const isDocs = 
        routePath.startsWith('/docs/') || 
        routePath.startsWith('/documentation/')
      
      // first, check that we are on a docs page
      if (isDocs) {
        // 1. extract the version from the docs route path
        // so that we can compare it
        const versionOnPage = routePath.split('/')[2]
        
        // 2. compare the current page version to the latest
        // and show or hide the alert based on the result
        if (versionOnPage !== this.getLatestRelease) {
          this.showAlert = true
        }
        else {
          this.showAlert = false
        }
      }
      // this is just a failsafe
      else {
        this.showAlert = false
      }
    }
  },
  mounted() {
    this.checkIfOldVersion()
  },
  watch: {
    $route (to, from) {
      this.checkIfOldVersion()
    },
  }
}
</script>