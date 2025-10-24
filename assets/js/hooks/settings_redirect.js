const SettingsRedirect = {
  mounted() {
    this.checkAndRedirect()

    window.addEventListener('resize', () => {
      this.checkAndRedirect()
    })
  },

  checkAndRedirect() {
    if (window.innerWidth > 950) {
      window.location.href = '/users/settings/info'
    }
  },

  destroyed() {
    window.removeEventListener('resize', this.checkAndRedirect)
  },
}

export default SettingsRedirect
