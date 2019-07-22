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

import Axios from 'axios'
import LatestSemver from 'latest-semver'

export default {
  data() {
    return {
      version: ''
    }
  },
  beforeCreate() {
    // let's fetch the releases data so we can grab
    // the latest version in order to build the redirect
    Axios
      .get('/releases.json')
      .then( response => {
        this.version = LatestSemver(response.data)
        this.$router.push(`${this.$page.path}${this.version}/`)
        console.log(this.version)
      })
      .catch( err => {
        console.log(err)
      })
  }
}
</script>