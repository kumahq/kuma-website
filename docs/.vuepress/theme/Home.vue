<template>
  <div class="theme-container theme-container--home">
    <Navbar/>

    <div class="page-masthead">
      <header class="page-masthead__header">
        <Content slot-key="masthead-main-title"/>
        <Content slot-key="masthead-sub-title"/>
      </header>
      <div class="page-masthead__actions">
        <KButton appearance="primary">Install</KButton>
        <KButton appearance="secondary">Getting Started</KButton>
      </div>
    </div> <!-- .page-masthead -->

    <div class="features">
      <Content slot-key="feature-block-content-1" class="features__item"/>
      <Content slot-key="feature-block-content-2" class="features__item"/>
      <Content slot-key="feature-block-content-3" class="features__item"/>
    </div> <!-- .features -->

    <div class="testimonial">
      <div v-if="$page.frontmatter.testimonialPortraitSrc" class="testimonial__portrait">
        <img :src="$page.frontmatter.testimonialPortraitSrc" :alt="$page.frontmatter.testimonialPortraitAlt">
      </div>
      <div class="testimonial__content">
        <Content slot-key="testimonial-content"/>
      </div>
    </div> <!-- .testimonial -->

    <!-- <main class="page-content">
      <Content/>
    </main> -->

    <Footer/>
  </div>
</template>

<script>
import Navbar from '@vuepress/theme-default/components/Navbar'
import Footer from './components/Footer'

export default {
  components: {
    Navbar,
    Footer
  }
}
</script>