<template>
  <Shell class="blog-page blog-page--pagination">
    <template slot="page-content">
      <div 
        class="page-container"
        :class="`page-container--${pageWrapperClassSlug}`"
      >
        
        <header v-if="pageTitle" class="page-header text-center bg-gradient">
          <div class="inner">
            <h1>{{ pageTitle }}</h1>
            <p v-if="pageSubTitle" class="page-sub-title">
              {{ pageSubTitle }}
            </p>
          </div>
          <!-- .inner -->
        </header>
        <!-- .page-header -->

        <div class="inner">
          
          <slot name="pagination-content">
            <div class="blog-index-list">
              <article v-for="(page, index) in $pagination.pages" class="blog-article">
                <header class="blog-index__post-header">
                  <h2 class="blog-index__post-title">
                    <router-link :to="page.path">
                      {{ page.title }}
                    </router-link>
                  </h2>
                  <PostDate :date="page.frontmatter.date" />
                </header>
                <div
                  v-if="page.frontmatter.description"
                  class="blog-index__post-summary"
                >
                  <PostSummary
                    :content="page.frontmatter.description"
                    :max-words="20"
                  />
                </div>
                <footer class="blog-index__post-footer">
                  <router-link :to="page.path">
                    Continue Reading &rarr;
                  </router-link>
                </footer>
              </article>
            </div>
          </slot>

          <div 
            v-if="$pagination.hasPrev || $pagination.hasNext"
            class="pagination-wrapper"
          >
            <Pagination />
            <router-link v-if="$pagination.hasPrev" :to="$pagination.prevLink">Prev</router-link>
            <router-link v-if="$pagination.hasNext" :to="$pagination.nextLink">Next</router-link>
          </div>
          <!-- .pagination-wrapper -->

        </div>
        <!-- .inner -->
      </div>
      <!-- .page-container -->
          
    </template>
  </Shell>
</template>

<script>
import PostDate from '../global-components/PostDate'
import PostSummary from '../global-components/PostSummary'
import { Pagination } from '@vuepress/plugin-blog/lib/client/components'

export default {
  name: 'BlogIndex',
  components: {
    PostDate,
    PostSummary,
    Pagination
  },
  props: {
    pageSubTitle: {
      type: String,
      required: false
    },
    pageWrapperClassSlug: {
      type: String,
      required: false,
      default: 'blog'
    }
  },
  computed: {
    pageTitle () {
      return this.$page.frontmatter.title
    }
  }
}
</script>

<style>

</style>