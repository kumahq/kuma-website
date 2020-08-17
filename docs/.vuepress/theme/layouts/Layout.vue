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

// reusable page template
import Shell from '@theme/components/custom/Shell.vue'

// specific page templates
import Home from '@theme/components/custom/Home.vue'
import Install from '@theme/components/custom/Install.vue'
import Community from '@theme/components/custom/Community.vue'
import Enterprise from '@theme/components/custom/Enterprise.vue'
import UseCases from '@theme/components/custom/UseCases.vue'
import Policies from '@theme/components/custom/Policies.vue'

export default {
  components: {
    Page,
    Sidebar,
    Navbar,
    Shell,
    Home,
    Install,
    Community,
    Enterprise,
    UseCases,
    Policies
  },

  data () {
    return {
      isSidebarOpen: false
    }
  },

  computed: {
    layoutComponentSelector() {

      /**
       * this function determines which page component
       * to load based on various parameters:
       * 
       * 1. is `home` set to true in the frontmatter?
       * 2. is a custom layout defined in the frontmatter?
       * 3. does the route have `layout` meta defined?
       * 4. if none of the above apply, fallback to the Page component
       * 
       */

      const fm = this.$page.frontmatter
      let layoutComponent

      /**
       * default to home if `home` is 
       * set to true in the frontmatter
       */
      if( fm.home ) {
        layoutComponent = 'Home'
      /**
       * or look for the layout defined in
       * the frontmatter
       */
      } else if( fm.layout ) {
        layoutComponent = fm.layout
      /**
       * otherwise fallback to the Page component
       */
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
    }
  }
}
</script>