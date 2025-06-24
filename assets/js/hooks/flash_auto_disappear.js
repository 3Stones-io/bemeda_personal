const FlashAutoDisappear = {
  mounted() {
    this.timeout = setTimeout(() => {
      // Create a click event that doesn't propagate to prevent modal closure
      const event = new Event('click', { bubbles: false, cancelable: true })
      this.el.dispatchEvent(event)
    }, 5000)
  },

  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  },
}

export default FlashAutoDisappear
