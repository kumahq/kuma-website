<template>
  <!-- 
    Nothing to see here. This template exists to simply pass the user along.
    This layout gets called in your corresponding page's `layout` frontmatter
    attribute. If the user navigates to the bare /docs/ directory, they are
    automatically redirected to the latest documentation.
  -->
</template>

<script>
import Axios from 'axios'
import LatestSemver from 'latest-semver'

export default {
  data() {
    return {
      version: ''
    }
  },
  mounted () {
    // let's fetch the releases data so we can grab
    // the latest version in order to build the redirect
    Axios
      .get('/releases.json')
      .then( response => {
        this.version = LatestSemver(response.data)
        this.$router.push(`${this.$page.path}${this.version}/`)
      })
      .catch( err => {
        console.log(err)
      })
  }
}
</script>