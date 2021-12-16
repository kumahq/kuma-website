<template>
  <div class="form-wrapper">

    <validation-observer
      v-slot="{ invalid, passes }"
    >
      <form
        v-if="formStatus === null || formStatus === false"
        :class="{ 'form-horizontal': (stacked === false), 'form-stacked': (stacked === true) }"
        ref="communityCallForm"
        @submit="formIsSubmitting"
      >
        <input
          v-for="(key, value) in formData"
          v-if="value !== 'email'"
          :name="value"
          :value="key"
          type="hidden"
        />
        <input type="hidden" name="pardot-link" :value="formEndpoint">
        <label for="input_email" class="sr-only">Email</label>
        <validation-provider rules="required|email" v-slot="{ errors }">
          <input v-model="formData.email" id="email" name="email" type="email" placeholder="Email" />
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
            Register Now
          </span>
        </button>
      </form>
    </validation-observer>

    <div ref="formMessageMarker"></div>

    <div v-if="formStatus === true" class="tip custom-block">
      <p class="custom-block-title">Thank you!</p>
      <p>
        We've received your request to register for the upcoming Community Call.
        Thank you for your interest in {{ getSiteData.title }}!
      </p>
      <ul class="inline-list">
        <li>
          <a :href="agenda" target="_blank">
            <span class="icon">📝</span>  Agenda
          </a>
        </li>
        <li>
          <a :href="invite" target="_blank">
            <span class="icon">📅</span> Add to Your Calendar
          </a>
        </li>
        <li>
          <a href="https://www.youtube.com/playlist?list=PLg_AhYkg50viOMrea6Nm3t9JCempVyLcj" target="_blank">
            <span class="icon">🎥</span> Past Recordings
          </a>
        </li>
      </ul>
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
  props: {
    stacked: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    ...mapGetters({
      formEndpoint: 'getCommunityCallFormEndpoint',
      agenda: 'getCommunityCallAgendaUrl',
      invite: 'getCommunityCallInvite'
    })
  },
  methods: {
    formIsSubmitting(ev) {
      this.formSending = true
      
      ev.preventDefault()
      
      ajax({
        url: this.formEndpoint,
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
        event('Form Submission - Community Call', 'Success')
      }
    },
  }
}
</script>

<style lang="scss" scoped>
@import '../styles/custom/config/variables';

.note {
  margin-top: 10px !important;
}

.form-stacked {
  
  .btn {
    margin-top: 0.8rem;
  }
}

.form-wrapper .custom-block {
  box-shadow: 0 0 0 1px #cccccc, 0 3px 6px 0 #eaecef;
  padding: 20px;
  // border-left: 0;

  // success
  &.tip {
    background-color: #fff;
  }

  // error
  &.danger {

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

.form-wrapper {
    
  form {
    border-radius: 0;
    overflow: visible;
  }
}

.inline-list {
  display: block;
  overflow: hidden;
  list-style: none;
  margin: 10px 0 0 0 !important;
  padding: 0;

  li {
    display: inline-block;

    &:not(:last-of-type) {
      border-right: 1px solid #ccc;
      margin-right: 8px;
      padding-right: 10px;
    }
  }

  a {
    display: block;
  }

  .icon {
    display: inline-block;
    margin: 0 5px 0 0;
  }
}
</style>