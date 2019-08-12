<template>
  <div class="page-container page-container--home" aria-labelledby="masthead-main-title">
    
    <div class="inner">

      <div class="page-masthead-wrap flex">
        <div class="page-masthead w-full lg:w-1/2">
          <header class="page-masthead__header">
            <Content slot-key="masthead-sub-title"/>
            <Content slot-key="masthead-main-title"/>
          </header>
          <div class="page-masthead__actions">
            <router-link to="/install/" class="btn btn--large-text btn--bright">Install</router-link>
            <router-link to="/docs/" class="btn btn--large-text btn--hollow">Getting Started</router-link>
          </div>
        </div>
      </div>
      <!-- .page-masthead-wrap -->

      <div class="features flex">
        <Content slot-key="feature-block-content-1" class="features__item px-2"/>
        <Content slot-key="feature-block-content-2" class="features__item px-2"/>
        <Content slot-key="feature-block-content-3" class="features__item px-2"/>
      </div>
      <!-- .features -->
    
    </div>
    <!-- .inner -->

    <div class="steps-wrapper">

      <div class="inner steps-items">
        <header class="steps-items__header">
          <Content slot-key="steps-title"/>
        </header>
      </div>
      <!-- .inner -->

    </div>

    <div class="inner">

      <div class="testimonial">
        <div v-if="$page.frontmatter.testimonialPortraitSrc" class="testimonial__portrait">
          <img
            :src="$page.frontmatter.testimonialPortraitSrc"
            :alt="$page.frontmatter.testimonialPortraitAlt"
          >
        </div>
        <blockquote class="testimonial__content">
          <Content slot-key="testimonial-content"/>
          <cite>
            <Content slot-key="testimonial-author"/><br/>
            <Content slot-key="testimonial-extra"/>
          </cite>
        </blockquote>
      </div>
      <!-- .testimonial -->

    </div>
    <!-- .inner -->
    
  </div>
</template>

<script>
import Navbar from '@theme/components/Navbar'
import Footer from '@theme/components/custom/Footer'

export default {
  components: {
    Navbar,
    Footer
  }
};
</script>