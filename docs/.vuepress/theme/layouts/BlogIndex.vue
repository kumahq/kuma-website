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
            <ul>
              <li v-for="(page, index) in $pagination.pages">
                <router-link
                  class="pagination__link"
                  :class="`pagination__link--${index}`"
                  :to="page.path"
                >
                  {{ page.title }}
                </router-link>
              </li>
            </ul>
          </slot>

          <div class="pagination-wrapper">
            <Pagination/>
            <!-- <router-link v-if="$pagination.hasPrev" :to="$pagination.prevLink">Prev</router-link>
            <router-link v-if="$pagination.hasNext" :to="$pagination.nextLink">Next</router-link> -->
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
import { Pagination } from '@vuepress/plugin-blog/lib/client/components'

export default {
  name: 'BlogIndex',
  components: {
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