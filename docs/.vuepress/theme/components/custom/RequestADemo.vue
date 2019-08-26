<template>
  <div class="page-container page-container--community">

    <header v-if="$page.frontmatter.title" class="page-header text-center bg-gradient" ref="pageHeader">
      <div class="inner">
        <h1>{{ $page.frontmatter.title }}</h1>
        <p v-if="$page.frontmatter.title" class="page-sub-title">{{ $page.frontmatter.subTitle }}</p>
      </div>
      <!-- .inner -->
    </header>
    <!-- .page-header -->

    <div class="inner flex flex-wrap -mx-4">

      <div class="w-full sm:w-1/2 px-4">

        <div class="flex flex-wrap -mx-2">

          <div class="tower-wrap w-full lg:w-1/2 px-2" ref="featuresColumn">
            
            <div class="tower">
              <div class="tower__header">
                <h3>Community</h3>
              </div>
              <div class="tower__content">
                <ul class="tower__list">
                  <li class="tower__list-title tower__list-title--muted">
                    <h4>Basic Features</h4>
                  </li>
                  <li>{{ getSiteData.title }} Core</li>
                  <li>{{ getSiteData.title }} OSS Policies</li>
                  <li class="tower__list-title tower__list-title--positive tower__footer-item">Free</li>
                </ul>
              </div>
            </div>
            <!-- .tower -->
            
          </div>

          <div class="tower-wrap w-full lg:w-1/2 px-2">
            
            <div class="tower">
              <div class="tower__header">
                <h3>Enterprise</h3>
              </div>
              <div class="tower__content">
                <ul class="tower__list">
                  <li class="tower__list-title tower__list-title--muted">
                    <h4>Basic Features</h4>
                  </li>
                  <li>{{ getSiteData.title }} Core</li>
                  <li>{{ getSiteData.title }} OSS Policies</li>
                  <li class="tower__list-title tower__list-title--focus">
                    <h4>Enterprise Support</h4>
                  </li>
                  <li class="tower__focus-item">Email Support</li>
                  <li class="tower__focus-item">Phone Support</li>
                  <li class="tower__focus-item">Initial Setup and Upgrade Path</li>
                  <li class="tower__focus-item">Org Architectural Review</li>
                  <li class="tower__focus-item">Hot fixes and emergency patches</li>
                  <li class="tower__focus-item">Custom Policies</li>
                  <li class="tower__focus-item">Integration with Kong Enterprise</li>
                  <li class="tower__list-title tower__list-title--neutral">
                    <span class="desktop">Fill out form on the right</span>
                    <span class="mobile">Fill out form below</span>
                  </li>
                </ul>
              </div>
            </div>
            <!-- .tower -->

          </div>

        </div>

      </div>

      <div class="demo-request-form w-full sm:w-1/2 px-4" ref="demoRequestForm">
        <form action="">
          <div class="flex flex-wrap -mx-4">   
            <div class="w-full md:w-1/2 px-4">
              <label for="input-firstname">First Name</label>
              <input type="text" name="firstname" id="input-firstname">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-lastname">Last Name</label>
              <input type="text" name="lastname" id="input-lastname">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-workemail">Work Email</label>
              <input type="text" name="workemail" id="input-workemail">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-phone">Phone</label>
              <input type="text" name="phone" id="input-phone">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-jobtitle">Job Title</label>
              <input type="text" name="jobtitle" id="input-jobtitle">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-companyname">Company Name</label>
              <input type="text" name="companyname" id="input-companyname">
            </div>
            <div class="w-full px-4">
              <label for="input-comments">How can we help you?</label>
              <textarea name="comments" id="input-comments"></textarea>
            </div>
            <div class="w-full px-4 mt-4">
              <button class="btn btn--bright btn--spaced btn--block">Request Demo</button>
            </div>
          </div>
        </form>
      </div>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import debounce from 'lodash/debounce'

export default {
  methods: {
    handleScroll(ev) {
      const requestForm = this.$refs.demoRequestForm
      const header = this.$refs.pageHeader
      const featuresCol = this.$refs.featuresColumn

      if (window.pageYOffset > ( header.scrollTop + header.offsetHeight )) {
        requestForm.classList.add('sticky')
        requestForm.querySelector('form').style.maxWidth = `${requestForm.offsetWidth}px`
      }
      else {
        requestForm.classList.remove('sticky')
        requestForm.querySelector('form').style.maxWidth = null
      }
    }
  },
  mounted() {
    const debouncedScroll = debounce( this.handleScroll, 0 )
    if (window.innerWidth >= 640) {
      window.addEventListener('scroll', debouncedScroll)
    }
  },
  beforeDestroy() {
    // remove the event listener before navigating to another page
    window.removeEventListener('scroll', this.debouncedScroll)
  }
}
</script>

<style lang="scss">

</style>