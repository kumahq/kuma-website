<template>
  <time class="post-date" :datetime="fixedDate">
    {{ niceDate }}
  </time>
</template>

<script>
import dayjs from 'dayjs'

export default {
  props: {
    date: {
      type: String,
      required: true
    },
    format: {
      type: String,
      required: false,
      default: 'MMM DD, YYYY'
    }
  },
  computed: {
    fixedDate () {
      const rawDate = new Date(this.date)
      const fixedDate = new Date(
        rawDate.getTime() 
        + rawDate.getTimezoneOffset() 
        * 60000
      ).toISOString()

      return fixedDate
    },
    niceDate () {
      const newDate = dayjs(this.fixedDate).format(this.format)

      return newDate
    }
  }
}
</script>