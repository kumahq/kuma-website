// Styles
import './theme/global-components/kongponents/packages/styles/styles.scss'
import './theme/styles/custom/styles.scss'

import KAlert from './theme/global-components/kongponents/packages/KAlert'
import KButton from './theme/global-components/kongponents/packages/KButton'
import KCard from './theme/global-components/kongponents/packages/KCard'
import KClipboardProvider from './theme/global-components/kongponents/packages/KClipboardprovider'
import KEmptyState from './theme/global-components/kongponents/packages/KEmptystate'
import KIcon from './theme/global-components/kongponents/packages/KIcon'
import KInput from './theme/global-components/kongponents/packages/KInput'
import KLabel from './theme/global-components/kongponents/packages/KLabel'
import KModal from './theme/global-components/kongponents/packages/KModal'
import KPop from './theme/global-components/kongponents/packages/KPop'
import KTable from './theme/global-components/kongponents/packages/KTable'
import Krumbs from './theme/global-components/kongponents/packages/KRumbs'
import KToaster from './theme/global-components/kongponents/packages/KToaster'

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
}
