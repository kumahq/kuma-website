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
    </div>

    <div class="features">
      <!-- feature columns here (content drawn from homepage .md file slots) -->
    </div>

    <main class="page-content">
      <Content/>
    </main>

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