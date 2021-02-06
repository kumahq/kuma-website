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
              <Card>
                <template slot="card-title">
                  <h3>Ready to get started?</h3>
                </template>
                <div class="mb-4">
                  <p>Receive a step-by-step onboarding guide delivered directly to your inbox</p>
                </div>
                <div class="newsletter-form">
                  <NewsletterForm
                    formSubmitText="Register Now"
                    :stacked="true"
                  >
                    <template v-slot:success>
                      <p class="custom-block-title">Thank you!</p>
                      <p>Please check your inbox for more info on our {{ getSiteData.title }} onboarding guide.</p>
                    </template>
                  </NewsletterForm>
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
import NewsletterForm from '@theme/global-components/NewsletterForm'

export default {
  name: 'BlogIndex',
  components: {
    PostDate,
    PostSummary,
    Pagination,
    Card,
    NewsletterForm
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