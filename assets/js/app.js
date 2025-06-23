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
import ChatInput from './hooks/chat_input'
import CopyToClipboard from './hooks/copy_to_clipboard'
import CurrentCheckbox from './hooks/current_checkbox'
import DocumentTemplate from './hooks/document_template'
import FileUpload from './hooks/file_upload'
import FlashAutoDisappear from './hooks/flash_auto_disappear'
import PdfPreview from './hooks/pdf_preview'
import RatingsTooltip from './hooks/ratings_tooltip'
import RatingsTooltipContent from './hooks/ratings_tooltip_content'
import SignwellEmbed from './hooks/signwell_embed'
import TagsInput from './hooks/tags_input'
import TextTruncate from './hooks/text_truncate'

// Define hooks object
const Hooks = {
  ChatInput,
  CopyToClipboard,
  CurrentCheckbox,
  DocumentTemplate,
  FileUpload,
  FlashAutoDisappear,
  PdfPreview,
  RatingsTooltip,
  RatingsTooltipContent,
  SignwellEmbed,
  TagsInput,
  TextTruncate,
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
