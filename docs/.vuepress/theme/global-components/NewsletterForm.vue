<template>
  <div class="form-wrapper">

    <validation-observer
      v-slot="{ invalid, passes }"
    >
      <form
        class="form-horizontal"
        method="post"
        :action="getNewsletterPardotEndpoint"
      >
        <input
          v-for="(key, value) in formData"
          v-if="value !== 'email'"
          :name="value"
          :value="key"
          type="hidden"
        />
        <!-- LIVE -->
        <input type="hidden" name="pardot-link" :value="getNewsletterPardotEndpoint">
        <!-- DEV -->
        <!-- <input type="hidden" name="pardot-link" :value="getNewsletterPardotEndpointDev"/> -->
        <label for="input_email" class="sr-only">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }">
          <input v-model="formData.email" id="email" name="email" type="email" placeholder="Work Email" />
          <span class="note note--error">{{ errors[0] }}</span>
        </validation-provider>
        <button 
          :disabled="invalid"
          type="submit"
          name="submit"
          class="btn btn--dark"
          :class="{ 'is-sending': (invalid === false && formSending === true) }"
          @click="formIsSubmitting()"
        >
          <span v-if="invalid === false && formSending === true">
            <Spinner />
          </span>
          <span v-else>
            Join Newsletter
          </span>
        </button>
      </form>
    </validation-observer>

    <div ref="formMessageMarker"></div>

    <div v-if="formStatus === true" class="tip custom-block">
      <p class="custom-block-title">Thank you!</p>
      <p>Your submission has been received.</p>
    </div>

    <div v-if="formStatus === false" class="danger custom-block">
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

// I am doing this because of an error that occurred when using KIcon
import Spinner from '@theme/global-components/IconSpinner'

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
      formStatus: null,
      formSending: false
    }
  },
  components: {
    ValidationProvider,
    ValidationObserver,
    Spinner
  },
  computed: {
    ...mapGetters([
      'getNewsletterPardotEndpoint',
      'getNewsletterPardotEndpointDev'
    ]),
    formDistanceFromTop () {
      const marker = this.$refs['formMessageMarker']

      return window.pageYOffset + marker.getBoundingClientRect().top
    }
  },
  mounted () {
    this.formBehaviorHandler()
  },
  methods: {
    formBehaviorHandler () {
      const query = this.$route.query.form_success
      const status = query ? JSON.parse(query) : null

      this.formStatus = status

      if (status === false || status === true) {
        window.scrollTo({
          top: this.formDistanceFromTop,
          behavior: 'auto'
        })
      }
    },

    formIsSubmitting() {
      this.formSending = true
    },
  }
}
</script>

<style lang="scss" scoped>
button.is-sending {
  text-align: center;

  span {
    height: 40px;
    display: block;
    margin: 0 auto;
  }

  svg {
    position: relative;
    top: calc(50% - 14px); left: calc(50% - 12px);
  }
}
</style>