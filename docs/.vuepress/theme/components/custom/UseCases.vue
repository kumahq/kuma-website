<template>
  <div class="page-container page-container--community">

    <header v-if="$page.frontmatter.title" class="page-header text-center bg-gradient">
      <div class="inner">
        <h1>{{ $page.frontmatter.title }}</h1>
        <p v-if="$page.frontmatter.title" class="page-sub-title">{{ $page.frontmatter.subTitle }}</p>
      </div>
      <!-- .inner -->
    </header>
    <!-- .page-header -->

    <div class="inner">

      <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Error esse architecto optio ea cupiditate porro ut nobis natus, aut iusto enim aperiam earum, quidem minima quos, quis exercitationem ullam obcaecati.</p>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
export default {
  
}
</script>

<style lang="scss">

</style>