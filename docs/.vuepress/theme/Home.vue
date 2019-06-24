<template>
  <div class="theme-container theme-container--home">
    <header>
      <Content slot-key="header"/>
    </header>
    <main>
      <Content/>
    </main>
    <footer>
      <Content slot-key="footer"/>
    </footer>
  </div>
</template>

<script>
export default {
  
}
</script>

<style lang="scss">
// this is temporary for testing (prevents the homepage title from going
// under the top navbar)
.theme-container--home {
  padding-top: 3.6rem;
}
</style>

