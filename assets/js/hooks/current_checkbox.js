const CurrentCheckbox = {
  mounted() {
    this.handleChange()
    this.el.addEventListener('change', () => this.handleChange())
  },

  handleChange() {
    const isChecked = this.el.checked
    const endDateId = this.el.getAttribute('data-end-date-id')

    if (endDateId) {
      const endDateInput = document.getElementById(endDateId)
      const endDateContainer = document.getElementById(`${endDateId}-container`)

      if (endDateInput) {
        // Disable the end date input if current is checked
        endDateInput.disabled = isChecked

        // Clear the end date value if current is checked
        if (isChecked) {
          endDateInput.value = ''

          // If using flatpickr, we need to update the flatpickr instance
          if (endDateInput._flatpickr) {
            endDateInput._flatpickr.clear()
          }
        }

        // Add visual indication that the field is disabled
        if (endDateContainer) {
          if (isChecked) {
            endDateContainer.classList.add('opacity-50')
          } else {
            endDateContainer.classList.remove('opacity-50')
          }
        }
      }
    }
  },
}

export default CurrentCheckbox
