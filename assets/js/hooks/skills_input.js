export default SkillsInput = {
  mounted() {
    const container = this.el
    const selectedSkillsTemplate = container.querySelector(
      '#selected-skills-template'
    )
    const checkboxes = Array.from(container.querySelectorAll('.skill-checkbox'))
    const selectedSkillsContainer = container.querySelector(
      '.selected-skills-container'
    )

    const selectedSkillsTitle = container.querySelector(
      '#selected-skills-title'
    )
    const searchContainer = container.querySelector(
      '#dropdown-options-container-skills-search-options-list'
    )
    const searchInput = searchContainer.querySelector("input[type='text']")
    const optionsList = searchContainer.querySelector('.dropdown-options-list')
    const optionsItems = Array.from(optionsList.children)

    const updateInitialState = () => {
      this.initialState = checkboxes.map((checkbox) => ({
        value: checkbox.value,
        checked: checkbox.checked,
      }))

      this.initiallySelectedValues = new Set(
        this.initialState
          .filter((item) => item.checked)
          .map((item) => item.value)
      )
    }

    updateInitialState()

    let wasHidden = container.classList.contains('hidden')

    const handleContainerVisibility = () => {
      const isHidden = container.classList.contains('hidden')

      if (!isHidden) {
        if (wasHidden) {
          updateInitialState()
        }
        document.body.classList.add('overflow-hidden')
      } else {
        document.body.classList.remove('overflow-hidden')
      }

      wasHidden = isHidden
    }

    // Use MutationObserver to watch for class changes
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === 'attributes' &&
          mutation.attributeName === 'class'
        ) {
          handleContainerVisibility()
        }
      })
    })

    observer.observe(container, {
      attributes: true,
      attributeFilter: ['class'],
    })

    handleContainerVisibility()
    // Search options
    searchInput.addEventListener('focus', () => {
      optionsList.classList.remove('hidden')

      optionsItems.forEach((option) => {
        option.classList.remove('hidden')
      })
    })

    searchInput.addEventListener('input', (event) => {
      event.stopPropagation()
      optionsList.classList.remove('hidden')

      if (event.target.value.trim() !== '') {
        let searchValue = event.target.value.trim().toLowerCase()

        optionsItems.forEach((option) => {
          if (option.textContent.toLowerCase().includes(searchValue)) {
            option.classList.remove('hidden')
          } else {
            option.classList.add('hidden')
          }
        })
      }
    })

    optionsItems.forEach((option) => {
      option.addEventListener('click', (event) => {
        event.stopPropagation()
        const checkbox = checkboxes.find(
          (checkbox) => checkbox.value === event.target.dataset.value
        )
        checkbox.checked = true
        renderSelectedSkills()

        optionsList.classList.add('hidden')
        searchInput.value = ''
        searchInput.dispatchEvent(new Event('input', { bubbles: true }))
      })
    })

    // list click away
    document.addEventListener('click', (event) => {
      if (
        !optionsList.contains(event.target) &&
        !searchInput.contains(event.target)
      ) {
        optionsList.classList.add('hidden')
      }
    })

    const maxSkills = 10

    const renderSelectedSkills = () => {
      selectedSkillsContainer.innerHTML = ''

      const checkedCount = checkboxes.filter(
        (checkbox) => checkbox.checked
      ).length

      if (checkedCount > 0) {
        selectedSkillsTitle.style.display = 'block'
        selectedSkillsTitle.querySelector('.skill-count').textContent =
          `(${checkedCount}/10)`
      } else {
        selectedSkillsTitle.style.display = 'none'
      }

      if (checkedCount >= maxSkills) {
        checkboxes.forEach((checkbox) => {
          checkbox.disabled = true
        })
      } else {
        checkboxes.forEach((checkbox) => {
          checkbox.disabled = false
        })
      }

      checkboxes.forEach((checkbox) => {
        if (checkbox.checked) {
          const skillElement = document.importNode(
            selectedSkillsTemplate.content,
            true
          )
          skillElement.querySelector('.tag-text').textContent = checkbox.value

          const removeBtn = skillElement.querySelector('.selected-skill-btn')
          removeBtn.addEventListener('click', () => {
            checkbox.checked = false
            renderSelectedSkills()
          })

          selectedSkillsContainer.appendChild(skillElement)
          checkbox.parentElement.classList.add('pointer-events-none')
        } else {
          checkbox.parentElement.classList.remove('pointer-events-none')
        }
      })
    }

    renderSelectedSkills()

    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener('change', () => {
        renderSelectedSkills()
      })
    })

    container.addEventListener('undo_selection', () => {
      checkboxes.forEach((checkbox) => {
        if (
          checkbox.checked &&
          !this.initiallySelectedValues.has(checkbox.value)
        ) {
          checkbox.checked = false
          checkbox.dispatchEvent(new Event('change', { bubbles: true }))
        }
      })
      renderSelectedSkills()
    })
  },
}
