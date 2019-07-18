<template>
  <!-- 
    Nothing to see here. This template exists to simply pass the user along.
    This layout gets called in your corresponding page's `layout` frontmatter
    attribute.
  -->
</template>

<script>
import Axios from 'axios'

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
        const releases = response.data.tags
        for ( let i = 0; i < releases.length; i++ ) {
          if ( releases[i].latest === true ) {
            this.version = releases[i].version
          }
        }
      })
      .then(() => {
        // as long as the version is set via the previous promise,
        // let's redirect to it.
        if ( this.version && this.version.length ) {
          this.$router.push(`${this.$page.path}${this.version}/`)
        }
      })
      .catch( err => {
        console.log(err)
      })
  }
}
</script>