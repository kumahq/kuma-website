<template>
  <div class="page-container page-container--home" aria-labelledby="masthead-main-title">
    
    <div class="page-masthead-wrap">

      <div class="inner flex flex-wrap -mx-4">

        <div class="page-masthead w-full lg:w-1/2 px-4">
          <header class="page-masthead__header">
            <Content slot-key="masthead-main-title"/>
            <Content slot-key="masthead-sub-title"/>
          </header>
          <div class="page-masthead__actions">
            <router-link
              to="/install/" 
              class="btn btn--bright">
              Install
            </router-link>
            <router-link
              to="#why-kuma" 
              class="btn btn--hollow">
              Why {{ getSiteData.title }}?
            </router-link>
          </div>
        </div>
        <!-- .page-masthead -->

        <div class="page-masthead__diagram w-full lg:w-1/2 px-4">
          <Content slot-key="masthead-diagram"/>
        </div>

      </div>
      <!-- .inner -->
    
    </div>
    <!-- .page-masthead-wrap -->

    <div class="product-features-wrap">

      <div v-if="$page.frontmatter.newsLink && $page.frontmatter.newsTagline" class="inner newsbar-wrap">
        <div class="newsbar">
          <span class="newsbar__tag">News</span>
          <p>
            <a :href="$page.frontmatter.newsLink"> {{$page.frontmatter.newsTagline}} <span class="newsbar__arrow">&rarr;</span></a>
          </p>
        </div>
      </div>

      <div class="inner product-features flex flex-wrap -mx-4">
        <Content slot-key="feature-block-content-1" class="product-features__item w-full md:w-1/3 px-4"/>
        <Content slot-key="feature-block-content-2" class="product-features__item w-full md:w-1/3 px-4"/>
        <Content slot-key="feature-block-content-3" class="product-features__item w-full md:w-1/3 px-4"/>
      </div>
      <!-- .inner -->

    </div>
    <!-- .features-wrap -->

    <div v-if="$page.frontmatter.hideTestimonial" class="testimonial-wrap">

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

    <div class="steps-wrap steps-wrap--slim">

      <div class="inner tabs-wrap">
        <header class="section-header steps-items__header text-center">
          <Content slot-key="tabs-section-title"/>
        </header>

        <TinyTabs
          id="get-started-steps-tabs"
          :anchor="false"
          :closable="false"
          :hideTitle="true"
        >
          <div class="section" id="tab-1">
            <Content slot-key="tab-1-title" class="title"/>
            <ol class="steps-items__content steps-items__content--narrow">
              <li>
                <Content slot-key="tab-1-content-step-1"/>
                <Content slot-key="tab-1-code-block-step-1"/>
              </li>
              <li>
                <Content slot-key="tab-1-content-step-2"/>
                <Content slot-key="tab-1-code-block-step-2"/>
              </li>
              <li>
                <Content slot-key="tab-1-content-step-3"/>
                <Content slot-key="tab-1-code-block-step-3"/>
              </li>
            </ol>
          </div>
          <div class="section" id="tab-2">
            <Content slot-key="tab-2-title" class="title"/>
            <ol class="steps-items__content steps-items__content--narrow">
              <li>
                <Content slot-key="tab-2-content-step-1"/>
                <Content slot-key="tab-2-code-block-step-1"/>
              </li>
              <li>
                <Content slot-key="tab-2-content-step-2"/>
                <Content slot-key="tab-2-code-block-step-2"/>
              </li>
              <li>
                <Content slot-key="tab-2-content-step-3"/>
                <Content slot-key="tab-2-code-block-step-3"/>
              </li>
            </ol>
          </div>
        </TinyTabs>
      </div>
      <!-- .tabs -->

      <!-- <div class="inner steps-items">
        <header class="section-header steps-items__header text-center">
          <Content slot-key="steps-title"/>
        </header>

        <ol class="steps-items__content">
          <li>
            <Content slot-key="step-1-content"/>
            <Content slot-key="step-1-code-block"/>
          </li>
          <li>
            <Content slot-key="step-2-content"/>
            <Content slot-key="step-2-code-block"/>
          </li>
          <li>
            <Content slot-key="step-3-content"/>
            <Content slot-key="step-3-code-block"/>
          </li>
        </ol>
      </div> -->
      <!-- .steps-items -->

      <div id="why-kuma">
        <!-- Why Kuma anchor -->
      </div>

    </div>
    <!-- .steps-wrap -->

    <div class="before-after-wrap">

      <div class="inner before-after">
        <header class="section-header">
          <Content slot-key="before-after-title" class="alt-title"/>
        </header>
        <div class="flex flex-wrap -mx-12">
          <div class="w-full px-12 md:w-1/2">
            <h4>Before</h4>
            <Content slot-key="before-after-diagram-1"/>
          </div>
          <div class="w-full px-12 md:w-1/2">
            <h4>After</h4>
            <Content slot-key="before-after-diagram-2"/>
          </div>
        </div>
      </div>
      <!-- .inner -->

    </div>
    <!-- .before-after-wrap -->

    <div class="newsletter-form-wrap">

      <div class="inner newsletter-form">
        <header class="section-header">
          <Content slot-key="newsletter-title" class="alt-title"/>
        </header>
        <Content slot-key="newsletter-content"/>
        <NewsletterForm />
      </div>

    </div>
    <!-- newsletter-form-wrap -->
    
  </div>
</template>

<script>
import Navbar from '@theme/components/Navbar'
import TinyTabs from '@theme/components/custom/TinyTabs/VueTinyTabs'

export default {
  components: {
    Navbar,
    TinyTabs
  }
};
</script>