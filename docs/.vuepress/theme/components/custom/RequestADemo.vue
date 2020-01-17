<template>
  <div class="page-container page-container--community">

    <header v-if="$page.frontmatter.pageTitle" class="page-header text-center bg-gradient">
      <div class="inner">
        <h1>{{ $page.frontmatter.pageTitle }}</h1>
        <p v-if="$page.frontmatter.pageTitle" class="page-sub-title">{{ $page.frontmatter.subTitle }}</p>
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
                  <li class="tower__focus-item">24/7/365 Support SLAs</li>
                  <li class="tower__focus-item">Email Support</li>
                  <li class="tower__focus-item">Phone Support</li>
                  <li class="tower__focus-item">Deployment and Setup</li>
                  <li class="tower__focus-item">Hot Fixes and Emergency Patches</li>
                  <li class="tower__focus-item">Custom Policies</li>
                  <li class="tower__focus-item">Envoy Expertise</li>
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

        <validation-observer v-slot="{ invalid, passes }">
          <form v-if="!submitted" class="sticky" @submit.prevent="passes(submitForm)">
            <div class="flex flex-wrap -mx-4">

              <div class="w-full md:w-1/2 px-4">
                <label for="input_first_name">First Name</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <input v-model="formData.input_first_name" id="input_first_name" name="input_first_name" type="text" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full md:w-1/2 px-4">
                <label for="input_last_name">Last Name</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <input v-model="formData.input_last_name" id="input_last_name" name="input_last_name" type="text" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full md:w-1/2 px-4">
                <label for="input_email">Email</label>
                <validation-provider rules="required|email" v-slot="{ errors }">
                  <input v-model="formData.input_email" id="input_email" name="input_email" type="email" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full md:w-1/2 px-4">
                <label for="input_company">Company</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <input v-model="formData.input_company" id="input_company" name="input_company" type="text" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full md:w-1/2 px-4">
                <label for="input_phone">Phone</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <input v-model="formData.input_phone" id="input_phone" name="input_phone" type="tel" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full md:w-1/2 px-4">
                <label for="input_title">Title</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <input v-model="formData.input_title" id="input_title" name="input_title" type="text" />
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full px-4">
                <label for="input_message">How can we help you?</label>
                <validation-provider rules="required" v-slot="{ errors }">
                  <textarea v-model="formData.input_message" id="input_message" name="input_message"></textarea>
                  <span class="note note--error">{{ errors[0] }}</span>
                </validation-provider>
              </div>

              <div class="w-full px-4 mt-4">
                <button :disabled="invalid" name="submit" class="btn btn--bright btn--spaced btn--block">
                  Request Demo
                </button>
              </div>

            </div>
          </form>
        </validation-observer>

        <div v-if="submitted" class="tip custom-block">
          <p class="custom-block-title">Thank you!</p>
          <p>Your submission has been received.</p>
        </div>

        <div v-if="error" class="danger custom-block">
          <p class="custom-block-title">Whoops!</p>
          <p>Something went wrong! Please try again later.</p>
        </div>

      </div>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import axios from 'axios'
import { ValidationProvider, ValidationObserver, extend } from 'vee-validate'
import { required, email } from 'vee-validate/dist/rules'

// required validation
extend('required', {
  ...required,
  message: 'This field is required.'
})

// email validation
extend('email', {
  ...email,
  message: 'This must be a valid email'
})

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
      },
      submitted: false,
      error: false
    }
  },
  components: {
    ValidationProvider,
    ValidationObserver
  },
  computed: {
    ...mapGetters([
      'getRequestADemoEndpoint'
    ]),
  },
  methods: {
    submitForm() {
      const url = this.getRequestADemoEndpoint
      const payload = this.formData

      // tell the app we have submitted successfully
      this.submitted = true

      // send the form data
      axios({
        method: 'post',
        url: url,
        params: payload,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
      })
      .catch(err => {
        // let the app know if an error has occurred
        this.error = true
      })
    }
  }
}
</script>

<style lang="scss">

</style>