<template>
  <div class="page-container page-container--home" aria-labelledby="masthead-main-title">
    
    <div class="page-masthead-wrap">

      <div class="inner flex">

        <div class="page-masthead w-full lg:w-1/2">
          <header class="page-masthead__header">
            <Content slot-key="masthead-main-title"/>
            <Content slot-key="masthead-sub-title"/>
          </header>
          <div class="page-masthead__actions flex -mx-2">
            <div class="w-1/2 px-2">
              <router-link to="/install/" class="btn btn--block btn--large-text btn--bright">Install</router-link>
            </div>
            <div class="w-1/2 px-2">
              <router-link to="/docs/" class="btn btn--block btn--large-text btn--hollow">Getting Started</router-link>
            </div>
          </div>
        </div>
        <!-- .page-masthead -->

      </div>
      <!-- .inner -->
    
    </div>
    <!-- .page-masthead-wrap -->

    <div class="product-features-wrap">

      <div class="inner product-features flex flex-wrap -mx-4">
        <Content slot-key="feature-block-content-1" class="product-features__item w-full md:w-1/3 px-4"/>
        <Content slot-key="feature-block-content-2" class="product-features__item w-full md:w-1/3 px-4"/>
        <Content slot-key="feature-block-content-3" class="product-features__item w-full md:w-1/3 px-4"/>
      </div>
      <!-- .inner -->

    </div>
    <!-- .features-wrap -->

    <div class="testimonial-wrap">

      <div class="inner testimonial">
        <blockquote class="testimonial__content-wrap">
          <Content slot-key="testimonial-content"/>
          <div class="testimonial__cite">
            <div v-if="$page.frontmatter.testimonialPortraitSrc" class="testimonial__portrait">
              <img :src="$page.frontmatter.testimonialPortraitSrc" :alt="$page.frontmatter.testimonialPortraitAlt">
            </div> 
            <cite>
              <Content slot-key="testimonial-author"/>
              <Content slot-key="testimonial-author-info"/>
            </cite>
          </div>
        </blockquote>
      </div>
      <!-- .inner -->

    </div>
    <!-- .testimonial-wrap -->

    <div class="steps-wrap">

      <div class="inner steps-items">
        <header class="steps-items__header text-center">
          <Content slot-key="steps-title"/>
        </header>

        <ol class="steps-items__content">
          <li class="flex flex-wrap -mx-4">
            <Content slot-key="step-1-content" class="w-full px-4 lg:w-1/2"/>
            <Content slot-key="step-1-code-block" class="w-full px-4 lg:w-1/2"/>
          </li>
          <li class="flex flex-wrap -mx-4">
            <Content slot-key="step-2-content" class="w-full px-4 lg:w-1/2"/>
            <Content slot-key="step-2-code-block" class="w-full px-4 lg:w-1/2"/>
          </li>
          <li class="flex flex-wrap -mx-4">
            <Content slot-key="step-3-content" class="w-full px-4 lg:w-1/2"/>
            <Content slot-key="step-3-code-block" class="w-full px-4 lg:w-1/2"/>
          </li>
        </ol>

      </div>
      <!-- .inner -->

    </div>
    <!-- .steps-wrap -->

    <div class="newsletter-form-wrap">

      <div class="inner newsletter-form">
        <NewsletterForm />
      </div>

    </div>
    <!-- newsletter-form-wrap -->
    
  </div>
</template>

<script>
import Navbar from '@theme/components/Navbar'
import NewsletterForm from '@theme/components/custom/NewsletterForm'

export default {
  components: {
    Navbar,
    NewsletterForm
  }
};
</script>