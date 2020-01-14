<template>
  <div class="form-wrapper">

    <!-- <validation-observer v-slot="{ invalid, passes }">
      <form v-if="!submitted" class="form-horizontal" @submit.prevent="passes(submitForm)">
        <label for="input_email" class="sr-only">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }">
          <input v-model="formData.input_email" id="input_email" name="input_email" type="email" />
          <span class="note note--error">{{ errors[0] }}</span>
        </validation-provider>
        <button :disabled="invalid" type="submit" name="submit" class="btn btn--bright">
          Join Newsletter
        </button>
      </form>
    </validation-observer> -->

    <validation-observer
      v-slot="{ invalid, passes }"
    >
      <form
        v-if="!submitted"
        class="form-horizontal"
        @submit.prevent="passes(submitForm)"
      >
        <input
          v-for="(key, value) in formData"
          v-if="value !== 'email'"
          :name="value"
          :value="key"
          type="hidden"
        />
        <!-- LIVE -->
        <!-- <input type="hidden" name="pardot-link" :value="getNewsletterPardotEndpoint"> -->
        <!-- DEV -->
        <input type="hidden" name="pardot-link" :value="getNewsletterPardotEndpointDev"/>
        <label for="input_email" class="sr-only">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }">
          <input v-model="formData.email" id="email" name="email" type="email" />
          <span class="note note--error">{{ errors[0] }}</span>
        </validation-provider>
        <button :disabled="invalid" type="submit" name="submit" class="btn btn--bright">
          Join Newsletter
        </button>
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
        email: '',
        utm_content: this.$route.query.utm_content || null,
        utm_medium: this.$route.query.utm_medium || null,
        utm_source: this.$route.query.utm_source || null,
        utm_campaign: this.$route.query.utm_campaign || null,
        utm_term: this.$route.query.utm_term || null,
        utm_ad_group: this.$route.query.utm_ad_group || null
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
      'getNewsletterPardotEndpoint',
      'getNewsletterPardotEndpointDev'
    ])
  },
  methods: {
    submitForm() {
      // const url = this.getNewsletterSignupEndpoint
      const url = this.getNewsletterPardotEndpoint
      // const url = this.getNewsletterPardotEndpointDev
      const payload = this.formData

      // send the form data
      const submitter = axios({
        method: 'post',
        url: url,
        params: payload,
        withCredentials: true
        // headers: {
        //   'Content-Type': 'application/x-www-form-urlencoded',
        //   'Accept': 'application/json'
        // }
      })

      submitter
        .then(res => {
          // if everything is good, tell the app we have submitted successfully
          // we handle validation with vee-validate
          console.log(res)
          
          if (res && res.statusText === 'OK') {
            this.submitted = true
          } else {
            this.error = true
          }
        })
        .catch(err => {
          // let the app know if an error has occurred
          this.error = true
          console.log(err)
        })
    }
  }
}
</script>