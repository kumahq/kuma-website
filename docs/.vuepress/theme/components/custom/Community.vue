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
          iconAlt="Github logo icon"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Github</h3>
          </template>
          <p>Contribute and explore Kuma at the <a href="https://github.com/Kong/kuma">official GitHub repository</a>. Here is where all the coding happens. Feel free to ask questions, submit PRs and open issues.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-slack.svg"
          iconAlt="Slack logo icon"
          :iconWidth="48"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Slack</h3>
          </template>
          <p><a href="https://chat.kuma.io">Join </a> the official community Slack chat where the community
             can discuss and ask questions in real-time. If you have already joined, go directly to the <a href="https://kuma-mesh.slack.com">Kuma Workspace</a>.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-community-call.svg"
          iconAlt="Community call icon"
          :iconWidth="48"
          :iconHeight="37"
        >
          <template slot="card-title">
            <h3>Community Call</h3>
          </template>
          <p>Kuma hosts official monthly community calls where users and contributors can
             discuss about any topic and demonstrate use-cases. <a href="#">Join the next call</a>.</p>
        </Card>
      </div>
      <!-- /card -->

      <div class="w-full sm:w-1/2 mb-8 px-4">
        <Card
          icon="/images/icons/icon-meetup.svg"
          iconAlt="Meetup logo icon"
          :iconWidth="50"
          :iconHeight="48"
        >
          <template slot="card-title">
            <h3>Meetups</h3>
          </template>
          <p>Join Kuma meetups all around the world where the community can
             meet in person, practice together and learn from each other. <a href="#">Explore meetups</a>.</p>
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