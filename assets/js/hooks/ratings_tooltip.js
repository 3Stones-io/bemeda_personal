const RatingsTooltip = {
  mounted() {
    const trigger = this.el
    const tooltipId = trigger.getAttribute('data-tooltip-target')
    const tooltip = document.getElementById(tooltipId)

    if (!tooltip) return

    trigger.addEventListener('mouseenter', () => {
      tooltip.classList.remove('hidden')
    })

    trigger.addEventListener('mouseleave', (e) => {
      const tooltipRect = tooltip.getBoundingClientRect()
      const mouseX = e.clientX
      const mouseY = e.clientY

      if (
        mouseX >= tooltipRect.left &&
        mouseX <= tooltipRect.right &&
        mouseY >= tooltipRect.top &&
        mouseY <= tooltipRect.bottom
      ) {
        return
      }

      tooltip.classList.add('hidden')
    })
  },
}

export default RatingsTooltip
