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
import { resolveNavLinkItem } from '../../util';
import NavLink from '../../components/NavLink'

export default {
  data() {
    return {
      tags: [],
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
          releases.tags.forEach( tag => {
            this.tags.push({
              text: (tag.label === 'master') ? `Latest (${tag.version})` : tag.version,
              type: 'link',
              link: `${window.location.origin}/${(tag.label === 'master') ? tag.label : tag.version}/`
            })
          })
        })
      })
    }
  }
}
</script>
