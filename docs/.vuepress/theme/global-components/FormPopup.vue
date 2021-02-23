<template>
  <div
    class="toast"
    :class="{ 'is-active': isActive }"
  >
    <div class="toast__inner">
      <button
        class="toast__close-button"
        @click="closeToast"
      >
        <span class="sr-only">Close Popup</span>
        <span class="toast__close-icon">
          &times;
        </span>
      </button>
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
      type: Number,
      default: 3000
    }
  },
  mounted () {
    this.displayToast()
  },
  methods: {
    displayToast () {
      setTimeout(ev => {
        this.isActive = true
        this.$emit('toast-opened')
      }, Number(this.$props.delay))
    },
    closeToast () {
      this.isActive = false
      this.$emit('toast-closed')
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
@import '../styles/custom/config/mixins';

$StartingMediaQuery: $MQLargeMid;

.toast {
  --toast-spacing: 2rem;
  --toast-ease-timing: 300ms;
  --toast-width: 450px;
  --toast-close-dims: 22px;
  --toast-close-font-size: 20px;
  --toast-ease-timing: 150ms;
  --toast-close-cancel: var(--red-base);
  --toast-close-base: #{$green-base};
  
  display: none;
  
  @media (min-width: $StartingMediaQuery) {
    display: block;
    position: fixed;
    z-index: 100;
    opacity: 0;
    bottom: var(--toast-spacing);
    right: var(--toast-spacing);
    width: var(--toast-width);
    transition: all var(--toast-ease-timing) cubic-bezier(0.44, 0.06, 0.24, 0.85);
    transform: translateX(120%);
    text-align: center;
    
    &.is-active {
      opacity: 1;
      transform: translateX(0);
    }
  }
}

@media (min-width: $StartingMediaQuery) {
  .toast__inner {
    position: relative;
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
  
  .toast__close-button {
    position: absolute;
    top: calc(var(--toast-close-dims) / 2);
    right: calc(var(--toast-close-dims) / 2);
    
    display: grid;
    place-items: center;
    
    height: var(--toast-close-dims);
    width: var(--toast-close-dims);
    
    padding: 0;
    margin: 0;
    border-radius: 3px;
    background: none;
    box-shadow: 0 0 0 1px var(--toast-close-base);
    
    color: var(--toast-close-base) !important;
    font-size: var(--toast-close-font-size);
    line-height: var(--toast-close-font-size);
    
    @include clear-text;
    
    transition: all var(--toast-ease-timing) ease-in-out;
    
    &:hover {
      background-color: var(--toast-close-cancel);
      box-shadow: 0 0 0 1px var(--toast-close-cancel);
      color: #fff !important;
    }
  }
}
</style>