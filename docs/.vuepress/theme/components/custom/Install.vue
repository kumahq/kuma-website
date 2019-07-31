<template>
  <div class="theme-container theme-container--install">

    <header class="page-header">
      <h1>Install {{$site.title}}</h1>
      
      <div v-if="this.getInstallMethods && this.getInstallMethods.length" class="version-selector-wrapper">
        <form>
          <select name="install-version-selector" @change="updateInstallPath($event.target.value)">
            <option 
              v-for="tag in releasesAsSelectValues" 
              :value="tag.version" 
              :key="tag.version" 
              :selected='getSelectedInstallVersion === tag'
            >
              {{tag.text}}
            </option>
          </select>
        </form>

        <div v-if="getSelectedInstallVersion">
          <p>You are viewing installation instructions for <strong>{{getSelectedInstallVersion}}</strong>.</p>
        </div>

      </div>
    </header>

    <div v-if="this.getInstallMethods" class="install-methods-wrapper">
      <ul class="install-methods">
        <li v-for="(item, index) in getInstallMethods" :key="index" class="install-methods__item">
          <router-link :to='`/${getSiteData.themeConfig.docsDir}/${getSelectedInstallVersion}/installation-guide/#${item.slug}`'>
            <img :src="item.logo" class="install-methods__item-logo">
            <h3 class="install-methods__item-title">{{item.label}}</h3>
          </router-link>
        </li>
      </ul>
    </div>

    <div v-else class="install-methods-wrapper">
      <p><strong>No install methods defined!</strong></p>
    </div>
    
  </div>
</template>

<script>
import { mapGetters, mapMutations } from 'vuex'

export default {
  name: 'Install',
  methods: {

    ...mapMutations([
      'updateSelectedDocVersion'
    ]),

    updateInstallPath(ev) {
      // update the version accordingly in the UI when the
      // user switches to a different version

      // set the updated install version in the store
      this.$store.commit('updateSelectedInstallVersion', ev)

      // change the URL to reflect the version change
      this.$router.push({
        path: `/install/${ev}`,
        meta: {
          version: ev
        }
      })
    },

    mapVersionMetaToInstallVersion() {
      const metaValue = this.$route.meta.version
      if ( metaValue ) {
        this.$store.commit('updateSelectedInstallVersion', metaValue)
      }
    },

    redirectToLatestVersion() {
      if ( !this.$route.meta.version || this.$route.path === '/install/' ) {
        // redirect to the latest release route
        this.$router.push({
          path: `/install/${this.getLatestRelease}/`,
          meta: {
            version: this.getLatestRelease
          }
        })
      }
    }

  },
  computed: {
    ...mapGetters([
      'getInstallMethods',
      'getReleaseList',
      'getLatestRelease',
      'getSelectedInstallVersion',
      'releasesAsSelectValues'
    ])
  },
  watch: {
    // this ensures that the user is always on the latest version
    // in case they are on the Install page and happen to navigate
    // to it again via the main nav (which sends them to the bare
    // path without a version appended)
    $route (to, from) {
      this.redirectToLatestVersion()
      this.mapVersionMetaToInstallVersion()
    }
  },
  beforeMount() {
    this.redirectToLatestVersion()
    this.mapVersionMetaToInstallVersion()
  }
};
</script>

<style lang="scss" scoped>
.page-header {
  text-align: center;
}

// temp styles grabbed from here https://www.filamentgroup.com/lab/select-css.html
select {
	// display: block;
	font-size: 16px;
	font-family: sans-serif;
	font-weight: 700;
	color: #444;
	line-height: 1.3;
	padding: .6em 1.4em .5em .8em;
	// width: 100%;
	max-width: 100%;
	box-sizing: border-box;
	margin: 0;
	border: 1px solid #aaa;
	box-shadow: 0 1px 0 1px rgba(0,0,0,.04);
	border-radius: .5em;
	-moz-appearance: none;
	-webkit-appearance: none;
	appearance: none;
	background-color: #fff;
	background-image: url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%23007CB2%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5-1.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E'),
	  linear-gradient(to bottom, #ffffff 0%,#e5e5e5 100%);
	background-repeat: no-repeat, repeat;
	background-position: right .7em top 50%, 0 0;
	background-size: .65em auto, 100%;
}

select::-ms-expand {
	display: none;
}

select:hover {
	border-color: #888;
}

select:focus {
	border-color: #aaa;
	box-shadow: 0 0 1px 3px rgba(59, 153, 252, .7);
	box-shadow: 0 0 0 3px -moz-mac-focusring;
	color: #222;
	outline: none;
}

select option {
	font-weight:normal;
}
</style>
