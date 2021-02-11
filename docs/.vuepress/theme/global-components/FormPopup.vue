<template>
  <div
    class="toast"
    :class="{ 'is-active': isActive }"
  >
    <div class="toast__inner">
      <header class="toast__header">
        <h3>Ready to get started?</h3>
      </header>
      <!-- /.toast__header -->
      <div class="toast__content">
        <p>Receive a step-by-step onboarding guide delivered directly to your inbox</p>
      </div>
      <!-- /.toast__content -->
      <NewsletterForm
        formSubmitText="Register Now"
        :simple="true"
      >
        <template v-slot:success>
          <p class="custom-block-title">Thank you!</p>
          <p>Please check your inbox for more info on our {{ getSiteData.title }} onboarding guide.</p>
        </template>
      </NewsletterForm>
    </div>
    <!-- /.toast-inner -->
  </div>
</template>

<script>
import NewsletterForm from '@theme/global-components/NewsletterForm'

export default {
  name: 'FormPopup',
  components: {
    NewsletterForm
  },
  data () {
    return {
      isActive: false
    }
  },
  props: {
    delay: {
      type: String,
      default: 3000
    }
  },
  mounted () {
    this.displayToast()
  },
  methods: {
    displayToast () {
      setInterval(ev => {
        this.isActive = true
      }, Number(this.$props.delay))
    }
  }
}
</script>

<style lang="scss">
@import '../styles/custom/config/variables';

.toast {
  
  form {
    background-color: #fff;
  }
  
  input[type='email'] {
    border-radius: 20px 0 0 20px !important;
    background-color: #fff !important;
    border: 0 !important;
  }
}
</style>

<style lang="scss" scoped>
@import '../styles/custom/config/variables';

.toast {
  --toast-spacing: 2rem;
  --toast-ease-timing: 300ms;
  --toast-width: 450px;
  
  position: fixed;
  z-index: 100;
  opacity: 0;
  bottom: var(--toast-spacing);
  right: var(--toast-spacing);
  width: calc(100% - (var(--toast-spacing) * 2));
  transition: all var(--toast-ease-timing) cubic-bezier(0.44, 0.06, 0.24, 0.85);
  transform: translateX(120%);
  text-align: center;
  
  &.is-active {
    opacity: 1;
    transform: translateX(0);
  }
  
  @media (min-width: 576px) {
    width: var(--toast-width);
  }
}

.toast__inner {
  background-color: $pale-blue;
  padding: 2rem;
  box-shadow: $base-soft-shadow;
  border: 1.5px solid rgba(#ccc, 0.5);
  border-radius: 5px;
}

.toast__header {
  
  > * {
    margin: 0;
    padding: 0;
  }
}
</style>