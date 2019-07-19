<template>
  <div class="version-nav">
    <DropdownLink :item="{
      text: 'Versions',
      items: tags,
      type: 'links'
    }"/>
  </div>
</template>

<script>
import Axios from 'axios'
import DropdownLink from '@theme/components/DropdownLink'
import NavLink from '@theme/components/NavLink'

export default {
  name: 'VersionNav',
  data() {
    return {
      tags: Array
    }
  },
  components: {
    DropdownLink,
    NavLink
  },
  mounted() {
    Axios
      .get('/releases.json')
      .then( response => {
        // setup the version array
        this.tags = response.data.map( tag => ({
          text: tag,
          type: 'link',
          link: `/${this.getSiteData.themeConfig.docsDir}/${tag}/`,
        }))
      })
  }
}
</script>
