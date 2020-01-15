<template>
  <div
    class="theme-container"
    @touchstart="$emit('touchStart')"
    @touchend="$emit('touchEnd')"
  >
    <Navbar
      v-if="showNavbar"
      @toggle-sidebar="$emit('toggleSidebar')"
    />
    <div class="content-wrapper">
      <slot name="page-content"></slot>
    </div>
    <!-- .content-wrapper -->
    <Footer />
  </div>
</template>

<script>
import Navbar from '@theme/components/Navbar.vue'

export default {
  props: {
    showNavbar: {
      type: Boolean,
      default: true
    }
  },
  components: {
    Navbar
  }
}
</script>

<style>

</style>