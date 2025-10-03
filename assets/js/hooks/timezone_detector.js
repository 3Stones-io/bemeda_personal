export default {
  mounted() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
    const input = this.el.querySelector('#interview_timezone')
    if (input) {
      input.value = timezone
    }
  },
}
