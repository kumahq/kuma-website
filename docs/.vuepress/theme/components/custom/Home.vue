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
              to="/install/"
              class="btn btn--bright btn--large"
            >
              Start Now
            </router-link>
            <router-link
              to="/docs/latest/overview/why-kuma/"
              class="btn btn--hollow btn--large"
            >
              Why {{ getSiteData.title }}?
            </router-link>
          </div>
        </div>
        <!-- .page-masthead -->

        <!-- <div class="page-masthead__diagram w-full lg:w-1/2 px-4">
          <Content slot-key="masthead-diagram" />
        </div> -->
      </div>
      <!-- .inner -->

      <!-- TODO work on proper placement -->
      <!-- <MastheadWaves id="page-masthead-waves" /> -->
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
          slot-key="feature-block-content-1"
          class="product-features__item w-full md:w-1/3 px-4"
        />
        <Content
          slot-key="feature-block-content-2"
          class="product-features__item w-full md:w-1/3 px-4"
        />
        <Content
          slot-key="feature-block-content-3"
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
        <div class="inner inner--bordered flex flex-wrap -mx-12">
          <Content
            :slot-key="`feature-focus-${i}-diagram`"
            class="w-full md:w-1/2 px-12"
          />
          <Content
            :slot-key="`feature-focus-${i}-content`"
            class="w-full md:w-1/2 px-12"
          />
        </div>
      </div>
    </div>
    <!-- .feature-focus-wrap -->

  </div>
</template>

<script>
import Navbar from "@theme/components/Navbar";
import TinyTabs from "@theme/components/custom/TinyTabs/VueTinyTabs";
import MastheadWaves from "@theme/components/custom/PageMastheadWaves";

export default {
  components: {
    Navbar,
    TinyTabs,
    MastheadWaves
  }
};
</script>