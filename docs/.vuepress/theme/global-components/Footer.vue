<template>
  <footer class="page-footer">
    
    <div class="page-footer__links">
      <div class="inner flex flex-wrap -mx-2">
        <div v-for="(link, index) in links" :key="index" class="w-full sm:w-1/2 md:w-1/4 px-2">
          <ul>
            <li><h5>{{ link.group }}</h5></li>
            <li v-for="(item, index) in link.items">
              <a :href="item.url" :class="{ 'badge-wrap': ( item.badge === true ) }">
                {{ item.label }} <span v-if="item.badge && item.badgeText" class="badge">{{ item.badgeText }}</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
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
      copyright: `Kong, Inc. ${new Date().getFullYear()}`,
      links: [
        {
          group: 'Products',
          items: [
            { label: 'Kong', url: 'https://konghq.com/' },
            { label: 'Kong Enterprise', url: 'https://konghq.com/kong-enterprise/' },
            { label: 'Kong Cloud', url: 'https://konghq.com/cloud/' },
            { label: 'Subscriptions', url: 'https://konghq.com/subscriptions/' }
          ]
        },
        {
          group: 'Resources',
          items: [
            // { label: 'Enterprise Support', url: '#' },
            { label: 'Documentation', url: '/docs/' },
            { label: 'Partners', url: 'https://konghq.com/partners/' },
            { label: 'Webinars', url: 'https://konghq.com/webinars/' },
            { label: 'Ebooks', url: 'https://konghq.com/ebooks/' },
            { label: 'Meetups', url: 'https://www.meetup.com/members/121234612/' }
          ]
        },
        {
          group: 'Company',
          items: [
            { label: 'About', url: 'https://konghq.com/about-kong-inc/' },
            { label: 'Investors', url: 'https://konghq.com/investors/' },
            { label: 'News', url: 'https://konghq.com/press-room/' },
            {
              label: 'Careers',
              url: 'https://konghq.com/careers/',
              badge: true,
              badgeText: 'Hiring!'
            },
            { label: 'Contact', url: 'https://konghq.com/contact/' }
          ]
        },
        {
          group: 'Open Source',
          items: [
            { label: 'Mockbin', url: 'https://mockbin.org/' },
            { label: 'API Embed', url: 'https://apiembed.com/' },
            { label: 'Unirest', url: 'http://unirest.io/' },
            { label: 'Guardian JS', url: 'http://guardianjs.com/' },
            { label: 'OAuth Bible', url: 'http://oauthbible.com/' }
          ]
        }
      ],
      subLinks: [
        { label: 'Terms', url: '/terms/' },
        { label: 'Privacy', url: '/privacy/' },
        // { label: 'Sitemap', url: '#' }
      ],
      socialIconPath: '/images/social/',
      socialIconSize: 16, // in px
      socialLinks: [
        // { label: 'Facebook', icon: 'icon-facebook.svg', url: '#' },
        { label: 'Twitter', icon: 'icon-twitter.svg', url: 'https://twitter.com/KumaMesh' },
        { label: 'Meetup', icon: 'icon-meetup.svg', url: 'https://www.meetup.com/members/121234612/' },
        { label: 'Github', icon: 'icon-github.svg', url: 'https://github.com/kong/kuma' }
      ]
    }
  },
  components: {
    GithubButton
  }
}
</script>