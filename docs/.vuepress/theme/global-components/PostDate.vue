<template>
  <div class="post-date">
    <time :datetime="date">
      {{ niceDate }}
    </time>
  </div>
</template>

<script>
import { format } from 'date-fns'

export default {
  props: {
    date: {
      type: String,
      required: true
    },
    format: {
      type: String,
      required: false,
      default: 'PPP' // January 1st, 2020
    }
  },
  computed: {
    niceDate () {
      const dateFormat = this.format
      const newDate = new Date(this.date)
      return format( newDate, dateFormat )
    }
  }
}
</script>

<style lang="scss" scoped>
.post-date {
  font-size: var(--type-sm);
  color: var(--tblack-70);
}
</style>