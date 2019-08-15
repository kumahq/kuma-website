<template>
  <footer class="page-footer">
    
    <div class="page-footer__links">
      <div class="inner flex flex-wrap -mx-2">
        <div class="w-full sm:w-1/2 md:w-1/4 px-2">
          <ul>
            <li><h5>Products</h5></li>
            <li><a href="#">Kong</a></li>
            <li><a href="#">Kong Enterprise</a></li>
            <li><a href="#">Kong Cloud</a></li>
            <li><a href="#">Subscriptions</a></li>
          </ul>
        </div>
        <div class="w-full sm:w-1/2 md:w-1/4 px-2">
          <ul>
            <li><h5>Resources</h5></li>
            <li><a href="#">Enterprise Support</a></li>
            <li><a href="#">Documentation</a></li>
            <li><a href="#">Partners</a></li>
            <li><a href="#">Webinars</a></li>
            <li><a href="#">Ebooks</a></li>
            <li><a href="#">Meetups</a></li>
          </ul>
        </div>
        <div class="w-full sm:w-1/2 md:w-1/4 px-2">
          <ul>
            <li><h5>Company</h5></li>
            <li><a href="#">About</a></li>
            <li><a href="#">Investors</a></li>
            <li><a href="#">News</a></li>
            <li>
              <a href="#" class="badge-wrap">
                Careers <span class="badge">Hiring!</span>
              </a>
            </li>
            <li><a href="#">Contact</a></li>
          </ul>
        </div>
        <div class="w-full sm:w-1/2 md:w-1/4 px-2">
          <ul>
            <li><h5>Open Source</h5></li>
            <li><a href="#">Mockbin</a></li>
            <li><a href="#">API Embed</a></li>
            <li><a href="#">Unirest</a></li>
            <li><a href="#">Guardian JS</a></li>
            <li><a href="#">OAuth Bible</a></li>
          </ul>
        </div>
      </div>
    </div>

    <div class="page-footer__sublinks">
      <div class="inner flex flex-wrap -mx-2">
        <div class="w-full md:w-3/4 px-2">
          <ul>
            <li class="copyright">&copy; Kong, Inc. {{new Date().getFullYear()}}</li>
            <li><a href="#">Terms</a></li>
            <li><a href="#">Privacy</a></li>
            <li><a href="#">Sitemap</a></li>
          </ul>
        </div>
        <div class="social-links w-full md:w-1/4 px-2">
          <ul>
            <li>
              <a href="#">
                <InlineSvg
                  src="/images/social/icon-facebook.svg"
                  width="16"
                  height="16"
                />
                <span class="sr-only">Facebook</span>
              </a>
            </li>
            <li>
              <a href="#">
                <InlineSvg
                  src="/images/social/icon-twitter.svg"
                  width="16"
                  height="16"
                />
                <span class="sr-only">Twitter</span>
              </a>
            </li>
            <li>
              <a href="#">
                <InlineSvg
                  src="/images/social/icon-meetup.svg"
                  width="16"
                  height="16"
                />
                <span class="sr-only">Meetup</span>
              </a>
            </li>
            <li>
              <a href="#">
                <InlineSvg
                  src="/images/social/icon-github.svg"
                  width="16"
                  height="16"
                />
                <span class="sr-only">Github</span>
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
      </div>
    </div>

  </footer>
</template>

<script>
import GithubButton from 'vue-github-button'

export default {
  components: {
    GithubButton
  }  
}
</script>