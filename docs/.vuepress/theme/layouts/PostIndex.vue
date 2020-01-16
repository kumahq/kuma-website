<template>
  <Shell
    class="blog-page blog-page--post-index"
  >
    <template slot="page-content">
      <main class="page">
        <div class="theme-default-content content__default">
          <ul id="default-layout">
            <li v-for="page in $pagination.pages">
              <router-link class="page-link" :to="page.path">{{ page.title }}</router-link>
            </li>
          </ul>
          <div id="pagination">
            <router-link v-if="$pagination.hasPrev" :to="$pagination.prevLink">Prev</router-link>
            <router-link v-if="$pagination.hasNext" :to="$pagination.nextLink">Next</router-link>
          </div>
        </div>
      </main>
    </template>
  </Shell>
</template>


<script>
export default {

}
</script>

<style>

</style>