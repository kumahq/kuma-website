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
import ky from 'ky'
import DropdownLink from '../../components/DropdownLink'
import NavLink from '../../components/NavLink'

export default {
  name: 'VersionNav',
  data() {
    return {
      tags: Array,
      location:
        typeof window !== 'undefined' && window !== null
          ? window.location.origin
          : ''
    }
  },
  components: {
    DropdownLink,
    NavLink
  },
  mounted() {
    if (typeof window !== 'undefined' && window !== null) {
      ky.get(`${window.location.origin}/releases.json`).then( res => {
        res.json().then( releases => {
          // setup the version array
          releases.tags.forEach( tag => {
            this.tags.push({
              text: (tag.latest === true) ? `Latest (${tag.version})` : tag.version,
              type: 'link',
              link: `${window.location.origin}/${(tag.latest === true) ? tag.label : tag.version}/`,
              latest: (tag.latest === true) ? true : false
            })
          })
        })
      })
    }
  }
}
</script>
