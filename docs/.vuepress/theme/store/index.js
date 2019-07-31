import Vue from 'vue'
import Vuex from 'vuex'
import ToSemver from 'to-semver'
import LatestSemver from 'latest-semver'
import releases from '../../public/releases.json'
import installMethods from '../../public/install-methods.json'

Vue.use(Vuex)

// storing the latest version since we use it often
let latestRelease = LatestSemver(releases)

export default new Vuex.Store({
  state: {
    releases: ToSemver(releases),
    latestRelease: latestRelease,
    selectedDocVersion: latestRelease,
    selectedInstallVersion: latestRelease,
    installMethods: installMethods
  },

  getters: {
    getInstallMethods: (state) => state.installMethods,
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
    },
    releasesAsSelectValues: (state) => {
      return state.releases.map( tag => ({
        version: tag,
        text: tag === state.latestRelease ? `${tag} (latest)` : tag
      }))
    }
  },

  actions: {},

  mutations: {
    updateSelectedDocVersion: (state, payload) => state.selectedDocVersion = payload,
    updateSelectedInstallVersion: (state, payload) => state.selectedInstallVersion = payload
  }
})