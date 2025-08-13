const SidebarHook = {
  mounted() {
    const sidebarContainer = document.querySelector('#sidebar-container')
    const sidebarOverlay = document.querySelector('#sidebar-overlay')

    const openSidebar = () => {
      sidebarContainer.classList.remove('psb-hidden')
      sidebarOverlay.classList.remove('psb-hidden')
    }

    const closeSidebar = () => {
      sidebarContainer.classList.add('psb-hidden')
      sidebarOverlay.classList.add('psb-hidden')
    }

    // Handle events from LiveView
    this.handleEvent('psb:open-sidebar', openSidebar)
    this.handleEvent('psb:close-sidebar', closeSidebar)

    // Handle global window events
    window.addEventListener('psb:open-sidebar', openSidebar)
    window.addEventListener('psb:close-sidebar', closeSidebar)
  },
}

export default SidebarHook
