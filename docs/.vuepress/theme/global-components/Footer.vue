<template>
  <footer class="page-footer">

    <div class="cncf-banner">
      <h4>{{ getSiteData.title }} is a CNCF Sandbox project</h4>
      <img src="/images/CNCF_Alternate_Pantone.png" alt="Cloud Native Computing Foundation Logo">
      <br>
      <p>Kuma was originally created by <a href="https://konghq.com/">Kong, Inc.</a> and made successful by its open <a href="/community">community</a>.</p>
    </div>
    
    <!-- .page-footer__links -->

    <div class="page-footer__sublinks">
      <div class="inner flex flex-wrap -mx-2">

        <div class="copyright-wrap w-full md:w-3/4 px-2">
          <ul>
            <li v-if="copyright" class="copyright">&copy; {{ copyright }}</li>
            <li v-for="(item, index) in subLinks" :key="index">
              <a :href="item.url">{{ item.label }}</a>
            </li>
          </ul>
        </div>
        <!-- .copyright-wrap -->

        <div class="social-links w-full md:w-1/4 px-2">
          <ul>
            <li v-for="(item, index) in socialLinks" :key="index">
              <a :href="item.url">
                <img :src="socialIconPath + item.icon" :alt="item.label">
                <span class="sr-only">{{ item.label }}</span>
              </a>
            </li>
            <li>
              <GithubButton
                v-if="getSiteData.themeConfig.repo"
                :href="getSiteData.themeConfig.repo"
                class="repo-button"
                data-icon="octicon-star"
                data-size="small"
                data-show-count="false"
                aria-label="Star Konvoy on GitHub"
              >
                {{
                  getSiteData.themeConfig.repoButtonLabel 
                    ? getSiteData.themeConfig.repoButtonLabel 
                    : 'Star'
                }}
              </GithubButton>
            </li>
          </ul>
        </div>
        <!-- .social-links -->

      </div>
    </div>
    <!-- .page-footer__sublinks -->

  </footer>
</template>

<script>
import GithubButton from 'vue-github-button'

export default {
  data() {
    return {
      copyright: `Copyright The Kuma Authors.`,
      links: [
        {
          group: 'Community',
          items: [
            { label: 'GitHub', url: 'https://github.com/kumahq/kuma' },
            { label: 'Slack', url: 'https://chat.kuma.io/' },
            { label: 'Twitter', url: 'https://twitter.com/kumamesh' }
          ]
        }
      ],
      subLinks: [
        { label: 'Code Of Conduct', url: 'https://github.com/kumahq/kuma/blob/master/CODE_OF_CONDUCT.md' }
      ],
      socialIconPath: '/images/social/',
      socialIconSize: 16, // in px
      socialLinks: [
        // { label: 'Facebook', icon: 'icon-facebook.svg', url: '#' },
        { label: 'Twitter', icon: 'icon-twitter.svg', url: 'https://twitter.com/KumaMesh' },
        { label: 'Meetup', icon: 'icon-meetup.svg', url: 'https://www.meetup.com/members/121234612/' },
        { label: 'Github', icon: 'icon-github.svg', url: 'https://github.com/kumahq/kuma' }
      ]
    }
  },
  components: {
    GithubButton
  }
}
</script>