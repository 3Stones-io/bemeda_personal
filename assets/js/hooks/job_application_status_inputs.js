const JobApplicationStatusInputs = {
  mounted() {
    const updateStatusContainer = this.el
    const form = updateStatusContainer.querySelector('form')

    const formElements = form.querySelectorAll(
      'input, select, textarea, button'
    )

    formElements.forEach((element) => {
      element.addEventListener('click', (event) => {
        event.stopPropagation()
      })
      element.addEventListener('keydown', (event) => {
        event.stopPropagation()
      })
      element.addEventListener('change', (event) => {
        event.stopPropagation()
      })
    })

    const cancelButton = Array.from(this.el.querySelectorAll('button')).find(
      (button) => button.textContent.trim() === 'Cancel'
    )

    const submitButton = Array.from(this.el.querySelectorAll('button')).find(
      (button) => button.textContent.trim() === 'Update Status'
    )

    cancelButton.addEventListener('click', () => {
      updateStatusContainer.style.display = 'none'
    })

    submitButton.addEventListener('click', () => {
      updateStatusContainer.style.display = 'none'
    })
  },
}

export default JobApplicationStatusInputs
