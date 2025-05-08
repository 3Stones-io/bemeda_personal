const RatingsTooltipContent = {
  mounted() {
    const tooltipContent = this.el

    tooltipContent.addEventListener('mouseleave', () => {
      tooltipContent.classList.add('hidden')
    })

    tooltipContent.addEventListener('click', (e) => {
      e.stopPropagation()
    })
  },
}

export default RatingsTooltipContent
