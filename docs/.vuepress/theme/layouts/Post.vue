<template>
  <Shell
    class="blog-page blog-page--posts"
  >
    <template slot="page-content">
      <div
        :class="{ 'has-image': $page.frontmatter.headerImage }"
        class="page-container"
      >
        <header class="page-header text-center bg-gradient">
          <div class="blog-nav inner">
            <router-link :to="{ path: '/blog/' }">
              &larr; Back to Blog
            </router-link>
          </div>
          <div class="inner blog-page__main-title-wrapper">
            <h1 v-if="$page.frontmatter.title">
              {{ $page.frontmatter.title }}
            </h1>
            <h1 v-else>
              {{ $page.title }}
            </h1>
            <div class="blog-post__info">
              <span class="date">
                <PostDate :date="$page.frontmatter.date" />
              </span>
              <span class="separator">/</span>
              <span class="reading-time">
                {{ $page.readingTime.text }}
              </span>
            </div>
          </div>
          <!-- .inner -->
        </header>
        <!-- .page-header -->
        
        <div class="inner lg:flex lg:space-x-8 lg:items-start">
          <div class="blog-detail__content lg:w-2/3">
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
          <div class="blog-sidebar lg:w-1/3">
            <Card>
              <template slot="card-title">
                <h3>Get Community Updates</h3>
              </template>
              <div class="mb-4">
                <p>Sign up for our Kuma community newsletter to get the most recent updates and product announcements.</p>
              </div>
              <div class="newsletter-form">
                <NewsletterForm
                  formSubmitText="Join Newsletter"
                  :stacked="true"
                >
                  <template v-slot:success>
                    <p class="custom-block-title">Thank you!</p>
                    <p>You're now signed up for the {{ getSiteData.title }} newsletter.</p>
                  </template>
                </NewsletterForm>
              </div>
            </Card>
          </div>
        </div>
      </div>
      <!-- .page-container -->
    </template>
  </Shell>
</template>

<script>
import Shell from '@theme/global-components/Shell.vue'
import PostDate from '../global-components/PostDate'
import Card from '@theme/components/custom/Card'
import NewsletterForm from '@theme/global-components/NewsletterForm'

export default {
  components: {
    Shell,
    PostDate,
    Card,
    NewsletterForm
  }
}
</script>

<style>

</style>