<template>
  <div class="page-container page-container--home" aria-labelledby="masthead-main-title">
    <div class="page-masthead-wrap">
      <div class="inner flex flex-wrap -mx-4">
        <div class="page-masthead w-full lg:w-1/2 px-4">
          <header class="page-masthead__header">
            <Content slot-key="masthead-main-title" />
            <Content slot-key="masthead-sub-title" />
          </header>
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
        <!-- .page-masthead -->

        <!-- <div class="page-masthead__diagram w-full lg:w-1/2 px-4">
          <Content slot-key="masthead-diagram" />
        </div> -->
      </div>
      <!-- .inner -->

      <div id="page-masthead-waves-wrap">
        <MastheadWaves id="page-masthead-waves" />
      </div>
    </div>
    <!-- .page-masthead-wrap -->

    <div class="product-features-wrap">
      <div
        v-if="$page.frontmatter.showNews"
        class="newsbar-wrap"
      >
        <Content
          slot-key="news"
          class="newsbar"
        />
      </div>

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

    <div v-if="$page.frontmatter.showTestimonial" class="testimonial-wrap">
      <div class="inner testimonial">
        <blockquote class="testimonial__content-wrap">
          <Content slot-key="testimonial-content" />
          <div class="testimonial__cite">
            <div v-if="$page.frontmatter.testimonialPortraitSrc" class="testimonial__portrait">
              <img
                :src="$page.frontmatter.testimonialPortraitSrc"
                :alt="$page.frontmatter.testimonialPortraitAlt"
              />
            </div>
            <cite>
              <Content slot-key="testimonial-author" />
              <Content slot-key="testimonial-author-info" />
            </cite>
          </div>
        </blockquote>
      </div>
      <!-- .inner -->
    </div>
    <!-- .testimonial-wrap -->

    <div class="feature-focus-wrap">
      <div
        v-for="i in 3"
        class="feature-focus"
        :class="`feature-focus-${i}-wrap`"
      >
        <div
          :class="{ 'md:flex-row-reverse': (i % 2 === 0) }"
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
import Navbar from "@theme/components/Navbar"
import TinyTabs from "@theme/components/custom/TinyTabs/VueTinyTabs"
import MastheadWaves from "@theme/components/custom/PageMastheadWaves"
import NewsletterWaves from "@theme/components/custom/NewsletterWaves"

export default {
  components: {
    Navbar,
    TinyTabs,
    MastheadWaves,
    NewsletterWaves
  }
};
</script>