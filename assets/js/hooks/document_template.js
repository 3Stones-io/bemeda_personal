export default {
  mounted() {
    this.handleEvent(`open-pdf-${this.el.id}`, ({ url }) => {
      window.open(url, '_blank')
    })
  },
}
