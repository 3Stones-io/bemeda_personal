const TextTruncate = {
  initializeTranslations() {
    this.translations = {
      readMore: this.el.dataset.readMoreText || 'Read More',
      readLess: this.el.dataset.readLessText || 'Read Less',
    }
  },

  mounted() {
    this.initializeTranslations()
    const textElement = this.el
    const fullText = textElement.textContent
    const maxLength = parseInt(this.el.dataset.truncateLength) || 150

    if (fullText.length <= maxLength) {
      return // No need to truncate
    }

    // Initial truncation
    this.truncateText(textElement, fullText, maxLength)

    // Set up event listeners for the "More" and "Less" links
    textElement.addEventListener('click', (e) => {
      e.preventDefault()
      if (e.target.classList.contains('read-more-link')) {
        this.showFullText(textElement, fullText)
      } else if (e.target.classList.contains('read-less-link')) {
        this.truncateText(textElement, fullText, maxLength)
      }
    })
  },

  truncateText(element, fullText, maxLength) {
    const truncatedText = fullText.substring(0, maxLength).replace(/\w+$/, '')
    element.innerHTML = `
      ${truncatedText}... 
      <a href="#" class="read-more-link text-blue-500 hover:text-blue-600">${this.translations.readMore}</a>
    `
  },

  showFullText(element, fullText) {
    element.innerHTML = `
      ${fullText} 
      <a href="#" class="read-less-link text-blue-500 hover:text-blue-600">${this.translations.readLess}</a>
    `
  },
}

export default TextTruncate
