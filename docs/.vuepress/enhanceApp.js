import Vuex from 'vuex'
import store from './theme/store/index'
// import Layout from './theme/layouts/Layout'

import '@kongponents/styles'
import 'vuepress-plugin-tabs/dist/themes/default.styl'
import './theme/styles/styles.scss'

import VueAnalytics from 'vue-analytics'

export default ({
  Vue,
  isServer,
  router,
  siteData
}) => {

  // setup Vuex
  Vue.use(Vuex)
  
  // setup VueAnalytics for creating GA events and other things
  Vue.use(VueAnalytics, {
    id: siteData.themeConfig.gaCode
  })
  
  /**
   * Global Mixins
   */
  Vue.mixin({
    store: store(siteData.themeConfig.versions, siteData.themeConfig.latestVersion, siteData.themeConfig.installMethods),
    computed: {
      /**
       * Creates an easy way to access site data globally
       */
      getSiteData() {
        return siteData
      },
      /**
       * Get the latest version
       * Good for use in pages, etc.
       */
      latestVersion() {
        return siteData.themeConfig.latestVersion
      }
    }
  })

  /**
   * Creates an aliased route to 'latest'
   * for the Install page. This is not done
   * within `install-route-builder.js` because
   * we need to be able to have an alias on the route
   * and the `additionalPages` feature of VuePress
   * does not allow `alias` on routes.
   */

  router.addRoutes([
    {
      path: '/install/latest/',
      alias: `/install/${siteData.themeConfig.latestVersion}/`,
      name: 'InstallLatest'
    },
    // {
    //   path: '/docs/latest/',
    //   alias: `/docs/${siteData.themeConfig.latestVersion}/`,
    //   name: 'DocsLatest'
    // }    
    {
      path: '/sidecar-injection',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-sidecar-injection"
    },
    {
      path: '/mesh',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-mesh"
    },
    {
      path: '/gateway',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-gateway"
    },
    {
      path: '/ingress',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-ingress"
    },
    {
      path: '/ingress-public-address',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-ingress-public-address"
    },
    {
      path: '/ingress-public-port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-ingress-public-port"
    },
    {
      path: '/direct-access-services',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-direct-access-services"
    },
    {
      path: '/virtual-probes',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-virtual-probes"
    },
    {
      path: '/virtual-probes-port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-virtual-probes-port"
    },
    {
      path: '/sidecar-env-vars',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-sidecar-env-vars"
    },
    {
      path: '/container-patches',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-container-patches"
    },
    {
      path: 'prometheus.metrics.kuma.io/port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#prometheus-metrics-kuma-io-port"
    },
    {
      path: 'prometheus.metrics.kuma.io/path',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#prometheus-metrics-kuma-io-path"
    },
    {
      path: '/builtindns',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-builtindns"
    },
    {
      path: '/builtindnsport',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-builtindnsport"
    },
    {
      path: '/ignore',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-ignore"
    },
    {
      path: 'traffic.kuma.io/exclude-inbound-ports',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#traffic-kuma-io-exclude-inbound-ports"
    },
    {
      path: 'traffic.kuma.io/exclude-outbound-ports',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#traffic-kuma-io-exclude-outbound-ports"
    },
    {
      path: '/transparent-proxying-experimental-engine',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-transparent-proxying-experimental-engine"
    },
    {
      path: '/envoy-admin-port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-envoy-admin-port"
    },
    {
      path: '/service-account-token-volume',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-service-account-token-volume"
    },
    {
      path: '/transparent-proxying-reachable-services',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-transparent-proxying-reachable-services"
    },
    {
      path: 'prometheus.metrics.kuma.io/aggregate-<name>-enabled',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#prometheus-metrics-kuma-io-aggregate-name-enabled"
    },
    {
      path: 'prometheus.metrics.kuma.io/aggregate-<name>-path',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#prometheus-metrics-kuma-io-aggregate-name-path"
    },
    {
      path: 'prometheus.metrics.kuma.io/aggregate-<name>-port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#prometheus-metrics-kuma-io-aggregate-name-port"
    },
    {
      path: '/transparent-proxying-inbound-v6-port',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-transparent-proxying-inbound-v6-port"
    },
    {
      path: '/sidecar-drain-time',
      redirect: "https://kuma.io/docs/1.8.x/reference/kubernetes-annotations/#kuma-io-sidecar-drain-time"
    }
  ])
}
