// Get base stylesheet
import '@kongponents/styles'

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

// our custom theme styles
import Styles from './theme/styles/custom/styles.scss'

export default ({
  Vue,
  options,
  router,
  siteData
}) => {

  // Site styles (Tailwind CSS is included via `postcss.config.js`)
  Vue.use(Styles),

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
