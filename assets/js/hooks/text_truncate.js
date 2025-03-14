const TextTruncate = {
  mounted() {
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
      if (e.target.classList.contains('read-more-link')) {
        this.showFullText(textElement, fullText)
        e.preventDefault()
      } else if (e.target.classList.contains('read-less-link')) {
        this.truncateText(textElement, fullText, maxLength)
        e.preventDefault()
      }
    })
  },

  truncateText(element, fullText, maxLength) {
    const truncatedText = fullText.substring(0, maxLength).replace(/\w+$/, '')
    element.innerHTML = `
      ${truncatedText}... 
      <a href="#" class="read-more-link text-blue-500 hover:text-blue-600">Read More</a>
    `
  },

  showFullText(element, fullText) {
    element.innerHTML = `
      ${fullText} 
      <a href="#" class="read-less-link text-blue-500 hover:text-blue-600">Read Less</a>
    `
  },
}

export default TextTruncate
