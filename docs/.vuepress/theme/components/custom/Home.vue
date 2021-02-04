<template>
  <div
    class="page-container page-container--home"
    aria-labelledby="masthead-main-title"
  >
    <div class="page-masthead-wrap">
      <div class="inner flex flex-wrap -mx-4">
        <div class="page-masthead w-full lg:w-1/2 px-4">
          
          <div class="page-masthead__upper">
            <header class="page-masthead__header">
              <Content slot-key="masthead-main-title" />
              <Content slot-key="masthead-sub-title" />
            </header>
            <!-- .page-masthead__header -->
            <div class="page-masthead__actions">
              <router-link
                v-if="$page.frontmatter.startText"
                :to="$page.frontmatter.startUrl"
                class="btn btn--bright btn--large"
              >
                {{ $page.frontmatter.startText }}
              </router-link>
              <a
                v-if="$page.frontmatter.whyUrl"
                :href="$page.frontmatter.whyUrl"
                class="btn btn--hollow btn--large"
              >
                {{ $page.frontmatter.whyText }}
              </a>
            </div>
          </div>
          <!-- /.page-masthead__upper -->
          
          <div class="page-masthead__diagram max-w-2xl mx-auto mt-4 w-full lg:w-1/2 block lg:hidden px-4">
            <Content slot-key="masthead-diagram" />
          </div>
          <!-- masthead diagram: mobile -->
          
          <!-- .page-masthead__actions -->
          <div v-if="$page.frontmatter.showNews" class="newsbar-wrap newsbar-wrap--left-text flex">
            <div class="newsbar-wrap__title mr-4">
              <h3>News</h3>
            </div>
            <div class="flex-1">
              <Content slot-key="news" class="newsbar" />
            </div>
          </div>
          <!-- masthead diagram: desktop -->
        </div>
        <!-- .page-masthead -->

        <div class="page-masthead__diagram w-full lg:w-1/2 hidden lg:block px-4">
          <Content slot-key="masthead-diagram" />
        </div>
      </div>
      <!-- .inner -->

      <div id="page-masthead-waves-wrap">
        <MastheadWaves id="page-masthead-waves" />
      </div>
    </div>
    <!-- .page-masthead-wrap -->
    
    <div v-if="$page.frontmatter.showTestimonial && testimonials.length" class="testimonials-carousel-wrap">
      <div class="inner">
        <ClientOnly>
          <carousel
            :loop="$page.frontmatter.testimonialCarouselLoop || false"
            :perPage="1"
            :autoplay="$page.frontmatter.testimonialCarouselAutoplay || false"
            :autoplayTimeout="$page.frontmatter.testimonialCarouselTiming || 3000"
            :autoPlayHoverPause="true"
            :navigationEnabled="true"
            navigationNextLabel="→"
            navigationPrevLabel="←"
          >
            <slide v-for="item in testimonials" class="testimonial">
              <blockquote class="lg:grid lg:grid-flow-col lg:gap-4 lg:col-gap-4 lg:row-gap-2 px-8 lg:px-0">
                <div class="testimonial__image lg:row-span-1 lg:row-start-1 mx-auto text-center">
                  <img
                    :src="item.image"
                    :alt="item.alt"
                  />
                </div>
                <div class="testimonial__content lg:col-span-2">
                  <div>
                    <p>{{ item.content }}</p>
                  </div>
                  <cite class="testimonial__author lg:row-span-1 lg:col-span-2 mt-4 lg:mt-0">
                    {{ item.author }}, {{ item.title }}
                  </cite>
                </div>
              </blockquote>
            </slide>
          </carousel>
        </ClientOnly>
      </div>
      <!-- /.inner -->
    </div>
    <!-- /.testimonials-carousel-wrap -->

    <div class="product-features-wrap">
      <!-- <div v-if="$page.frontmatter.showNews" class="newsbar-wrap">
        <Content slot-key="news" class="newsbar" />
      </div> -->

      <div class="inner product-features flex flex-wrap -mx-4">
        <Content
          v-for="i in 3"
          :slot-key="`feature-block-content-${i}`"
          :class="`product-features__item--${i}`"
          class="product-features__item w-full md:w-1/3 px-4"
        />
      </div>
      <!-- .inner -->
    </div>
    <!-- .features-wrap -->

    <div class="feature-focus-wrap">
      <div class="feature-focus feature-focus__tabs" v-if="tabs">
        <div class="inner inner--bordered flex flex-wrap -mx-12">
          <div class="w-full lg:w-1/2 px-12">
            <ClientOnly>
              <KTabs :tabs="tabs">
                <template v-for="tab in tabs" :slot="tab.hash.replace('#','')">
                  <Content :slot-key="`tab-${tab.hash.replace('#','')}`" />
                </template>
              </KTabs>
            </ClientOnly>
          </div>
          <div class="feature-focus__content w-full lg:w-1/2 px-12">
            <Content slot-key="tabs-right-col-content" />
          </div>
        </div>
      </div>
      <div
        v-for="i in 2"
        class="feature-focus"
        :class="`feature-focus-${i}-wrap`"
      >
        <div
          :class="{ 'md:flex-row-reverse': i % 2 !== 0 }"
          class="inner inner--bordered flex flex-wrap -mx-12"
        >
          <Content
            :slot-key="`feature-focus-${i}-diagram`"
            class="feature-focus__diagram w-full md:self-center md:w-1/2 px-12"
          />
          <Content
            :slot-key="`feature-focus-${i}-content`"
            class="feature-focus__content w-full md:self-center md:w-1/2 px-12"
          />
        </div>
      </div>
    </div>
    <!-- .feature-focus-wrap -->

    <div class="newsletter-form-wrap">
      <div class="inner newsletter-form">
        <header class="section-header">
          <Content slot-key="newsletter-title" class="alt-title" />
        </header>
        <Content slot-key="newsletter-content" />
        <NewsletterForm />
      </div>
      <NewsletterWaves />
    </div>
    <!-- newsletter-form-wrap -->
  </div>
</template>

<script>
import Navbar from '@theme/components/Navbar'
import MastheadWaves from '@theme/components/custom/PageMastheadWaves'
import NewsletterWaves from '@theme/components/custom/NewsletterWaves'
import KTabs from '../../../../../node_modules/@kongponents/ktabs/KTabs'

export default {
  components: {
    Navbar,
    MastheadWaves,
    NewsletterWaves,
    KTabs
  },
  computed: {
    tabs () {
      return this.$page.frontmatter.tabs || null
    },
    testimonials () {
      return this.$page.frontmatter.testimonials || null
    },
  },
}
</script>