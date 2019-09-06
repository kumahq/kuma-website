<template>
  <div class="page-container page-container--community">

    <header v-if="$page.frontmatter.title" class="page-header text-center bg-gradient">
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

          <div class="tower-wrap w-full lg:w-1/2 px-2">
            
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

      <div class="demo-request-form w-full sm:w-1/2 px-4">

        <form class="sticky" @submit.prevent="submitForm">
          <div class="flex flex-wrap -mx-4">

            <div class="w-full md:w-1/2 px-4">
              <label for="input_first_name">First Name</label>
              <input v-model="formData.input_first_name" id="input_first_name" name="input_first_name" type="text" />
            </div>

            <div class="w-full md:w-1/2 px-4">
              <label for="input_last_name">Last Name</label>
              <input v-model="formData.input_last_name" id="input_last_name" name="input_last_name" type="text" />
            </div>

            <div class="w-full md:w-1/2 px-4">
              <label for="input_email">Email</label>
              <input v-model="formData.input_email" id="input_email" name="input_email" type="email" />
            </div>

            <div class="w-full md:w-1/2 px-4">
              <label for="input_company">Company</label>
              <input v-model="formData.input_company" id="input_company" name="input_company" type="text" />
            </div>

            <div class="w-full md:w-1/2 px-4">
              <label for="input_phone">Phone</label>
              <input v-model="formData.input_phone" id="input_phone" name="input_phone" type="tel" />
            </div>

            <div class="w-full md:w-1/2 px-4">
              <label for="input_title">Title</label>
              <input v-model="formData.input_title" id="input_title" name="input_title" type="text" />
            </div>

            <div class="w-full px-4">
              <label for="input_message">How can we help you?</label>
              <textarea v-model="formData.input_message" id="input_message" name="input_message"></textarea>
            </div>

            <div class="w-full px-4 mt-4">
              <button name="submit" class="btn btn--bright btn--spaced btn--block">
                Request Demo
              </button>
            </div>

          </div>
        </form>

      </div>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import axios from 'axios'
// import superagent from 'superagent'
// import Vuelidate from 'vuelidate'
// import { required, email } from 'vuelidate/lib/validators'

export default {
  data() {
    return {
      formData: {
        input_first_name: '',
        input_last_name: '',
        input_email: '',
        input_company: '',
        input_phone: '',
        input_title: '',
        input_message: ''
      }
    }
  },
  methods: {
    submitForm() {
      const url = 'https://script.google.com/macros/s/AKfycbwiFfaiSK6JqdNqZLAt5PRayPV43x7qw1ZAM_-sFSDg6IT44d4/exec'
      const payload = this.formData

      axios({
        method: 'post',
        url: url,
        data: payload,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
      })
      .then(res => JSON.stringify(res))
      .then(res => {
        console.info(res)
      })
      .catch(err => {
        console.error(err)
      })
    }
  }
}
</script>

<style lang="scss">

</style>