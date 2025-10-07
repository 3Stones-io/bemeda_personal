export default DropDownInput = {
  mounted() {
    const hook = this
    const dropdown = hook.el
    const dropdownId = dropdown.dataset.dropdownId
    const dropdownOptionsList = dropdown.querySelector(
      `#dropdown-options-list-${dropdownId}`
    )
    const dropdownOptionsItems = Array.from(dropdownOptionsList.children)
    const dropdownOptionsContainer = dropdown.querySelector(
      `#dropdown-options-container-${dropdownId}`
    )
    const dropdownInput = dropdown.querySelector(`#${dropdownId}`)
    const dropdownPrompt = dropdown.querySelector(
      `#dropdown-prompt-${dropdownId}`
    )
    const dropdownSearchInput = dropdown.querySelector(
      `#dropdown-search-${dropdownId}`
    )

    // Searching the list of options
    if (dropdownSearchInput) {
      dropdownSearchInput.addEventListener('input', (event) => {
        event.stopPropagation()
        let searchValue = event.target.value.trim().toLowerCase()

        dropdownOptionsItems.forEach((option) => {
          if (option.textContent.toLowerCase().includes(searchValue)) {
            option.classList.remove('hidden')
          } else {
            option.classList.add('hidden')
          }
        })
      })
    }

    // Show/hide the dropdown options
    dropdownPrompt.addEventListener('click', () => {
      const isHidden = dropdownOptionsContainer.classList.contains('hidden')

      if (isHidden) {
        dropdownOptionsContainer.classList.remove('hidden')
        dropdownPrompt.classList.remove('border-form-input-border')
        dropdownPrompt.classList.add('border-form-border-focus')
        dropdownPrompt
          .querySelector('.hero-chevron-down')
          .classList.add('rotate-180')
      } else {
        dropdownOptionsContainer.classList.add('hidden')
        dropdownPrompt.classList.add('border-form-input-border')
        dropdownPrompt.classList.remove('border-form-border-focus')
        dropdownPrompt
          .querySelector('.hero-chevron-down')
          .classList.remove('rotate-180')
      }
    })

    // Item selection
    dropdownOptionsItems.forEach((option) => {
      option.addEventListener('click', (event) => {
        let optionValue = event.target.textContent.trim()

        dropdownPrompt.querySelector('.prompt-text').textContent = optionValue
        dropdownPrompt
          .querySelector('.hero-chevron-down')
          .classList.remove('rotate-180')
        dropdownPrompt.classList.remove('border-form-border-focus')
        dropdownPrompt.classList.add('border-form-input-border')
        dropdownOptionsContainer.classList.add('hidden')
        dropdownInput.value = event.target.dataset.value
        dropdownInput.dispatchEvent(new Event('input', { bubbles: true }))

        // Reset the search input if it exists
        if (dropdownSearchInput) {
          dropdownSearchInput.value = ''
          dropdownSearchInput.dispatchEvent(
            new Event('input', { bubbles: true })
          )
        }
      })
    })
  },
}
