<template>
  <div class="card">
    <header class="card__header">
      <div class="card__icon" v-if="icon">
        <InlineSvg
          :src="icon"
          :width="iconWidth"
          :height="iconHeight"
        />
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
      type: String,
      required: true
    },
    iconWidth: {
      type: Number,
      required: true
    },
    iconHeight: {
      type: Number,
      required: true
    },
  }
}
</script>

<style lang="scss">

</style>