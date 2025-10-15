// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from '../vendor/topbar'

// Import hooks
import AdminChart from './hooks/admin_chart'
import ChatInput from './hooks/chat_input'
import CopyToClipboard from './hooks/copy_to_clipboard'
import CurrentCheckbox from './hooks/current_checkbox'
import DocumentTemplate from './hooks/document_template'
import DropDownInput from './hooks/drop_down_input'
import FileUpload from './hooks/file_upload'
import FlashAutoDisappear from './hooks/flash_auto_disappear'
import MultiSelect from './hooks/multi_select'
import PdfPreview from './hooks/pdf_preview'
import PhoneInput from './hooks/phone_input'
import RatingsTooltip from './hooks/ratings_tooltip'
import RatingsTooltipContent from './hooks/ratings_tooltip_content'
import SearchHook from './hooks/search_hook'
import SidebarHook from './hooks/sidebar_hook'
import SignwellEmbed from './hooks/signwell_embed'
import SkillsInput from './hooks/skills_input'
import StoryHook from './hooks/story_hook'
import TagsInput from './hooks/tags_input'
import TextTruncate from './hooks/text_truncate'
import TimezoneDetector from './hooks/timezone_detector'
import WysiwygInput from './hooks/wysiwyg_input'

// Define hooks object
const Hooks = {
  AdminChart,
  ChatInput,
  CopyToClipboard,
  CurrentCheckbox,
  DocumentTemplate,
  DropDownInput,
  FileUpload,
  FlashAutoDisappear,
  MultiSelect,
  PdfPreview,
  PhoneInput,
  RatingsTooltip,
  RatingsTooltipContent,
  SearchHook,
  SidebarHook,
  SignwellEmbed,
  SkillsInput,
  StoryHook,
  TagsInput,
  TextTruncate,
  TimezoneDetector,
  WysiwygInput,
}

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
let liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300))
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === 'development') {
  window.addEventListener(
    'phx:live_reload:attached',
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs()

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown
      window.addEventListener('keydown', (e) => (keyDown = e.key))
      window.addEventListener('keyup', (e) => (keyDown = null))
      window.addEventListener(
        'click',
        (e) => {
          if (keyDown === 'c') {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtCaller(e.target)
          } else if (keyDown === 'd') {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtDef(e.target)
          }
        },
        true
      )

      window.liveReloader = reloader
    }
  )
}
