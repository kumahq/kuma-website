<template>
  <div class="form-wrapper">

    <validation-observer v-slot="{ invalid, passes }">
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
      'getNewsletterSignupEndpoint'
    ])
  },
  methods: {
    submitForm() {
      const url = this.getNewsletterSignupEndpoint
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