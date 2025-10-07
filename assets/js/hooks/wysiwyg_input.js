import Trix from 'trix'
// Customize toolbar
document.addEventListener('trix-before-initialize', () => {
  Trix.config.toolbar.getDefaultHTML = () => {
    return `
      <div class="trix-button-row">
        <span class="trix-button-group trix-button-group--text-tools" data-trix-button-group="text-tools">
          <button type="button" class="trix-button trix-button--icon trix-button--icon-bold" data-trix-attribute="bold" data-trix-key="b" title="Bold" tabindex="-1">Bold</button>
          <button type="button" class="trix-button trix-button--icon trix-button--icon-italic" data-trix-attribute="italic" data-trix-key="i" title="Italic" tabindex="-1">Italic</button>
          <button type="button" class="trix-button trix-button--icon trix-button--icon-strike" data-trix-attribute="strike" title="Strikethrough" tabindex="-1">Strikethrough</button>
        </span>
        <span class="trix-button-group trix-button-group--block-tools" data-trix-button-group="block-tools">
          <button type="button" class="trix-button trix-button--icon trix-button--icon-heading-1" data-trix-attribute="heading1" title="Heading" tabindex="-1">Heading</button>
          <button type="button" class="trix-button trix-button--icon trix-button--icon-quote" data-trix-attribute="quote" title="Quote" tabindex="-1">Quote</button>
          <button type="button" class="trix-button trix-button--icon trix-button--icon-bullet-list" data-trix-attribute="bullet" title="Bullets" tabindex="-1">Bullets</button>
          <button type="button" class="trix-button trix-button--icon trix-button--icon-number-list" data-trix-attribute="number" title="Numbers" tabindex="-1">Numbers</button>
        </span>
      </div>
    `
  }
})

export default WysiwygInput = {
  mounted() {
    const element = document.querySelector('trix-editor')
    const maxCharacters = parseInt(this.el.dataset.maxCharacters)

    const updateCharacterProgress = () => {
      if (!maxCharacters) return

      const textContent = element.editor.getDocument().toString()
      const currentLength = textContent.length

      const progressIndicator = document.getElementById(
        `character-progress-indicator-${this.el.querySelector('input[type="hidden"]').id}`
      )

      if (progressIndicator) {
        const percentage = Math.min((currentLength / maxCharacters) * 100, 100)
        const circumference = 50.26 // 2 * π * r (r=8)
        const offset = circumference - (percentage / 100) * circumference

        progressIndicator.style.strokeDashoffset = offset

        if (percentage > 90) {
          progressIndicator.style.stroke = '#ef4444'
        } else if (percentage > 75) {
          progressIndicator.style.stroke = '#eab308'
        } else {
          progressIndicator.style.stroke = '#3b82f6'
        }
      }
    }

    element.editor.element.addEventListener('trix-change', (e) => {
      this.el.value = element.value
      updateCharacterProgress()
    })

    element.editor.element.addEventListener('trix-blur', (e) => {
      this.el.value = element.value
      this.el.dispatchEvent(new Event('blur', { bubbles: true }))
    })

    updateCharacterProgress()
  },
}
