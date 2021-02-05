<template>
  <div
    class="form-wrapper"
    :class="{ 'form-wrapper--compact': (simple === true) }"
  >

    <validation-observer
      v-slot="{ invalid, passes }"
    >
      <form
        v-if="formStatus === null || formStatus === false"
        class="form-horizontal"
        ref="newsletterForm"
        @submit="formIsSubmitting"
      >
        <input
          v-for="(key, value) in formData"
          v-if="value !== 'email'"
          :name="value"
          :value="key"
          type="hidden"
        />
        <input type="hidden" name="pardot-link" :value="getFormHandler">
        <label for="input_email" class="sr-only" v-model="formData.email">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }" class="form-note-wrapper">
          <input v-model="formData.email" id="email" name="email" type="email" placeholder="Work Email" />
          <span class="note note--error">{{ errors[0] }}</span>
        </validation-provider>
        <button 
          :disabled="invalid"
          type="submit"
          name="submit"
          class="btn"
          :class="{ 'is-sending': (invalid === false && formSending === true) }"
        >
          <span v-if="invalid === false && formSending === true">
            <Spinner />
          </span>
          <span :class="{ 'is-hidden': (invalid === false && formSending === true) }">
            {{ getFormSubmitText }}
          </span>
        </button>
      </form>
    </validation-observer>

    <div ref="formMessageMarker"></div>

    <div v-if="formStatus === true" class="tip custom-block">
      <slot name="success">
        <p class="custom-block-title">Thank you!</p>
        <p>You're now signed up for the {{ getSiteData.title }} newsletter.</p>
      </slot>
    </div>

    <div v-if="formStatus === false" class="danger custom-block">
      <slot name="error">
        <p class="custom-block-title">Whoops!</p>
        <p>Something went wrong! Please try again later.</p>
      </slot>
    </div>

  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import axios from 'axios'
import { ValidationProvider, ValidationObserver, extend } from 'vee-validate'
import { required, email } from 'vee-validate/dist/rules'
import { event } from 'vue-analytics'
import { ajax } from 'jquery'

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
        utm_source: 'kuma-homepage',
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
  props: {
    formHandler: {
      type: String,
      default: () => 'getNewsletterFormEndpoint'
    },
    simple: {
      type: Boolean,
      default: false
    },
    formSubmitText: {
      type: String,
      default: () => null
    },
    scrollOffset: {
      type: Number,
      default: () => 0
    }
  },
  computed: {
    getFormHandler () {
      return this.$store.getters[this.$props.formHandler]
    },
    getFormSubmitText () {
      return this.$props.formSubmitText || 'Join Newsletter'
    }
  },
  methods: {
    formIsSubmitting(ev) {
      this.formSending = true
      
      ev.preventDefault()
      
      ajax({
        url: this.getFormHandler,
        type: 'GET',
        dataType: 'jsonp',
        crossDomain: true,
        data: this.formData,
        xhrFields: {
          withCredentials: true
        },
        complete: () => {
          this.formSending = false
          this.formStatus = true
        }
      })
      
      // push a Google Analytics event for form submission
      if (process.env.NODE_ENV === 'production') {
        event('Form Submission - Newsletter', 'Success')
      }
    },
  }
}
</script>

<style lang="scss" scoped>
@import '../styles/custom/config/variables';

.form-note-wrapper {
  position: relative;

  .note {
    position: absolute;
    top: 100%; left: 0;
    z-index: 1;
    width: 100%;
  }
}


button.is-sending {
  position: relative;
  background-color: $green-base !important;
  cursor: not-allowed;

  span:not(.is-hidden) {
    display: block;
    position: absolute;
    left: calc(50% - 12px);
  }
}

.is-hidden {
  opacity: 0;
  visibility: hidden;
}

.form-wrapper .custom-block {
  box-shadow: 0 0 0 1px #cccccc, 0 3px 6px 0 #eaecef;
  padding: 20px;
  text-align: left;
  // border-left: 0;

  // success
  &.tip {
    background-color: #fff;
  }

  // error
  &.danger {

  }

  p {

    &:first-of-type {
      margin-top: 0;
      padding-top: 0;
    }

    &:last-of-type {
      margin-bottom: 0;
      padding-bottom: 0;
    }
  }
}
</style>