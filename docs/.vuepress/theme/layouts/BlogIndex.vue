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
          
          <div class="lg:flex lg:space-x-8 lg:items-start">
            <div class="blog-content-area lg:w-2/3">
              <slot name="pagination-content">
                <div class="blog-index-list">
                  <article v-for="(page, index) in $pagination.pages" class="blog-article">
                    <div
                      :class="{ 'has-image': page.frontmatter.headerImage }"
                      class="blog-article__content-wrapper"
                    >
                      <div
                        v-if="page.frontmatter.headerImage"
                        class="blog-post__header-image"
                        :style="`background-image: url('${page.frontmatter.headerImage}');`"
                      >
                        <img
                          :src="page.frontmatter.headerImage"
                          :alt="`Featured image for a blog article titled ${page.title}.`"
                          class="sr-only"
                        >
                      </div>
                      <div class="blog-article__post-inner">
                        <header class="blog-index__post-header">
                          <div class="blog-index__post-header__content">
                            <div class="blog-post__info">
                              <span class="date">
                                <PostDate :date="page.frontmatter.date" />
                              </span>
                              <span class="separator">/</span>
                              <span class="reading-time">
                                {{ page.readingTime.text }}
                              </span>
                            </div>
                            <h2 class="blog-index__post-title">
                              <router-link :to="page.path">
                                {{ page.title }}
                              </router-link>
                            </h2>
                          </div>
                        </header>
                        <div
                          v-if="page.frontmatter.description"
                          class="blog-index__post-summary"
                        >
                          <PostSummary
                            :content="page.frontmatter.description"
                            :max-words="maxWords"
                          />
                        </div>
                        <footer class="blog-index__post-footer">
                          <router-link :to="page.path">
                            Continue Reading &rarr;
                          </router-link>
                        </footer>
                      </div>
                    </div>
                  </article>
                </div>
              </slot>
            </div>
            <div class="blog-sidebar lg:w-1/3">
              <Card
                icon="/images/icons/icon-community-call.svg"
                iconAlt="Community call icon"
                :iconWidth="48"
                :iconHeight="48"
              >
                <template slot="card-title">
                  <h3>Community Call</h3>
                </template>
                <div class="mb-4">
                  <p>Kuma hosts official monthly community calls where users and contributors can discuss about any topic and demonstrate use-cases. Interested? You can register below for the next Community Call.</p>
                </div>
                <div class="community-form">
                  <CommunityCallForm :stacked="true" />
                </div>
              </Card>
            </div>
          </div>

          <div 
            v-if="$pagination.hasPrev || $pagination.hasNext"
            class="pagination-wrapper"
          >
            <Pagination />
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
import PostDate from '../global-components/PostDate'
import PostSummary from '../global-components/PostSummary'
import { Pagination } from '@vuepress/plugin-blog/lib/client/components'
import Card from '@theme/components/custom/Card'
import CommunityCallForm from '@theme/global-components/CommunityCallForm'

export default {
  name: 'BlogIndex',
  components: {
    PostDate,
    PostSummary,
    Pagination,
    Card,
    CommunityCallForm
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
    },
    maxWords: {
      type: Number,
      required: false,
      default: 20
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