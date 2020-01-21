<template>
  <header
    class="page-header text-center bg-gradient"
    :class="{ 'page-header--has-divider': hasDivider }"
    :style="`border-bottom-color: ${dividerColor}`"
  >
    <div class="inner">
      <h1>{{ title }}</h1>
      <p v-if="subTitle" class="page-sub-title">
        {{ subTitle }}
      </p>
    </div>
  </header>
</template>

<script>
export default {
  name: 'PageHeader',
  props: {
    title: {
      type: String,
      required: true
    },
    subTitle: {
      type: String,
      required: false
    },
    hasDivider: {
      type: Boolean,
      required: false,
      default: false
    },
    dividerColor: {
      type: String,
      required: false
    }
  }
}
</script>

<style>

</style>