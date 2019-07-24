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
import releases from '../../../public/releases.json'
import DropdownLink from '@theme/components/DropdownLink'

export default {
  name: 'VersionNav',
  data() {
    return {
      tags: Array
    }
  },
  components: {
    DropdownLink
  },
  methods: {
    fetchReleases() {
      this.tags = releases.map( tag => ({
        text: tag,
        type: 'link',
        link: `/${this.getSiteData.themeConfig.docsDir}/${tag}/`,
      }))
    }
  },
  mounted() {
    this.fetchReleases()
  }
}
</script>
