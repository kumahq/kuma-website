<template>
  <div class="post-summary">
    <p>
      {{ summary }}
    </p>
  </div>
</template>

<script>
export default {
  props: {
    content: {
      type: String,
      required: true
    },
    maxWords: {
      type: Number,
      required: false,
      default: 10
    }
  },
  computed: {
    summary () {
      const max = this.maxWords
      const array = this.content.trim().split(' ');
      const ellipsis = array.length > max ? '...' : '';

      return array.slice(0, max).join(' ') + ellipsis;
    }
  }
}
</script>

<style lang="scss" scoped>
.post-summary {

  p {
    margin: 0;
    padding: 0;
  }
}
</style>