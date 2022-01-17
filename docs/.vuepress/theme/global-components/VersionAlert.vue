<template>
  <div>
    <div v-if="showAlert" class="version-alert">
      <div class="warning custom-block">
        <p class="custom-block-title">Careful!</p>
        <p v-if="isDev">You are browsing documentation for the next version of {{getSiteData.title}}. Use this version at your own risks.</p>
        <p v-else>You are browsing documentation for a version of {{getSiteData.title}} that is not the latest release.</p>
        <p>
          <router-link :to="{ path: `/docs/${getLatestRelease}/` }">Go here</router-link> to browse the documentation for the latest version.
        </p>
        <p v-if="!isDev">Looking for even older versions? <router-link :to="{ path: `/blog/2021/_2021-website-reorg/` }">Learn more</router-link>.</p>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  name: "VersionAlert",
  data() {
    return {
      showAlert: false,
      isDev: false
    };
  },
  computed: {
    ...mapGetters(["getLatestRelease"])
  },
  methods: {
    // this will check if the user is viewing an older version
    // of the documentation, and alert them accordingly
    checkIfOldVersion() {
      const routePath = this.$route.path;
      const isDocs =
        routePath.startsWith("/docs/") ||
        routePath.startsWith("/documentation/");

      // first, check that we are on a docs page
      if (isDocs) {
        // 1. extract the version from the docs route path
        // so that we can compare it
        const versionOnPage = routePath.split("/")[2];
        this.isDev = versionOnPage === "dev";

        // 2. compare the current page version to the latest
        // and show or hide the alert based on the result
        this.showAlert = versionOnPage !== this.getLatestRelease;
      }
      // this is just a failsafe
      else {
        this.showAlert = false;
      }
    }
  },
  mounted() {
    this.checkIfOldVersion();
  },
  watch: {
    $route(to, from) {
      this.checkIfOldVersion();
    }
  }
};
</script>
