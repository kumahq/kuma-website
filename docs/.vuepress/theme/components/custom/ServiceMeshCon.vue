<template>
  <div class="page-container page-container--servicemeshcon" aria-labelledby="masthead-main-title">
    <div class="page-masthead-wrap smc-gradient">
      <div class="inner flex flex-wrap -mx-4">
        <div class="page-masthead w-full lg:w-1/2 px-4">
          <Content slot-key="masthead" />
        </div>
        <!-- .page-masthead -->
        <div class="page-masthead--right w-full lg:w-1/2 px-4">
          <img :src="$page.frontmatter.eventLogo" class="event-logo" />
        </div>
      </div>
      <!-- .inner -->
    </div>
    <!-- .page-masthead-wrap -->

    <section class="content-block-wrapper content-block-1">
      <div class="inner py-8 flex justify-items-center">
        <Content slot-key="content-block-1" />
      </div>
    </section>

    <section class="content-block-wrapper content-block-2">
      <div class="inner pt-8 flex justify-items-center">
        <Content slot-key="content-block-2" class="centered-headings" />
      </div>
    </section>

    <section class="content-block-wrapper content-block-3">
      <div class="inner py-8">
        <ServiceMeshConForm />
      </div>
    </section>

    <section class="content-block-wrapper content-block-4">
      <div class="inner py-8">
        <Content slot-key="content-block-3" class="centered-text" />
      </div>
    </section>
  </div>
</template>

<script>
import ServiceMeshConForm from '@theme/global-components/ServiceMeshConForm'

export default {
  name: 'ServiceMeshCon',
  components: {
    ServiceMeshConForm
  }
}
</script>

<style lang="scss">
@import '../../styles/custom/config/variables';
@import '../../styles/custom/config/fonts';
@import '../../styles/custom/config/mixins';
@import '../../styles/custom/base/forms';

$smc-gradient: linear-gradient(90deg, #ee751e 0%, #990066 100%);

// put page overrides here
.servicemeshcon {
}

// page container
.page-container--servicemeshcon {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    border: 0;
  }

  a.header-anchor {
    display: none !important;
  }

  .smc-gradient {
    background: $smc-gradient;
    color: #fff;
  }

  .content-block-wrapper {
    .inner {
      max-width: 900px;
    }
  }

  .page-masthead-wrap {
    padding: 3.5rem 0;

    h1,
    h2 {
      color: #fff;
    }

    h1 {
      font-size: 2.4rem;
    }

    h2 {
      font-size: 1.6rem;
    }
  }

  .page-masthead {
    background: none;
    box-shadow: none;
    color: #fff;

    &:before {
      display: none;
    }
  }

  .page-masthead--right {
    display: grid;
    place-items: center;
    text-align: center;
  }

  .event-logo {
    max-width: 80%;
  }

  .content-block-wrapper {
    overflow: hidden;
    font-size: 1.4rem;
  }

  .centered-text {
    text-align: center;
  }

  .centered-headings {
    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      text-align: center;
    }
  }

  .content-block-2,
  .content-block-3 {
    background-color: $pale-blue;
  }

  .content-block-3 {
  }

  .content-block-4 {
    a {
      @extend .btn;
      font-size: 2rem;
      height: auto;
      border-radius: 55px;
    }
  }
}
</style>
