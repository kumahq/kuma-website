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
    installMethods: installMethods,
    requestADemoEndpoint: 'https://script.google.com/macros/s/AKfycbwiFfaiSK6JqdNqZLAt5PRayPV43x7qw1ZAM_-sFSDg6IT44d4/exec',
    newsletterSignupEndpoint: 'https://script.google.com/macros/s/AKfycbx9xikTdHNrrnHiqxNX3ecVkTJYzPmKemrz2OMr6SaOXT7FYaiM/exec',
    newsletterPardotEndpoint: 'https://go.pardot.com/l/392112/2019-09-03/bjz6yv',
    newsletterPardotEndpointDev: 'https://go.pardot.com/l/392112/2020-01-14/bkwzrx',
    communityCallEndpoint: 'https://go.pardot.com/l/392112/2020-02-28/bl766m',
    communityCallAgendaUrl: 'https://tny.sh/NXs6EVO',
    communityCallInvite: '/community-call-invite.ics'
  },

  getters: {
    getInstallMethods: (state) => state.installMethods,
    getReleaseList: (state) => state.releases,
    getLatestRelease: (state) => state.latestRelease,
    getSelectedDocVersion: (state) => state.selectedDocVersion,
    getSelectedInstallVersion: (state) => state.selectedInstallVersion,
    getRequestADemoEndpoint: (state) => state.requestADemoEndpoint,
    getNewsletterSignupEndpoint: (state) => state.newsletterSignupEndpoint,
    getNewsletterPardotEndpoint: (state) => state.newsletterPardotEndpoint,
    getNewsletterPardotEndpointDev: (state) => state.newsletterPardotEndpointDev,
    getCommunityCallSignupEndpoint: (state) => state.communityCallEndpoint,
    getCommunityCallAgendaUrl: (state) => state.communityCallAgendaUrl,
    getCommunityCallInvite: (state) => state.communityCallInvite,
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