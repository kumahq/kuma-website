import Vue from 'vue'
import Vuex from 'vuex'
import ToSemver from 'to-semver'
import LatestSemver from 'latest-semver'
import releases from '../../public/releases.json'

Vue.use(Vuex)

// storing the latest version since we use it often
const latestRelease = LatestSemver(releases)

export default new Vuex.Store({
  state: {
    releases: ToSemver(releases),
    latestRelease: latestRelease,
    selectedDocVersion: latestRelease,
    selectedInstallVersion: latestRelease
  },

  getters: {
    getReleaseList: (state) => state.releases,
    getLatestRelease: (state) => state.latestRelease,
    getSelectedDocVersion: (state) => state.selectedDocVersion,
    getSelectedInstallVersion: (state) => state.selectedInstallVersion,
    releasesAsRouterLinks: (state) => {
      return state.releases.map( tag => ({
        text: tag === state.latestRelease ? `${tag} (latest)` : tag,
        type: 'link',
        link: `/docs/${tag}/`
      }))
    }
  },

  actions: {},

  mutations: {
    updateSelectedDocVersion: (state, payload) => state.selectedDocVersion = payload,
    updateSelectedInstallVersion: (state, payload) => state.selectedInstallVersion = payload
  }
})