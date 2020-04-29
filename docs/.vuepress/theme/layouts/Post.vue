<template>
  <Shell
    class="blog-page blog-page--posts"
  >
    <template slot="page-content">
      <div
        :class="{ 'has-image': $page.frontmatter.headerImage }"
        class="page-container"
      >
        <div class="blog-nav inner">
          <router-link :to="{ path: '/blog/' }">
            &larr; Back to Blog
          </router-link>
        </div>
        <header class="page-header text-center bg-gradient">
          <div class="inner">
            <h1 v-if="$page.frontmatter.title">
              {{ $page.frontmatter.title }}
            </h1>
            <h1 v-else>
              {{ $page.title }}
            </h1>
            <PostDate :date="$page.frontmatter.date" />
          </div>
          <!-- .inner -->
        </header>
        <!-- .page-header -->

        <div class="inner blog-detail__content">
          <div
            v-if="$page.frontmatter.headerImage"
            class="blog-post__header-image"
            :style="`background-image: url('${$page.frontmatter.headerImage}');`"
          >
            <img
              :src="$page.frontmatter.headerImage"
              :alt="`Featured image for a blog article titled ${$page.frontmatter.title || $page.title}.`"
              class="sr-only"
            >
          </div>
          <div class="blog-post__detail-content">
            <Content />
          </div>
        </div>
        <!-- .inner -->

      </div>
      <!-- .page-container -->
    </template>
  </Shell>
</template>

<script>
import Shell from '@theme/global-components/Shell.vue'
import PostDate from '../global-components/PostDate'

export default {
  components: {
    Shell,
    PostDate
  }
}
</script>

<style>

</style>