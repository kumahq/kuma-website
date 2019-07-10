<template>
  <div class="version-nav-wrapper">
    <div v-if="this.versionPages && this.versionPages.length" class="version-nav">
      <ul v-for="item in this.versionPages">
        <!-- <router-link tag="li" :to="/">
          <a>
            {{item.title}}
          </a>
        </router-link> -->
        {{item}}
      </ul>
    </div>
    <div v-else>
      <p>no items</p>
    </div>

    <DropdownLink :item="{
      text: 'Versions',
      items: versionPages,
      type: 'links'
    }"/>

    <!-- <code><pre>{{this.$site.pages}}</pre></code> -->

  </div>
</template>

<script>
import NavLink from '../../default-theme/components/NavLink'
import DropdownLink from '../../default-theme/components/DropdownLink'
import { resolveNavLinkItem } from '../../default-theme/util';

export default {
  components: {
    DropdownLink,
    NavLink
  },
  computed: {
    versionPages() {
      const regex = new RegExp(/[V-v]+\d+(\.\d{1,2})+(\.\d{1,2})?\/?[^\/]*\/?[^\/]*\/?[^\/]*.[html]*$/, 'igm')
      // const pages = this.$site.pages.filter(path => regex.test(path))
      const pages = [
        '/v1.1.1/testing.html',
        '/v1.2.3/things/thing.html',
        '/v1.0.100/',
        '/thing/thing.html'
      ]
      return pages
      // return pages.filter(item => regex.test(item))
    }
  }
}
</script>
