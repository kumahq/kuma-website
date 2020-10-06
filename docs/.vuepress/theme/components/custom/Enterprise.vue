<template>
  <div class="page-container page-container--community">

    <PageHeader
      :title="$page.frontmatter.pageTitle"
      :subTitle="$page.frontmatter.subTitle"
    />

    <div class="company-list-wrapper">
      <div class="inner">
        <ul class="company-list md:flex md:flex-wrap -mx-2">
          <li v-for="(company, index) in $page.frontmatter.companies" :key="index" class="px-2 mx-auto md:w-1/2">
            <a :href="company.url" class="company-list__link block md:flex">
              <div v-if="company.image" class="w-full md:w-1/5 md:mx-0 md:mr-6 text-center">
                <img :src="company.image" :alt="`Logo image for ${company.name}`" class="w-24 mx-auto md:w-full">
              </div>
              <div class="w-full md:w-4/5 text-center md:text-left">
                <h3 class="mb-2">{{ company.name }}</h3>
                <p v-if="company.summary" class="m-0">
                  {{ company.summary }}
                </p>
              </div>
            </a>
          </li>
        </ul>
      </div>
      <!-- .inner -->
    </div>

    <div v-if="$page.frontmatter.pullRequestUrl" class="pull-request-cta mt-12 pt-12">
      <div class="inner text-center">
        <h3>Are you offering a Kuma enterprise package?</h3>
        <p>
          <a :href="$page.frontmatter.pullRequestUrl" class="btn" target="_blank">
            Create a Pull Request
          </a>
        </p>
      </div>
      <!-- .inner -->
    </div>
  
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import axios from 'axios'
import { ValidationProvider, ValidationObserver, extend } from 'vee-validate'
import { required, email } from 'vee-validate/dist/rules'
import PageHeader from '@theme/global-components/PageHeader'

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
    ValidationObserver,
    PageHeader
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
.company-list {
  list-style: none;

  li {
    display: block;
  }
}

.company-list__link {
  $hover-color: #3fa66a;
  $cubic-bezier: cubic-bezier(0.47, 0.37, 0.36, 0.92);

  // display: flex;
  // align-items: center;
  // justify-content: center;
  overflow: hidden;
  min-height: 8rem;
  background-color: #fff;
  border: 1px solid #c6cfd7;
  border-radius: 5px;
  padding: 1.4375rem 0.5rem;
  transition: 
    color 200ms $cubic-bezier, 
    border 200ms $cubic-bezier;

  &:hover, &:active {
    // no more scale on hover because Chrome on Retina does not play nice with it
    // transform: scale(1.05);
    border: 1px solid $hover-color;
    color: $hover-color;

    h3, p {
      color: $hover-color;
    }
  }

  h3, p {
    transition: color 200ms $cubic-bezier;
  }

  h3 {
    padding: 0;
    margin: 0;
    font-size: 1.188rem;
    font-weight: 500;
    color: rgba(#000, 0.70);
    line-height: 1.5rem;
  }

  p {
    font-weight: normal;
    color: rgba(#000, 0.70);
  }
}

.pull-request-cta {
  border-top: 1px solid #eaecef;
}
</style>