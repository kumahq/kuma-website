// Various libraries
import LatestSemver from 'latest-semver'
import ToSemver from 'to-semver'

// Styles
import '@kongponents/styles'
import './theme/styles/custom/styles.scss'

// Releases
import releases from './public/releases.json'

// Globally import all Kongponents
import KAlert from '@kongponents/kalert'
import KButton from '@kongponents/kbutton'
import KCard from '@kongponents/kcard'
import KClipboardProvider from '@kongponents/kclipboardprovider'
import KEmptyState from '@kongponents/kemptystate'
import KIcon from '@kongponents/kicon'
import KModal from '@kongponents/kmodal'
import KPop from '@kongponents/kpop'
import Krumbs from '@kongponents/krumbs'
import KTable from '@kongponents/ktable'
import KToaster from '@kongponents/ktoaster'
import KLabel from '@kongponents/klabel'
import KInput from '@kongponents/kinput'

export default ({
  Vue,
  options,
  router,
  siteData
}) => {
  // Kongponents
  Vue.component('KAlert', KAlert)
  Vue.component('KModal', KModal)
  Vue.component('KButton', KButton)
  Vue.component('KCard', KCard)
  Vue.component('KEmptyState', KEmptyState)
  Vue.component('KIcon', KIcon)
  Vue.component('KTable', KTable)
  Vue.component('KToaster', KToaster)
  Vue.component('KPop', KPop)
  Vue.component('KClipboardProvider', KClipboardProvider)
  Vue.component('Krumbs', Krumbs)
  Vue.component('KLabel', KLabel)
  Vue.component('KInput', KInput)

  Vue.mixin({
    computed: {
      getSiteData() {
        return siteData
      }
    }
  })

  /**
   * Install page route handling
   */
  Vue.mixin({
    beforeRouteEnter (to, from, next){
      const latest = LatestSemver(releases)
      const routePath = to.path

      // if the destination route is the install page
      // modify the url with the latest version
      // and continue forward
      // if ( routePath === '/install/' ) {
      //   next({
      //     path: `/install/${latest}/`,
      //     params: {
      //       test: latest
      //     }
      //   })
      // } else {
      //   // otherwise continue on as normal
      //   next()
      // }

      console.log(to)
   },
  })
}
