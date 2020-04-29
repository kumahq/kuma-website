<template>
  <div class="page-container page-container--policies">

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
        :id="`policies-${item.section}`"
      >
        <header class="policy-section__header">
          <h2>{{ item.sectionTitle }}</h2>
          <h3>{{ item.sectionSubTitle }}</h3>
        </header>

        <div class="policy-section__item-wrapper">
          <ul class="policy-section__items flex flex-wrap -mx-4">
            <li
              v-for="(item, index) in item.items"
              class="policy-section__tile w-full sm:w-1/2 md:w-1/3 mb-4 px-4"
            >
              <a
                :href="item.url"
                class="policy-section__link"
              >
                <div class="policy-section__link-content">
                  <img
                    class="policy-section__icon"
                    :src="item.icon ? item.icon : '/images/icons/icon-script@2x.png'"
                    :alt="`Policy icon for ${item.title}`"
                  >
                  <h4 v-if="item.title">
                    {{ item.title }}
                  </h4>
                  <h4 v-else>
                    <strong>Please add a title for this policy.</strong>
                  </h4>
                </div>
              </a>
            </li>
          </ul>
        </div>

      </section>
      <section
        v-else
        class="policy-section policy-section--no-items"
      >
        <h2>There are no Policies present.</h2>
      </section>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
import PageHeader from '@theme/global-components/PageHeader'

export default {
  components: {
    PageHeader
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
  max-width: 33.75rem;
  margin-left: auto;
  margin-right: auto;

  h1, h2, h3, h4, h5, h6 {
    border: 0;
  }
}

.policy-section--no-items {
  text-align: center;
}

.policy-section__header {

  h2, h3 {
    margin: 0;
    padding: 0;
  }

  h2 {
    font-size: 1.1875rem;
    color: rgba(#000, 0.85);
    margin-bottom: 0.8rem;
  }

  h3 {
    font-size: 0.9375rem;
    color: rgba(#000, 0.70);
  }
}

.policy-section__items {
  list-style: none;
  padding: 0;
  margin-top: 1.25rem;
  margin-bottom: 1.25rem;
}

.policy-section__tile {
  text-align: center;
}

.policy-section__link {
  $hover-color: #3fa66a;
  $cubic-bezier: cubic-bezier(0.47, 0.37, 0.36, 0.92);

  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 8rem;
  background-color: #fff;
  // border: 1px solid #c6cfd7;
  box-shadow: 0 0 1px 1px #c6cfd7;
  border-radius: 5px;
  padding: 1.4375rem 0.5rem;
  // will-change: transform;
  // transform-origin: center;
  // transform: translateZ(0);
  transition: 
    color 200ms $cubic-bezier, 
    box-shadow 200ms $cubic-bezier, 
    transform 200ms $cubic-bezier;

  &:hover, &:active {
    transform: scale(1.05);
    // border-color: $hover-color;
    box-shadow: 0 0 1px 1px $hover-color;
    color: $hover-color;

    h4 {
      color: $hover-color;
    }
  }

  h4 {
    padding: 0;
    margin: 0;
    font-size: 0.9375rem;
    font-weight: 200;
    color: rgba(#000, 0.70);
    line-height: 1.5rem;
    transition: color 200ms $cubic-bezier;
  }
}

.policy-section__icon {
  max-width: 2.0625rem;
  height: auto;
  margin: 0 auto 0.8rem auto;
}
</style>