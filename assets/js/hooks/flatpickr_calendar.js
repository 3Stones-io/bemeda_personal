import flatpickr from 'flatpickr'

const FlatpickrCalendar = {
  mounted() {
    const input = this.el

    flatpickr(input, {
      dateFormat: 'Y-m-d',
    })
  },
}

export default FlatpickrCalendar
