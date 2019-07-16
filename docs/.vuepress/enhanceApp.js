// Globally import all Kongponents
import KAlert from './theme/components/kongponents/packages/KAlert'
import KButton from './theme/components/kongponents/packages/kbutton'
import KCard from './theme/components/kongponents/packages/kcard'
import KClipboardProvider from './theme/components/kongponents/packages/kclipboardprovider'
import KEmptyState from './theme/components/kongponents/packages/kemptystate'
import KIcon from './theme/components/kongponents/packages/kicon'
import KModal from './theme/components/kongponents/packages/kmodal'
import KPop from './theme/components/kongponents/packages/kpop'
import Krumbs from './theme/components/kongponents/packages/krumbs'
import KTable from './theme/components/kongponents/packages/ktable'
import KToaster from './theme/components/kongponents/packages/ktoaster'
import KLabel from './theme/components/kongponents/packages/klabel'
import KInput from './theme/components/kongponents/packages/kinput'

// Kongponents styles
import KStyles from './theme/components/kongponents/packages/styles/styles.scss'

// Custom theme styles
import Styles from './theme/styles/custom/styles.scss'

export default ({
  Vue,
  options,
  router,
  siteData
}) => {

  // Site styles (Tailwind CSS is included via `postcss.config.js`)
  Vue.use(Styles),
  Vue.use(KStyles),

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
}
