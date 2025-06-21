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
    this.initializeTranslations()
    this.generatePreview()
  },

  updated() {
    this.generatePreview()
  },

  initializeTranslations() {
    this.translations = {
      loadingText: this.el.dataset.loadingText || 'Loading PDF preview...',
      previewUnavailable:
        this.el.dataset.errorPreviewUnavailable || 'Preview unavailable',
      detailsUnavailable:
        this.el.dataset.errorDetailsUnavailable || 'Unable to load PDF preview',
      invalidPdf: this.el.dataset.errorInvalidPdf || 'Invalid PDF file',
      fileCorrupted:
        this.el.dataset.errorFileCorrupted ||
        'The file appears to be corrupted',
      pdfNotFound: this.el.dataset.errorNotFound || 'PDF not found',
      fileNotLoaded:
        this.el.dataset.errorFileNotLoaded || 'The file could not be loaded',
      loadingError: this.el.dataset.errorLoading || 'Loading error',
      viewerUnavailable:
        this.el.dataset.errorViewerUnavailable ||
        'PDF viewer temporarily unavailable',
      loadingTimeout: this.el.dataset.errorTimeout || 'Loading timeout',
      timeoutDetails:
        this.el.dataset.errorTimeoutDetails ||
        'The PDF is taking too long to load',
      serviceUnavailable:
        this.el.dataset.errorServiceUnavailable || 'Service unavailable',
      viewerNotLoaded:
        this.el.dataset.errorViewerNotLoaded ||
        'PDF viewer could not be loaded',
      accessFileMessage:
        this.el.dataset.accessFileMessage ||
        'Use the download button below to access the file',
    }
  },

  async generatePreview() {
    const pdfUrl = this.el.dataset.pdfUrl
    const previewContainer = this.el.querySelector('.pdf-preview-container')

    if (!pdfUrl || !previewContainer) return

    try {
      previewContainer.innerHTML = `<div class="animate-pulse bg-gray-200 h-48 rounded flex items-center justify-center"><p class="text-gray-500 text-sm">${this.translations.loadingText}</p></div>`

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
      let errorMessage = this.translations.previewUnavailable
      let errorDetail = this.translations.detailsUnavailable

      if (error.name === 'InvalidPDFException') {
        errorMessage = this.translations.invalidPdf
        errorDetail = this.translations.fileCorrupted
      } else if (
        error.name === 'MissingPDFException' ||
        error.message?.includes('404')
      ) {
        errorMessage = this.translations.pdfNotFound
        errorDetail = this.translations.fileNotLoaded
      } else if (error.message?.includes('worker')) {
        errorMessage = this.translations.loadingError
        errorDetail = this.translations.viewerUnavailable
      } else if (error.message?.includes('timeout')) {
        errorMessage = this.translations.loadingTimeout
        errorDetail = this.translations.timeoutDetails
      } else if (error.message?.includes('PDF viewer unavailable')) {
        errorMessage = this.translations.serviceUnavailable
        errorDetail = this.translations.viewerNotLoaded
      }

      previewContainer.innerHTML = `
        <div class="flex items-center justify-center h-48 bg-red-50 rounded border border-red-200">
          <div class="text-center">
            <svg class="mx-auto h-12 w-12 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <p class="mt-2 text-sm font-medium text-red-800">${errorMessage}</p>
            <p class="mt-1 text-xs text-red-600">${errorDetail}</p>
            <p class="mt-2 text-xs text-gray-500">${this.translations.accessFileMessage}</p>
          </div>
        </div>
      `
    }
  },
}
