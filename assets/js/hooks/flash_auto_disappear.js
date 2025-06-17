const FlashAutoDisappear = {
  mounted() {
    this.timeout = setTimeout(() => {
      this.el.click()
    }, 5000)
  },

  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  },
}

export default FlashAutoDisappear
