<template>
  <div class="page-container page-container--community">

    <PageHeader
      :title="$page.frontmatter.title"
      :subTitle="$page.frontmatter.subTitle"
    />

    <div class="inner flex flex-wrap items-stretch -mx-4">

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
          <ul class="inline-list">
            <li>
              <a href="https://tny.sh/NXs6EVO" target="_blank">
                <span class="icon">📝</span>  Agenda
              </a>
            </li>
            <li>
              <a href="https://www.youtube.com/playlist?list=PLg_AhYkg50viOMrea6Nm3t9JCempVyLcj" target="_blank">
                <span class="icon">🎥</span> Past Recordings
              </a>
            </li>
          </ul>
          <div class="community-form">
            <CommunityCallForm />
          </div>
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
import PageHeader from '@theme/global-components/PageHeader'
import Card from '@theme/components/custom/Card'
import CommunityCallForm from '@theme/global-components/CommunityCallForm'

export default {
  components: {
    PageHeader,
    Card,
    CommunityCallForm
  }
}
</script>

<style lang="scss" scoped>
.community-form {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #ccc;
}

.inline-list {
  display: block;
  overflow: hidden;
  list-style: none;
  margin: 10px 0 0 0 !important;
  padding: 0;

  li {
    display: inline-block;

  &:not(:last-of-type) {
     border-right: 1px solid #ccc;
     margin-right: 8px;
     padding-right: 10px;
   }
  }

  a {
    display: block;
  }

  .icon {
    display: inline-block;
    margin: 0 5px 0 0;
  }
}
</style>