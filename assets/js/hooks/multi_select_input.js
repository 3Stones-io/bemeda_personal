const MultiSelectInput = {
  mounted() {
    const container = this.el
    const id = container.dataset.id
    const button = container.querySelector(`#select-button-${id}`)
    const dropdown = container.querySelector(`#select-dropdown-${id}`)
    const icon = container.querySelector(`#select-icon-${id}`)
    const hiddenInput = container.querySelector(`#${id}`)
    const checkboxes = dropdown.querySelectorAll('input[type="checkbox"]')

    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === 'attributes' &&
          mutation.attributeName === 'class'
        ) {
          const target = mutation.target
          if (target.classList.contains('hidden')) {
            selectedValues = Array.from(checkboxes)
              .filter((cb) => cb.checked)
              .map((cb) => cb.value)

            hiddenInput.value = selectedValues.join(',')
            hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
          }
        }
      })
    })

    observer.observe(dropdown, {
      attributes: true,
      attributeFilter: ['class'],
    })

    button.addEventListener('click', (event) => {
      event.preventDefault()

      dropdown.classList.toggle('hidden')
      icon.classList.toggle('rotate-180')
    })

    document.addEventListener('click', (event) => {
      const isClickInsideContainer = container.contains(event.target)
      const isDropdownVisible = !dropdown.classList.contains('hidden')

      if (!isClickInsideContainer && isDropdownVisible) {
        dropdown.classList.add('hidden')
        icon.classList.remove('rotate-180')
      }
    })

    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener('change', (event) => {
        event.preventDefault()
        event.stopPropagation()

        selectedValues = Array.from(checkboxes)
          .filter((cb) => cb.checked)
          .map((cb) => cb.value)
      })
    })
  },
}

export default MultiSelectInput
