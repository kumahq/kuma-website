import Vue from 'vue'
import Vuex from 'vuex'
import toSemver from 'to-semver'
import latestSemver from 'latest-semver'
import releases from '../../public/releases.json'
import installMethods from '../../public/install-methods.json'

Vue.use(Vuex)

// storing the latest version since we use it often
let latestRelease = latestSemver(releases)

export default new Vuex.Store({
  state: {
    releases: toSemver(releases),
    latestRelease: latestRelease,
    selectedDocVersion: latestRelease,
    selectedInstallVersion: latestRelease,
    installMethods: installMethods,
    requestADemoEndpoint:
      'https://script.google.com/macros/s/AKfycbwiFfaiSK6JqdNqZLAt5PRayPV43x7qw1ZAM_-sFSDg6IT44d4/exec' /** not currently in use */,
    communityCallAgendaUrl: 'https://tny.sh/NXs6EVO',
    communityCallInvite:
      'https://calendar.google.com/calendar?cid=a29uZ2hxLmNvbV8xbWE5NnNzZGdnZmg5ZnJyY3M5N2VwdTM4b0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t'
  },

  getters: {
    /** documentation functionality */
    getInstallMethods: (state) => state.installMethods,
    getReleaseList: (state) => state.releases,
    getLatestRelease: (state) => state.latestRelease,
    getSelectedDocVersion: (state) => state.selectedDocVersion,
    getSelectedInstallVersion: (state) => state.selectedInstallVersion,

    /** form endpoints */
    getRequestADemoEndpoint: (state) => state.requestADemoEndpoint,
    getNewsletterFormEndpoint: () => {
      if (process.env.NODE_ENV === 'production') {
        return 'https://go.pardot.com/l/392112/2019-09-03/bjz6yv'
      } else {
        return 'https://go.pardot.com/l/392112/2020-01-14/bkwzrx'
      }
    },
    getInstallPageNewsletterFormEndpoint: () => {
      return 'https://go.pardot.com/l/392112/2021-01-21/bp22j3'
    },
    getCommunityCallFormEndpoint: () => {
      if (process.env.NODE_ENV === 'production') {
        return 'https://go.pardot.com/l/392112/2020-02-28/bl766m'
      } else {
        return 'https://go.pardot.com/l/392112/2020-07-09/bmmgqv'
      }
    },

    getServiceMeshConFormEndpoint: () => {
      return 'https://go.konghq.com/l/392112/2020-11-16/bnlpqv'
    },

    /** community call */
    getCommunityCallAgendaUrl: (state) => state.communityCallAgendaUrl,
    getCommunityCallInvite: (state) => state.communityCallInvite,

    /** version releases as vue-router links */
    releasesAsRouterLinks: (state) => {
      return state.releases.map((tag) => ({
        text: tag === state.latestRelease ? `${tag} (latest)` : tag,
        type: 'link',
        link: `/docs/${tag}/`
      }))
    },

    /** version releases as <select> menu values/options */
    releasesAsSelectValues: (state) => {
      return state.releases.map((tag) => ({
        version: tag,
        text: tag === state.latestRelease ? `${tag} (latest)` : tag
      }))
    }
  },

  actions: {},

  mutations: {
    updateSelectedDocVersion: (state, payload) => (state.selectedDocVersion = payload),
    updateSelectedInstallVersion: (state, payload) => (state.selectedInstallVersion = payload)
  }
})
