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
import LatestSemver from 'latest-semver'
import DropdownLink from '@theme/components/DropdownLink'

export default {
  name: 'VersionNav',
  data() {
    return {
      tags: Array,
      latestRelease: LatestSemver(releases)
    }
  },
  components: {
    DropdownLink
  },
  methods: {
    fetchReleases() {
      // map the release list to fields that we can use in the
      // DropdownLink component accordingly
      this.tags = releases.map( tag => ({
        text: tag === this.latestRelease ? `${tag} (latest)` : tag,
        type: 'link',
        link: `/${this.getSiteData.themeConfig.docsDir}/${tag}/`,
      }))
    }
  },
  beforeMount() {
    this.fetchReleases()
  }
}
</script>
