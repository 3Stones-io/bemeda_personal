/**
 * Hook for handling copy to clipboard functionality using clipboard.js
 */

import ClipboardJS from 'clipboard'

const CopyToClipboard = {
  mounted() {
    const copyButton = this.el
    const copyIcon = document.querySelector('#copy-icon')
    const copyConfirmElement = document.querySelector('#copy-confirm-message')

    // Initialize clipboard.js on the element
    // We're using data-clipboard-text attribute, so no need to specify target
    const clipboard = new ClipboardJS(copyButton)

    // Show success message when copy is successful
    clipboard.on('success', (e) => {
      e.clearSelection()

      // Hide the copy icon
      copyIcon.classList.add('hidden')

      // Show the confirmation icon
      copyConfirmElement.classList.remove('hidden')

      // After 2 seconds, restore original state
      setTimeout(() => {
        // Hide the confirmation icon
        copyConfirmElement.classList.add('hidden')

        // Show the copy icon again
        copyIcon.classList.remove('hidden')
      }, 2000)
    })
  },
}

export default CopyToClipboard
