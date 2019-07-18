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
        this.tags = response.data.tags.map( tag => ({
          text: (tag.latest === true) ? `Latest (${tag.version})` : tag.version,
          type: 'link',
          link: `/${this.getSiteData.themeConfig.docsDir}/${tag.version}/`,
          latest: (tag.latest === true) ? true : false
        }))
      })
  }
}
</script>
