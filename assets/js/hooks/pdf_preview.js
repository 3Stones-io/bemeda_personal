const PDFJS_CDN_URL =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.8.69/pdf.min.mjs'
const PDFJS_WORKER_URL =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.8.69/pdf.worker.min.mjs'

const CONFIG = {
  maxThumbnailHeight: 120,
  maxPagesDisplayed: 4,
  thumbnailGap: 12,
  loadingTimeout: 5000,
}

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
    const maxPages =
      parseInt(this.el.dataset.maxPages) || CONFIG.maxPagesDisplayed

    if (!pdfUrl || !previewContainer) return

    try {
      previewContainer.innerHTML = this.createLoadingState()

      const pdfjs = await loadPdfJs()
      const pdf = await this.loadPdfWithTimeout(pdfjs, pdfUrl)

      await this.renderMultiPageThumbnails(pdf, previewContainer)
    } catch (error) {
      console.error('PDF preview generation failed:', error)

      // Try fallback to single page rendering for compatibility
      if (
        error.message?.includes('no pages') ||
        error.name === 'InvalidPDFException'
      ) {
        previewContainer.innerHTML = this.createErrorState(error)
      } else {
        try {
          const pdfjs = await loadPdfJs()
          const pdf = await this.loadPdfWithTimeout(pdfjs, pdfUrl)
          await this.fallbackToSinglePage(pdf, previewContainer)
        } catch (fallbackError) {
          console.error('Fallback rendering also failed:', fallbackError)
          previewContainer.innerHTML = this.createErrorState(error)
        }
      }
    }
  },

  async loadPdfWithTimeout(pdfjs, pdfUrl) {
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(
        () => reject(new Error('PDF loading timeout')),
        CONFIG.loadingTimeout
      )
    )

    return await Promise.race([
      pdfjs.getDocument(pdfUrl).promise,
      timeoutPromise,
    ])
  },

  async renderMultiPageThumbnails(pdf, container) {
    const layout = this.calculateResponsiveLayout()
    // Show all pages if document has 3 or fewer pages, otherwise respect responsive limits
    const pageCount =
      pdf.numPages <= 3 ? pdf.numPages : Math.min(layout.maxPages, pdf.numPages)

    if (pageCount === 0) {
      throw new Error('PDF contains no pages')
    }

    const pagesContainer = document.createElement('div')
    pagesContainer.className =
      'flex gap-3 overflow-x-auto scrollbar-thin scrollbar-thumb-gray-300 p-3'

    const pagePromises = []
    for (let i = 1; i <= pageCount; i++) {
      pagePromises.push(pdf.getPage(i))
    }

    const pages = await Promise.all(pagePromises)

    const thumbnailPromises = pages.map((page, index) =>
      this.createThumbnail(page, index + 1, pageCount, layout.thumbnailHeight)
    )

    const thumbnails = await Promise.all(thumbnailPromises)

    thumbnails.forEach((thumbnailContainer) => {
      pagesContainer.appendChild(thumbnailContainer)
    })

    container.innerHTML = ''
    container.appendChild(pagesContainer)

    if (pdf.numPages > pageCount) {
      container.appendChild(this.createPageIndicator(pageCount, pdf.numPages))
    }
  },

  calculateResponsiveLayout() {
    const containerWidth = this.el.offsetWidth
    const isMobile = containerWidth < 480
    const isTablet = containerWidth >= 480 && containerWidth < 768
    const isLarge = containerWidth >= 768

    if (isMobile) {
      return {
        maxPages: 3,
        thumbnailHeight: 100,
      }
    } else if (isTablet) {
      return {
        maxPages: 4,
        thumbnailHeight: 120,
      }
    } else if (isLarge) {
      return {
        maxPages: 4,
        thumbnailHeight: 120,
      }
    } else {
      return {
        maxPages: 3,
        thumbnailHeight: 120,
      }
    }
  },

  async createThumbnail(
    page,
    pageNum,
    totalDisplayed,
    thumbnailHeight = CONFIG.maxThumbnailHeight
  ) {
    const containerWidth = this.el.offsetWidth
    const availableWidth =
      (containerWidth - (totalDisplayed - 1) * CONFIG.thumbnailGap) /
      totalDisplayed

    const viewport = page.getViewport({ scale: 1 })
    const scaleByWidth = availableWidth / viewport.width
    const scaleByHeight = thumbnailHeight / viewport.height
    const scale = Math.min(scaleByWidth, scaleByHeight)

    const scaledViewport = page.getViewport({ scale })

    const canvas = document.createElement('canvas')
    canvas.width = scaledViewport.width
    canvas.height = scaledViewport.height
    canvas.className =
      'cursor-pointer hover:ring-2 hover:ring-blue-500 rounded border shadow-sm transition-all duration-200'

    const renderTask = page.render({
      canvasContext: canvas.getContext('2d'),
      viewport: scaledViewport,
    })

    if (!this.renderTasks) this.renderTasks = []
    this.renderTasks.push(renderTask)

    await renderTask.promise

    const thumbnailContainer = document.createElement('div')
    thumbnailContainer.className = 'flex-shrink-0 text-center'

    const pageLabel = document.createElement('div')
    pageLabel.className = 'text-xs text-gray-500 mt-1'
    pageLabel.textContent = `Page ${pageNum}`

    thumbnailContainer.appendChild(canvas)
    thumbnailContainer.appendChild(pageLabel)

    canvas.addEventListener('click', () => {
      this.pushEvent('download_pdf', {
        'upload-id': this.el.dataset.uploadId,
        page: pageNum,
      })
    })

    return thumbnailContainer
  },

  createLoadingState() {
    return `
      <div class="animate-pulse bg-gray-200 h-[120px] rounded flex items-center justify-center">
        <p class="text-gray-500 text-sm">${this.translations.loadingText}</p>
      </div>
    `
  },

  createErrorState(error) {
    const errorMessage = this.getErrorMessage(error)
    const errorDetail = this.getErrorDetail(error)

    return `
      <div class="flex items-center justify-center h-[120px] bg-red-50 rounded border border-red-200">
        <div class="text-center">
          <svg class="mx-auto h-8 w-8 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <p class="mt-2 text-sm font-medium text-red-800">${errorMessage}</p>
          <p class="mt-1 text-xs text-red-600">${errorDetail}</p>
          <p class="mt-2 text-xs text-gray-500">${this.translations.accessFileMessage}</p>
        </div>
      </div>
    `
  },

  createPageIndicator(displayed, total) {
    const indicator = document.createElement('div')
    indicator.className = 'text-xs text-gray-500 text-center mt-2'
    indicator.textContent = `Showing ${displayed} of ${total} pages`
    return indicator
  },

  getErrorMessage(error) {
    if (error.name === 'InvalidPDFException') {
      return this.translations.invalidPdf
    } else if (
      error.name === 'MissingPDFException' ||
      error.message?.includes('404')
    ) {
      return this.translations.pdfNotFound
    } else if (error.message?.includes('worker')) {
      return this.translations.loadingError
    } else if (error.message?.includes('timeout')) {
      return this.translations.loadingTimeout
    } else if (error.message?.includes('PDF viewer unavailable')) {
      return this.translations.serviceUnavailable
    }
    return this.translations.previewUnavailable
  },

  getErrorDetail(error) {
    if (error.name === 'InvalidPDFException') {
      return this.translations.fileCorrupted
    } else if (
      error.name === 'MissingPDFException' ||
      error.message?.includes('404')
    ) {
      return this.translations.fileNotLoaded
    } else if (error.message?.includes('worker')) {
      return this.translations.viewerUnavailable
    } else if (error.message?.includes('timeout')) {
      return this.translations.timeoutDetails
    } else if (error.message?.includes('PDF viewer unavailable')) {
      return this.translations.viewerNotLoaded
    }
    return this.translations.detailsUnavailable
  },

  async fallbackToSinglePage(pdf, container) {
    try {
      const page = await pdf.getPage(1)
      const thumbnail = await this.createThumbnail(page, 1, 1)
      container.innerHTML = ''
      container.appendChild(thumbnail)
    } catch (fallbackError) {
      container.innerHTML = this.createErrorState(fallbackError)
    }
  },

  destroyed() {
    if (this.renderTasks) {
      this.renderTasks.forEach((task) => {
        if (task.cancel) task.cancel()
      })
    }

    if (this.loadingTimeout) {
      clearTimeout(this.loadingTimeout)
    }
  },
}
