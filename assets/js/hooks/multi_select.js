export default {
  mounted() {
    this.initializeMultiSelect()
  },

  updated() {
    this.initializeMultiSelect()
  },

  initializeMultiSelect() {
    const select = this.el
    const container = select.parentElement
    const placeholder = select.dataset.placeholder || 'Choose options'

    // Hide the original select
    select.style.display = 'none'

    // Remove any existing custom UI
    const existingUI = container.querySelector('.multi-select-ui')
    if (existingUI) {
      existingUI.remove()
    }

    // Create custom multi-select UI
    const customSelect = document.createElement('div')
    customSelect.className = 'multi-select-ui relative'

    // Create display area
    const display = document.createElement('div')
    display.className =
      'min-h-[42px] px-3 py-2 border border-gray-300 rounded-md cursor-pointer flex flex-wrap gap-2 items-center'
    display.innerHTML = this.getDisplayContent(select, placeholder)

    // Create dropdown
    const dropdown = document.createElement('div')
    dropdown.className =
      'absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg hidden'
    dropdown.innerHTML = this.getDropdownContent(select)

    customSelect.appendChild(display)
    customSelect.appendChild(dropdown)
    container.appendChild(customSelect)

    // Prevent any form submission when clicking inside the multi-select
    customSelect.addEventListener('click', (e) => {
      e.stopPropagation()
    })

    // Event handlers
    display.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()

      if (!e.target.closest('.remove-tag')) {
        dropdown.classList.toggle('hidden')
      }
    })

    // Handle option clicks
    dropdown.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()

      const option = e.target.closest('.option-item')
      if (option) {
        const value = option.dataset.value
        const selectOption = select.querySelector(`option[value="${value}"]`)
        if (selectOption) {
          selectOption.selected = !selectOption.selected
          // Don't bubble the change event to prevent form submission
          select.dispatchEvent(new Event('change', { bubbles: false }))
          display.innerHTML = this.getDisplayContent(select, placeholder)
          dropdown.innerHTML = this.getDropdownContent(select)
        }
      }
    })

    // Handle tag removal
    display.addEventListener('click', (e) => {
      const removeBtn = e.target.closest('.remove-tag')
      if (removeBtn) {
        e.preventDefault()
        e.stopPropagation()

        const value = removeBtn.dataset.value
        const selectOption = select.querySelector(`option[value="${value}"]`)
        if (selectOption) {
          selectOption.selected = false
          // Don't bubble the change event to prevent form submission
          select.dispatchEvent(new Event('change', { bubbles: false }))
          display.innerHTML = this.getDisplayContent(select, placeholder)
          dropdown.innerHTML = this.getDropdownContent(select)
        }
      }
    })

    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!customSelect.contains(e.target)) {
        dropdown.classList.add('hidden')
      }
    })
  },

  getDisplayContent(select, placeholder) {
    const selected = Array.from(select.selectedOptions)
    if (selected.length === 0) {
      return `<span class="text-gray-400">${placeholder}</span>`
    }

    return (
      selected
        .map(
          (option) => `
      <span class="inline-flex items-center gap-1 px-2 py-1 text-sm bg-indigo-100 text-indigo-800 rounded">
        ${option.text}
        <button type="button" class="remove-tag hover:text-indigo-600" data-value="${option.value}">
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </span>
    `
        )
        .join('') + '<span class="flex-1"></span>'
    )
  },

  getDropdownContent(select) {
    const options = Array.from(select.options)
    return `
      <div class="max-h-60 overflow-auto py-1">
        ${options
          .map(
            (option) => `
          <div class="option-item px-3 py-2 hover:bg-gray-100 cursor-pointer flex items-center gap-2" data-value="${option.value}">
            <input type="checkbox" ${option.selected ? 'checked' : ''} class="pointer-events-none" readonly disabled />
            <span>${option.text}</span>
          </div>
        `
          )
          .join('')}
      </div>
    `
  },
}
