const JobApplicationStatusInputs = {
  mounted() {
    const updateStatusContainer = this.el
    const form = updateStatusContainer.querySelector('form')
    const applicantId = form.dataset.applicantId
    const cancelButton = document.getElementById(
      `cancel-status-update-${applicantId}`
    )
    const submitButton = document.getElementById(`update-status-${applicantId}`)

    const formElements = form.querySelectorAll(
      'input, select, textarea, button'
    )

    formElements.forEach((element) => {
      ;['click', 'keydown', 'change'].forEach((eventType) => {
        element.addEventListener(eventType, (event) => {
          event.stopPropagation()
        })
      })
    })

    cancelButton.addEventListener('click', () => {
      updateStatusContainer.style.display = 'none'
    })

    submitButton.addEventListener('click', () => {
      updateStatusContainer.style.display = 'none'
    })
  },
}

export default JobApplicationStatusInputs
