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
          :icon="$page.frontmatter.card1Icon"
          :iconAlt="$page.frontmatter.card1IconAlt"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <Content slot-key="card-1-title"/>
          </template>
          <Content slot-key="card-1-content"/>
        </Card>
      </div>
      <!-- /card 1 -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          :icon="$page.frontmatter.card2Icon"
          :iconAlt="$page.frontmatter.card2IconAlt"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <Content slot-key="card-2-title"/>
          </template>
          <Content slot-key="card-2-content"/>
        </Card>
      </div>
      <!-- /card 2 -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          :icon="$page.frontmatter.card3Icon"
          :iconAlt="$page.frontmatter.card3IconAlt"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <Content slot-key="card-3-title"/>
          </template>
          <Content slot-key="card-3-content"/>
        </Card>
      </div>
      <!-- /card 3 -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          :icon="$page.frontmatter.card4Icon"
          :iconAlt="$page.frontmatter.card4IconAlt"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <Content slot-key="card-4-title"/>
          </template>
          <Content slot-key="card-4-content"/>
        </Card>
      </div>
      <!-- /card 4 -->

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