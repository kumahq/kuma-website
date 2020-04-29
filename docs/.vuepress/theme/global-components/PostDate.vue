<template>
  <time class="post-date" :datetime="date">
    {{ niceDate }}
  </time>
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