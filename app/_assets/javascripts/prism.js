import Prism from 'prismjs'

import 'prismjs/components/prism-bash.js'
import 'prismjs/components/prism-systemd.js'
import 'prismjs/components/prism-yaml.js'
import 'prismjs/components/prism-json.js'
import 'prismjs/plugins/autoloader/prism-autoloader.js'
import 'prismjs/plugins/line-numbers/prism-line-numbers.js'
import 'prismjs/plugins/toolbar/prism-toolbar.js'
import 'prismjs/plugins/copy-to-clipboard/prism-copy-to-clipboard.js'
// styles
import 'prismjs/themes/prism.css'
import 'prismjs/plugins/line-numbers/prism-line-numbers.css'
import 'prismjs/plugins/toolbar/prism-toolbar.css'
import '@/styles/prismjs/prism-vs.scss'

Prism.highlightAll();

const icon = `
<span>
  <svg data-v-49140617="" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" class="hover">
    <path data-v-49140617="" fill="none" d="M0 0h24v24H0z"></path>
    <path data-v-49140617="" fill="#4e1999" d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm-1 4l6 6v10c0 1.1-.9 2-2 2H7.99C6.89 23 6 22.1 6 21l.01-14c0-1.1.89-2 1.99-2h7zm-1 7h5.5L14 6.5V12z"></path>
  </svg>
</span>
<span>Copied!</span>
`;

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.copy-to-clipboard-button').forEach((elem) => {
    elem.innerHTML = icon;
  });
});
