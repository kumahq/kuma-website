<template>
  <header v-if="title" class="page-header text-center bg-gradient">
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
    }
  }
}
</script>

<style>

</style>