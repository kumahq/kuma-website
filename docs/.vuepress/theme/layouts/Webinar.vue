<template>
  <Shell
    class="blog-page blog-page--webinars"
  >
    <template slot="page-content">
      <main class="page">
        <div class="theme-default-content content__default">
          <Content/>
        </div>
      </main>
    </template>
  </Shell>
</template>

<script>
import Shell from '@theme/global-components/Shell.vue'

export default {
  components: {
    Shell
  }
}
</script>

<style>

</style>