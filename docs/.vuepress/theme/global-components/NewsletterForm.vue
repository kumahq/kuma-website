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
          v-for="(input, index) in utmFields"
          v-if="urlQuery[index]"
          type="hidden"
          :name="input"
          :value="urlQuery[index].value"
        />
        <!-- LIVE -->
        <!-- <input type="hidden" name="pardot-link" value="https://go.pardot.com/l/392112/2019-09-03/bjz6yv"> -->
        <!-- DEV -->
        <input type="hidden" name="pardot-link" value="https://go.pardot.com/l/392112/2020-01-14/bkwzrx">
        <label for="input_email" class="sr-only">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }">
          <input v-model="formData.input_email" id="email" name="email" type="email" />
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
        input_email: ''
      },
      utmFields: [
        'utm_content',
        'utm_medium',
        'utm_source',
        'utm_campaign',
        'utm_term',
        'utm_ad_group'
      ],
      urlQuery: [],
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
  beforeMount () {
    this.compileUrlQueries()
  },
  methods: {
    compileUrlQueries () {
      const query = this.$route.query || null

      if (query && query.length > 0) {
        this.utmFields.forEach(i => {
          const item = query[i]

          if (item && item.length > 0) {
            this.urlQuery.push({
              name: i,
              value: item
            })
          }
        })
      }
    },
    submitForm() {
      // const url = this.getNewsletterSignupEndpoint
      // const url = this.getNewsletterPardotEndpoint
      const url = this.getNewsletterPardotEndpointDev
      const payload = this.formData

      // send the form data
      const submitter = axios({
        method: 'post',
        url: url,
        params: payload,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
      })

      submitter
        .then(res => {
          console.log(res)
          // if everything is good, tell the app we have submitted successfully
          // we handle validation with vee-validate
          this.submitted = true
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