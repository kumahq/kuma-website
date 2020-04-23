<template>
  <Shell
    class="blog-page blog-page--posts"
  >
    <template slot="page-content">
      <div class="page-container">
        
        <header class="page-header text-center bg-gradient">
          <div class="inner">
            <h1 v-if="$page.frontmatter.title">
              {{ $page.frontmatter.title }}
            </h1>
            <h1 v-else>
              {{ $page.title }}
            </h1>
            <div v-if="$page.frontmatter.date" class="entry-date">
              {{ $page.frontmatter.date }}
            </div>
            <p v-if="$page.frontmatter.description" class="page-sub-title">
              {{ $page.frontmatter.description }}
            </p>
          </div>
          <!-- .inner -->
        </header>
        <!-- .page-header -->

        <div class="inner">
          <Content/>
        </div>
        <!-- .inner -->

      </div>
      <!-- .page-container -->
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