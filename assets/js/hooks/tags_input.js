const TagsInput = {
  mounted() {
    const tagContainer = this.el.querySelector('.tag-container')
    const tagInput = this.el.querySelector('.tag-input')
    const hiddenInput = this.el.querySelector('input[type="hidden"]')
    const hook = this
    const inputContainer = hook.el
    const tagTemplate = this.el.querySelector('#tag-template')

    let tags = []

    const checkOverflow = () => {
      if (tagContainer.children.length === 0) return false

      return (
        tagContainer.offsetHeight > tagContainer.children[0].offsetHeight * 1.5
      )
    }

    const updateInputLayout = () => {
      setTimeout(() => {
        if (checkOverflow()) {
          tagInput.classList.add('w-full', 'mt-2')
          tagContainer.classList.add('w-full')
        } else {
          tagInput.classList.remove('w-full', 'mt-2')
          tagContainer.classList.remove('w-full')
        }
      }, 10)
    }

    const renderTags = () => {
      tagContainer.innerHTML = ''

      tags.forEach((tag) => {
        const tagElement = document.importNode(tagTemplate.content, true)
        tagElement.querySelector('.tag').setAttribute('data-value', tag)
        tagElement.querySelector('.tag-text').textContent = tag
        tagContainer.appendChild(tagElement)
      })

      updateInputLayout()
    }

    const updateTagsFromInput = () => {
      tags = hiddenInput.value
        ? hiddenInput.value.split(',').filter((tag) => tag.trim() !== '')
        : []
      renderTags()
    }

    const updateHiddenInput = () => {
      hiddenInput.value = tags.join(',')
      updateTagsFromInput()
    }

    const addTag = (value) => {
      if (!value || tags.includes(value)) return

      tags.push(value)
      updateHiddenInput()

      tagInput.focus()
    }

    const removeTag = (value) => {
      const index = tags.indexOf(value)
      if (index !== -1) {
        tags.splice(index, 1)
        updateHiddenInput()
      }

      tagInput.focus()
    }

    const loadExistingTags = () => {
      updateTagsFromInput()
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
        } else if (
          e.key === 'Backspace' &&
          e.target.value === '' &&
          tags.length > 0
        ) {
          removeTag(tags[tags.length - 1])
        }
      })

      inputContainer.addEventListener('click', (e) => {
        if (
          e.target === inputContainer ||
          e.target.classList.contains('tag-container')
        ) {
          tagInput.focus()
        }
      })

      tagContainer.addEventListener('click', (e) => {
        if (
          e.target.classList.contains('remove-tag') ||
          e.target.closest('.remove-tag')
        ) {
          const tagElement = e.target.closest('.tag')
          if (tagElement) {
            const tagValue = tagElement.getAttribute('data-value')
            removeTag(tagValue)
          }
        }
      })

      window.addEventListener('resize', () => {
        if (tags.length > 0) {
          updateInputLayout()
        }
      })

      hiddenInput.addEventListener('change', updateTagsFromInput)

      if (hiddenInput.getAttribute('data-input-type') === 'filters') {
        hook.el.addEventListener('clear_filters', () => {
          tags = []
          renderTags()
          updateHiddenInput()
          tagInput.value = ''
        })
      }
    }

    loadExistingTags()
    setupEventListeners()
  },
}

export default TagsInput
