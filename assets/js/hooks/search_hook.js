const SearchHook = {
  mounted() {
    const searchContainer = document.querySelector('#search-container')
    const searchModal = document.querySelector('#search-modal')
    const searchList = document.querySelector('#search-list')
    const searchInput = document.querySelector('#search-input')
    let children = searchList.children
    let firstChild = searchList.firstElementChild
    let lastChild = searchList.lastElementChild
    let activeItem = firstChild

    // Watch for changes in search results
    new MutationObserver((mutations) => {
      children = searchList.children
      firstChild = searchList.firstElementChild
      lastChild = searchList.lastElementChild

      if (children.length > 0) {
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-baseline')
        )
        activeItem = firstChild
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-highlight')
        )
      }
    }).observe(searchList, { childList: true })

    // Open search modal
    window.addEventListener('psb:open-search', () => {
      this.liveSocket.execJS(
        searchContainer,
        searchContainer.getAttribute('phx-show')
      )
      this.liveSocket.execJS(searchModal, searchModal.getAttribute('phx-show'))
      setTimeout(() => searchInput.focus(), 50)
      this.liveSocket.execJS(
        activeItem,
        activeItem.getAttribute('phx-highlight')
      )
    })

    // Close search modal
    window.addEventListener('psb:close-search', () => {
      this.liveSocket.execJS(searchModal, searchModal.getAttribute('phx-hide'))
      this.liveSocket.execJS(
        searchContainer,
        searchContainer.getAttribute('phx-hide')
      )
    })

    // Global keyboard shortcut (Cmd/Ctrl + K)
    window.addEventListener('keydown', (event) => {
      if (event.metaKey && (event.key === 'k' || event.key === 'K')) {
        event.preventDefault()
        this.dispatchOpenSearch()
      }
    })

    // Mouse hover handling for search results
    ;[...children].forEach((item) => {
      item.addEventListener('mouseover', (event) => {
        if (
          event.movementX != 0 &&
          event.movementY != 0 &&
          event.target == item
        ) {
          this.liveSocket.execJS(
            activeItem,
            activeItem.getAttribute('phx-baseline')
          )
          activeItem = event.target
          this.liveSocket.execJS(
            activeItem,
            activeItem.getAttribute('phx-highlight')
          )
        }
      })
    })

    // Keyboard navigation within search
    searchContainer.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault()
        const link = activeItem.firstElementChild
        this.resetInput(searchInput)
        this.pushEventTo('#search-container', 'navigate', {
          path: link.pathname,
        })
        this.dispatchCloseSearch()
      }

      if (event.key === 'Escape') {
        this.dispatchCloseSearch()
      }

      if (event.key === 'Tab') {
        event.preventDefault()
      }

      if (event.key === 'ArrowUp') {
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-baseline')
        )
        activeItem =
          activeItem == firstChild
            ? lastChild
            : activeItem.previousElementSibling
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-highlight')
        )
        activeItem.scrollIntoView({ block: 'nearest', inline: 'nearest' })
      }

      if (event.key === 'ArrowDown') {
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-baseline')
        )
        activeItem =
          activeItem == lastChild ? firstChild : activeItem.nextElementSibling
        this.liveSocket.execJS(
          activeItem,
          activeItem.getAttribute('phx-highlight')
        )
        activeItem.scrollIntoView({ block: 'nearest', inline: 'nearest' })
      }
    })

    // Click handling for search results
    searchList.addEventListener('click', (event) => {
      const link = activeItem.firstElementChild
      this.resetInput(searchInput)
      this.pushEventTo('#search-container', 'navigate', { path: link.pathname })
      this.dispatchCloseSearch()
    })
  },

  resetInput(input) {
    input.value = ''
    this.pushEventTo('#search-container', 'search', { search: { input: '' } })
  },

  dispatchOpenSearch() {
    const event = new Event('psb:open-search')
    window.dispatchEvent(event)
  },

  dispatchCloseSearch() {
    const event = new Event('psb:close-search')
    window.dispatchEvent(event)
  },
}

export default SearchHook
