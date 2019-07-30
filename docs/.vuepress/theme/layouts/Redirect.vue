<template></template>

<script>
/**
 * Redirect.vue
 * 
 * This is a functional component that simply passes the user
 * to the latest version whenever they arrive at /docs/
 * 
 * Example:
 * - User navigates to /docs/
 * - This component checks to see what the latest version is
 * - The component then redirects them to /docs/1.2.3/
 *    (or whatever the latest version happens to be)
 */

import releases from '../../public/releases.json'
import LatestSemver from 'latest-semver'

export default {
  data() {
    return {
      version: ''
    }
  },
  created() {
    this.fetchReleases()
  },
  methods: {
    fetchReleases() {
      // let's fetch the releases data so we can grab
      // the latest version in order to build the redirect
      const latestVersion = LatestSemver(releases)
      this.version = latestVersion
      this.$router.push({
        path: `${this.$page.path}${latestVersion}/`
      })
    }
  }
}
</script>