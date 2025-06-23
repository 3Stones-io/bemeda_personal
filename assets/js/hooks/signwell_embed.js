export default {
  mounted() {
    const signingUrl = this.el.dataset.signingUrl

    if (signingUrl && signingUrl.includes('/mock_signing/')) {
      console.log('Mock signing URL detected, using mock interface')
      this.initializeMockInterface()
    } else {
      this.loadSignWellLibrary()
        .then(() => {
          this.initializeSignWellEmbed()
        })
        .catch((error) => {
          console.error('Failed to initialize SignWell:', error)
          this.pushEvent('signing_error', {
            error: 'Failed to load SignWell library',
            details: error.toString(),
          })
        })
    }
  },

  destroyed() {
    if (this.signWellEmbed) {
      this.signWellEmbed = null
    }
  },

  loadSignWellLibrary() {
    return new Promise((resolve, reject) => {
      if (window.SignWellEmbed) {
        resolve()
        return
      }

      const script = document.createElement('script')
      script.type = 'text/javascript'
      script.src = 'https://static.signwell.com/assets/embedded.js'
      script.onload = () => {
        resolve()
      }
      script.onerror = () => {
        console.error('Failed to load SignWell library')
        reject(new Error('Failed to load SignWell library'))
      }

      document.head.appendChild(script)
    })
  },

  initializeSignWellEmbed() {
    const signingUrl = this.el.dataset.signingUrl

    if (!signingUrl) {
      console.error('No signing URL provided')
      return
    }

    this.signWellEmbed = new window.SignWellEmbed({
      url: signingUrl,
      containerId: this.el.id,
      allowDecline: true,
      allowClose: true,
      showHeader: true,
      allowDownload: true,
      events: {
        completed: (e) => {
          this.pushEvent('signing_completed', {
            'document-id': e.id,
          })
        },
        declined: (e) => {
          this.pushEvent('signing_declined', {
            'document-id': e.id,
            'decline-reason': e.declineReason,
          })
        },
        closed: (e) => {
          this.pushEvent('signing_closed', {
            'document-id': e.id,
          })
        },
        error: (e) => {
          this.pushEvent('signing_error', {
            error: e.message || e.toString() || 'Unknown SignWell error',
            details: JSON.stringify(e),
          })
        },
      },
    })

    this.signWellEmbed.open()
  },

  initializeMockInterface() {
    const signingUrl = this.el.dataset.signingUrl
    const documentId = signingUrl.split('/').pop()

    // Create a mock signing interface
    this.el.innerHTML = `
      <div class="flex flex-col items-center justify-center h-full bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
        <div class="text-center p-8">
          <div class="mb-6">
            <div class="w-16 h-16 mx-auto bg-blue-100 rounded-full flex items-center justify-center mb-4">
              <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-gray-900 mb-2">Mock Signing Interface</h3>
            <p class="text-gray-600 mb-6">This is a mock signing interface for development and testing.</p>
          </div>
          
          <div class="space-y-4">
            <button
              id="mock-sign-button"
              class="inline-flex items-center px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg transition-colors duration-200"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
              </svg>
              Sign Document
            </button>
            
            <button
              id="mock-decline-button"
              class="inline-flex items-center px-6 py-3 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors duration-200 ml-3"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
              Decline
            </button>
          </div>
          
          <p class="text-sm text-gray-500 mt-6">
            Document ID: <code class="bg-gray-200 px-2 py-1 rounded text-xs">${documentId}</code>
          </p>
        </div>
      </div>
    `

    const signButton = this.el.querySelector('#mock-sign-button')
    const declineButton = this.el.querySelector('#mock-decline-button')

    if (signButton) {
      signButton.addEventListener('click', () => {
        console.log('Mock signing completed')
        this.pushEvent('signing_completed', {
          'document-id': documentId,
        })
      })
    }

    if (declineButton) {
      declineButton.addEventListener('click', () => {
        console.log('Mock signing declined')
        this.pushEvent('signing_declined', {
          'document-id': documentId,
          'decline-reason': 'User declined',
        })
      })
    }
  },
}
