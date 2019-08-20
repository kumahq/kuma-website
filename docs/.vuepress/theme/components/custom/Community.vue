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

    <div class="inner flex flex-wrap -mx-4">

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-github.svg"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Github Issues</h3>
          </template>
          <p>If you've come across what you think is a bug, or just want to 
            make a feature request open a ticket in the <a href="#">issue queue</a>.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-slack.svg"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Github Issues</h3>
          </template>
          <p>If you've come across what you think is a bug, or just want to 
            make a feature request open a ticket in the <a href="#">issue queue</a>.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-community-call.svg"
          :iconWidth="48"
          :iconHeight="37"
        >
          <template slot="card-title">
            <h3>Github Issues</h3>
          </template>
          <p>If you've come across what you think is a bug, or just want to 
            make a feature request open a ticket in the <a href="#">issue queue</a>.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-meetup.svg"
          :iconWidth="50"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Github Issues</h3>
          </template>
          <p>If you've come across what you think is a bug, or just want to 
            make a feature request open a ticket in the <a href="#">issue queue</a>.</p>
        </Card>
      </div>
      <!-- /card -->

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import Card from '@theme/components/custom/Card'

export default {
  components: {
    Card
  }
}
</script>

<style lang="scss">

</style>