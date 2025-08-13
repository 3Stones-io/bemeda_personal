// Phoenix Storybook configuration file
// This file exposes hooks and configurations needed for Storybook to work properly with LiveView

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'

// Import all hooks that Storybook components might need
import SearchHook from './hooks/search_hook'
import SidebarHook from './hooks/sidebar_hook'
import StoryHook from './hooks/story_hook'
import ChatInput from './hooks/chat_input'
import CopyToClipboard from './hooks/copy_to_clipboard'
import CurrentCheckbox from './hooks/current_checkbox'
import DocumentTemplate from './hooks/document_template'
import FileUpload from './hooks/file_upload'
import FlashAutoDisappear from './hooks/flash_auto_disappear'
import MultiSelect from './hooks/multi_select'
import PdfPreview from './hooks/pdf_preview'
import RatingsTooltip from './hooks/ratings_tooltip'
import RatingsTooltipContent from './hooks/ratings_tooltip_content'
import SignwellEmbed from './hooks/signwell_embed'
import TagsInput from './hooks/tags_input'
import TextTruncate from './hooks/text_truncate'

// Create the hooks object with all available hooks
const Hooks = {
  SearchHook,
  SidebarHook,
  StoryHook,
  ChatInput,
  CopyToClipboard,
  CurrentCheckbox,
  DocumentTemplate,
  FileUpload,
  FlashAutoDisappear,
  MultiSelect,
  PdfPreview,
  RatingsTooltip,
  RatingsTooltipContent,
  SignwellEmbed,
  TagsInput,
  TextTruncate,
}

// Make hooks available globally for Phoenix Storybook
window.storybook = {
  Hooks: Hooks,
}
