<template>
  <div class="page-container page-container--community">

    <PageHeader
      :title="$page.frontmatter.title"
      :subTitle="$page.frontmatter.subTitle"
    />

    <div class="inner">

      <section
        v-if="policies.length > 0"
        v-for="(item, index) in policies"
        class="policy-section"
        :class="`policy-section--${item.section}`"
      >
        <header class="policy-section__header">
          <h2>{{ item.sectionTitle }}</h2>
          <h3>{{ item.sectionSubTitle }}</h3>
        </header>

        <div class="policy-section__item-wrapper">
          <ul class="policy-section__items">
            <li
              v-for="(item, index) in item.items"
              class="policy-section__tile"
            >
              <router-link
                :to="item.url"
                class="policy-section__link"
              >
                <img
                  class="policy-section__icon"
                  srcset="/images/icons/icon-script.png, 
                  /images/icons/icon-script@2x.png 2x"
                  src="/images/icons/icon-script@2x.png"
                  alt="Script Icon"
                >
                <h4>{{ item.title }}</h4>
              </router-link>
            </li>
          </ul>
        </div>

      </section>
      <section
        v-else
        class="policy-section"
      >
        <h2>There are no Policies present.</h2>
      </section>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import PageHeader from '@theme/global-components/PageHeader'
import Card from '@theme/components/custom/Card'

export default {
  components: {
    PageHeader,
    Card
  },
  computed: {
    policies () {
      return this.$page.frontmatter.policies
    }
  }
}
</script>

<style lang="scss">
.policy-section {

  h1, h2, h3, h4, h5, h6 {
    border: 0;
  }
}

.policy-section__items {
  list-style: none;
  padding: 0;
  margin: 0;
}
</style>