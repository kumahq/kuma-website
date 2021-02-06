<template>
  <div class="card">
    <header class="card__header">
      <div class="card__icon" v-if="icon">
        <img
          :src="icon"
          :alt="iconAlt"
        >
      </div>
      <div class="card__title">
        <slot name="card-title"></slot>
      </div>
    </header>
    <div class="card__content">
      <slot></slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Card',
  props: {
    icon: {
      type: String
    },
    iconWidth: {
      type: Number
    },
    iconHeight: {
      type: Number
    },
    iconAlt: {
      type: String
    }
  }
}
</script>