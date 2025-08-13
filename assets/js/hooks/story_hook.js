const StoryHook = {
  mounted() {
    if (window.location.hash) {
      const element = document.querySelector(window.location.hash)
      if (element) {
        const container = document.querySelector('#live-container')
        setTimeout(() => {
          container.scrollTop = element.offsetTop - 115
        }, 100)
      }
    }
    this.bindAnchorLinks()
    this.bindCopyCodeLinks()
  },

  updated() {
    this.bindAnchorLinks()
  },

  bindAnchorLinks() {
    document.querySelectorAll('.variation-anchor-link').forEach((link) => {
      link.addEventListener('click', (event) => {
        event.preventDefault()
        window.history.replaceState({}, '', link.hash)
      })
    })
  },

  bindCopyCodeLinks() {
    const defaultClasses = ['psb-text-slate-500', 'hover:psb-text-slate-100']
    const successClasses = ['psb-text-green-400', 'hover:psb-text-green-400']
    const copyIcon = 'fa-copy'
    const checkIcon = 'fa-check'

    window.addEventListener('psb:copy-code', (event) => {
      const button = event.target
      const icon =
        button.querySelector('.svg-inline--fa') ||
        button.querySelector('.fa-copy')

      button.classList.add(...successClasses)
      button.classList.remove(...defaultClasses)
      icon.classList.add(checkIcon)
      icon.classList.remove(copyIcon)

      this.copyToClipboard(button.nextElementSibling.textContent)

      setTimeout(() => {
        const iconElement =
          button.querySelector('.svg-inline--fa') ||
          button.querySelector('.fa-copy')
        iconElement.classList.add(copyIcon)
        iconElement.classList.remove(checkIcon)
        button.classList.add(...defaultClasses)
        button.classList.remove(...successClasses)
      }, 1000)
    })
  },

  copyToClipboard(text) {
    const textarea = document.createElement('textarea')
    textarea.textContent = text
    textarea.style.position = 'fixed'
    document.body.appendChild(textarea)
    textarea.select()

    try {
      return document.execCommand('copy')
    } catch (error) {
      console.warn('Copy to clipboard failed.', error)
      return prompt('Copy to clipboard: Ctrl+C, Enter', text)
    } finally {
      document.body.removeChild(textarea)
    }
  },
}

export default StoryHook
