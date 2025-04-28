const TagFilterInput = {
  mounted() {
    const tagContainer = this.el.querySelector('.tag-container')
    const tagInput = this.el.querySelector('.tag-input')
    const hiddenInput = this.el.querySelector('input[type="hidden"]')
    const inputContainer = this.el
    let tags = []

    const renderTags = () => {
      tagContainer.innerHTML = ''
      
      tags.forEach(tag => {
        const tagElement = document.createElement('div')
        tagElement.className = 'tag inline-flex items-center gap-1 bg-indigo-100 text-indigo-800 text-xs rounded-full px-3 py-1'
        tagElement.setAttribute('data-value', tag)
        tagElement.innerHTML = `
          <span>${tag}</span>
          <button type="button" class="remove-tag text-indigo-500 hover:text-indigo-700 focus:outline-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </button>
        `
        tagContainer.appendChild(tagElement)
      })
    }

    const updateHiddenInput = () => {
      hiddenInput.value = tags
    }

    const addTag = (value) => {
      if (!value || tags.includes(value)) return
      
      tags.push(value)
      updateHiddenInput()
      renderTags()
      
      tagInput.focus()
    }

    const removeTag = (value) => {
      const index = tags.indexOf(value)
      if (index !== -1) {
        tags.splice(index, 1)
        updateHiddenInput()
        renderTags()
      }
      
      tagInput.focus()
    }

    const loadExistingTags = () => {
      const currentValue = hiddenInput.value
      if (currentValue) {
        const tagValues = currentValue.split(',').filter(tag => tag.trim() !== '')
        tagValues.forEach(tag => addTag(tag))
      }
    }

    const setupEventListeners = () => {
      tagInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ',') {
          e.preventDefault()
          const tagValue = e.target.value.trim()
          if (tagValue) {
            addTag(tagValue)
            e.target.value = ''
          }
        } else if (e.key === 'Backspace' && e.target.value === '' && tags.length > 0) {
          removeTag(tags[tags.length - 1])
        }
      })

      inputContainer.addEventListener('click', (e) => {
        if (e.target === inputContainer || e.target.classList.contains('tag-container')) {
          tagInput.focus()
        }
      })

      tagContainer.addEventListener('click', (e) => {
        if (e.target.classList.contains('remove-tag') || e.target.closest('.remove-tag')) {
          const tagElement = e.target.closest('.tag')
          if (tagElement) {
            const tagValue = tagElement.getAttribute('data-value')
            removeTag(tagValue)
          }
        }
      })
    }

    loadExistingTags()
    setupEventListeners()
  }
}

export default TagFilterInput 