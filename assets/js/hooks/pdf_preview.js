const PDFJS_CDN_URL =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.8.69/pdf.min.mjs'
const PDFJS_WORKER_URL =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.8.69/pdf.worker.min.mjs'

let pdfjsLib = null

async function loadPdfJs() {
  if (pdfjsLib) return pdfjsLib

  try {
    pdfjsLib = await import(PDFJS_CDN_URL)
    pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER_URL
    return pdfjsLib
  } catch (error) {
    console.error('Failed to load PDF.js from CDN:', error)
    throw new Error('PDF viewer unavailable')
  }
}

export default PdfPreview = {
  mounted() {
    this.generatePreview()
  },

  updated() {
    this.generatePreview()
  },

  async generatePreview() {
    const pdfUrl = this.el.dataset.pdfUrl
    const previewContainer = this.el.querySelector('.pdf-preview-container')

    if (!pdfUrl || !previewContainer) return

    try {
      previewContainer.innerHTML =
        '<div class="animate-pulse bg-gray-200 h-48 rounded flex items-center justify-center"><p class="text-gray-500 text-sm">Loading PDF preview...</p></div>'

      const pdfjs = await loadPdfJs()

      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('PDF loading timeout')), 10000)
      )

      const pdf = await Promise.race([
        pdfjs.getDocument(pdfUrl).promise,
        timeoutPromise,
      ])
      const page = await pdf.getPage(1)

      const scale = 0.8
      const viewport = page.getViewport({ scale })
      const canvas = document.createElement('canvas')
      const context = canvas.getContext('2d')

      canvas.height = viewport.height
      canvas.width = viewport.width
      canvas.className =
        'max-w-full h-auto rounded border shadow-sm cursor-pointer hover:shadow-md transition-shadow'

      await page.render({
        canvasContext: context,
        viewport: viewport,
      }).promise

      previewContainer.innerHTML = ''
      previewContainer.appendChild(canvas)

      canvas.addEventListener('click', () => {
        this.pushEvent('download_pdf', { uploadId: this.el.dataset.uploadId })
      })
    } catch (error) {
      console.error('PDF preview generation failed:', error)

      // Determine error message based on error type
      let errorMessage = 'Preview unavailable'
      let errorDetail = 'Unable to load PDF preview'

      if (error.name === 'InvalidPDFException') {
        errorMessage = 'Invalid PDF file'
        errorDetail = 'The file appears to be corrupted'
      } else if (
        error.name === 'MissingPDFException' ||
        error.message?.includes('404')
      ) {
        errorMessage = 'PDF not found'
        errorDetail = 'The file could not be loaded'
      } else if (error.message?.includes('worker')) {
        errorMessage = 'Loading error'
        errorDetail = 'PDF viewer temporarily unavailable'
      } else if (error.message?.includes('timeout')) {
        errorMessage = 'Loading timeout'
        errorDetail = 'The PDF is taking too long to load'
      } else if (error.message?.includes('PDF viewer unavailable')) {
        errorMessage = 'Service unavailable'
        errorDetail = 'PDF viewer could not be loaded'
      }

      previewContainer.innerHTML = `
        <div class="flex items-center justify-center h-48 bg-red-50 rounded border border-red-200">
          <div class="text-center">
            <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <p class="mt-2 text-sm font-medium text-red-800">${errorMessage}</p>
            <p class="mt-1 text-xs text-red-600">${errorDetail}</p>
            <p class="mt-2 text-xs text-gray-500">Use the download button below to access the file</p>
          </div>
        </div>
      `
    }
  },
}
