import ClipboardJS from 'clipboard'

const CopyToClipboard = {
  mounted() {
    const copyButton = this.el
    const copyIcon = document.querySelector('#copy-icon')
    const copyConfirmElement = document.querySelector('#copy-confirm-message')

    const clipboard = new ClipboardJS(copyButton)

    clipboard.on('success', (e) => {
      e.clearSelection()

      copyIcon.classList.add('hidden')

      copyConfirmElement.classList.remove('hidden')

      setTimeout(() => {
        copyConfirmElement.classList.add('hidden')

        copyIcon.classList.remove('hidden')
      }, 2000)
    })
  },
}

export default CopyToClipboard
