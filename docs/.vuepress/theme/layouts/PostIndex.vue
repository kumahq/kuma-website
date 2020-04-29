<template>
  <BlogIndex
    :page-sub-title="`Stay up to date on the latest ${getSiteData.title} news.`"
  />
</template>

<script>
import BlogIndex from '@theme/layouts/BlogIndex'

export default {
  components: {
    BlogIndex
  }
}
</script>

<style>

</style>