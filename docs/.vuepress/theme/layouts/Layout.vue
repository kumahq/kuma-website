<template>
  <div
    class="theme-container"
    :class="pageClasses"
    @touchstart="onTouchStart"
    @touchend="onTouchEnd"
  >
    <Navbar
      v-if="shouldShowNavbar"
      @toggle-sidebar="toggleSidebar"
    />

    <div class="content-wrapper">

      <!-- <div
        class="sidebar-mask"
        @click="toggleSidebar(false)"
      ></div> -->

      <Sidebar
        :items="sidebarItems"
        @toggle-sidebar="toggleSidebar"
      >
        <slot
          name="sidebar-top"
          slot="top"
        />
        <slot
          name="sidebar-bottom"
          slot="bottom"
        />
      </Sidebar>

      <component
        :is="layoutComponentSelector"
        :sidebar-items="sidebarItems"
      />

    </div>
    <!-- .content-wrapper -->

    <Footer />

  </div>
</template>

<script>
import axios from 'axios'
import Navbar from '@theme/components/Navbar.vue'
import Page from '@theme/components/Page.vue'
import Sidebar from '@theme/components/Sidebar.vue'
import { resolveSidebarItems, redirectToLatestVersion } from '../util'

// specific page templates
import Home from '@theme/components/custom/Home.vue'
import Install from '@theme/components/custom/Install.vue'
import Community from '@theme/components/custom/Community.vue'
import RequestADemo from '@theme/components/custom/RequestADemo.vue'
import UseCases from '@theme/components/custom/UseCases.vue'

export default {
  components: {
    Page,
    Sidebar,
    Navbar,
    Home,
    Install,
    Community,
    RequestADemo,
    UseCases
  },

  data () {
    return {
      isSidebarOpen: false
    }
  },

  computed: {
    layoutComponentSelector() {

      // this function determines which page component
      // to load. if a markdown file has the `layout`
      // attribute defined in its frontmatter, this
      // function will load that template accordingly.
      // otherwise, it will load the homepage, or
      // fallback to the default `Page` component.

      const fm = this.$page.frontmatter
      let layoutComponent

      if( fm.home ) {
        layoutComponent = 'Home'
      } else if( fm.layout ) {
        layoutComponent = fm.layout
      } else {
        layoutComponent = 'Page'
      }

      return layoutComponent
    },

    shouldShowNavbar () {
      const { themeConfig } = this.$site
      const { frontmatter } = this.$page
      if (
        frontmatter.navbar === false
        || themeConfig.navbar === false) {
        return false
      }
      return (
        this.$title
        || themeConfig.logo
        || themeConfig.repo
        || themeConfig.nav
        || this.$themeLocaleConfig.nav
      )
    },

    shouldShowSidebar () {
      const { frontmatter } = this.$page
      return (
        !frontmatter.home
        && frontmatter.sidebar !== false
        && this.sidebarItems.length
      )
    },

    sidebarItems () {
      return resolveSidebarItems(
        this.$page,
        this.$page.regularPath,
        this.$site,
        this.$localePath
      )
    },

    pageClasses () {
      const userPageClass = this.$page.frontmatter.pageClass
      return [
        {
          'no-navbar': !this.shouldShowNavbar,
          'sidebar-open': this.isSidebarOpen,
          'no-sidebar': !this.shouldShowSidebar
        },
        userPageClass
      ]
    }
  },

  beforeMount() {
    this.$router.beforeEach((to, from, next) => {
      const path = to.path
      // only preload the documentation page assets
      if (path.startsWith('/docs/')) {
        this.preloadPubAssets()
      }
      // regardless of what happens, always trigger next()
      next()
    })
  },

  mounted () {
    this.$router.afterEach(() => {
      this.isSidebarOpen = false
    })
  },

  methods: {
    toggleSidebar (to) {
      this.isSidebarOpen = typeof to === 'boolean' ? to : !this.isSidebarOpen
    },

    // side swipe
    onTouchStart (e) {
      this.touchStart = {
        x: e.changedTouches[0].clientX,
        y: e.changedTouches[0].clientY
      }
    },

    onTouchEnd (e) {
      const dx = e.changedTouches[0].clientX - this.touchStart.x
      const dy = e.changedTouches[0].clientY - this.touchStart.y
      if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 40) {
        if (dx > 0 && this.touchStart.x <= 80) {
          this.toggleSidebar(true)
        } else {
          this.toggleSidebar(false)
        }
      }
    },

    /**
     * Documentation public asset preloader
     * 
     * This is a bit of a hacky workaround to force the
     * public asset folder to preload images. Because
     * the images used in the documentation pages are
     * not fed through the webpack pipeline, they load
     * staticly and thus slower than the webpack chunks.
     * 
     * This forces them to preload into the browser so
     * that the hash anchor links in the documentation
     * page sidebar don't go to the incorrect location
     * due to public assets loading slightly slower
     * (e.g. after the user is already at the anchor
     * section they navigated to).
     * 
     */
    preloadPubAssets () {
      axios({
        method: 'get',
        url: '/images/docs/manifest.json',
        headers: {
          'Accept': 'application/json'
        },
      })
      .then(res => {
        const items = res.data.children
        items.forEach((item, i) => {
          item.children.forEach((item, i) => {
            const imgPath = item.path.replace('docs/.vuepress/public', '')
            let image = new Image()
            image.src = imgPath
            image.onload = console.log('loaded')
          })
        })
      })
      .catch(err => {
        // let the app know if an error has occurred
        this.error = true
      })
    }
  }
}
</script>

// this is required for automatic code highlighting
<style src="prismjs/themes/prism-tomorrow.css"></style>