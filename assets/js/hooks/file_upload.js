import 'dragster'
import * as UpChunk from '@mux/upchunk'

export default FileUpload = {
  mounted() {
    const hook = this
    const fileUploadInput = hook.el
    const fileUploadInputsContainer = fileUploadInput.querySelector(
      '#file-upload-inputs-container'
    )
    const eventsTarget = fileUploadInput.dataset.eventsTarget

    const input = fileUploadInput.querySelector('#hidden-file-input')
    const assetDescription = document.querySelector('#asset-description')

    const uploadProgressElement = document.querySelector(
      '.file-upload-progress'
    )

    const filenameElement =
      uploadProgressElement.querySelector('#upload-filename')
    const fileSizeElement = uploadProgressElement.querySelector('#upload-size')
    const percentageElement =
      uploadProgressElement.querySelector('#upload-percentage')
    const progressBar = uploadProgressElement.querySelector(
      '#upload-progress-bar'
    )
    const progressElement =
      uploadProgressElement.querySelector('#upload-progress')

    let currentUpload

    const restoreDropzoneStyles = () => {
      fileUploadInputsContainer.classList.remove('border-indigo-600')
      fileUploadInputsContainer.classList.add('border-gray-300')
      fileUploadInputsContainer.classList.remove('dropzone')
    }

    const fileSizeSI = (bytes) => {
      const exponent = Math.floor(Math.log(bytes) / Math.log(1000.0))
      const decimal = (bytes / Math.pow(1000.0, exponent)).toFixed(
        exponent ? 2 : 0
      )
      return `${decimal} ${exponent ? `${'kMGTPEZY'[exponent - 1]}B` : 'B'}`
    }

    const uploadFile = (file) => {
      if (currentUpload) {
        currentUpload.abort()
        currentUpload = null
      }

      hook.pushEventTo(
        `#${eventsTarget}`,
        'upload-file',
        { filename: file.name, type: file.type },
        (response) => {
          if (response.error) {
            uploadProgressElement.classList.remove('hidden')
            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent = response.error

            hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')

            return
          }

          progressBar.classList.add('bg-indigo-600')
          progressBar.classList.remove('bg-green-600')
          uploadProgressElement.classList.remove('hidden')
          filenameElement.textContent = file.name
          fileSizeElement.textContent = fileSizeSI(file.size)

          currentUpload = UpChunk.createUpload({
            endpoint: response.upload_url,
            file: file,
            chunkSize: 30720,
            method: 'PUT',
            headers: {
              'Content-Type': file.type,
            },
          })

          currentUpload.on('progress', (entry) => {
            let progress = Math.round(entry.detail)

            percentageElement.textContent = `${progress}%`
            progressElement.setAttribute('aria-valuenow', progress)
            progressBar.style.width = `${progress}%`
          })

          currentUpload.on('error', (_error) => {
            hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')

            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent =
              'An error has occurred, please try again'
          })

          currentUpload.on('success', (_entry) => {
            progressBar.classList.remove('bg-blue-500')
            progressBar.classList.add('bg-green-600')
            progressBar.classList.remove('processing-bar')
            percentageElement.textContent = 'Completed'

            hook.pushEventTo(`#${eventsTarget}`, 'upload-completed')
          })
        }
      )
    }

    const deleteButton = assetDescription?.querySelector(
      'button[type="button"]'
    )
    if (deleteButton) {
      deleteButton.addEventListener('click', () => {
        fileUploadInput.classList.remove('hidden')
        assetDescription.classList.add('hidden')
        hook.pushEventTo(`#${eventsTarget}`, 'delete_file')
      })
    }

    new Dragster(fileUploadInput)

    fileUploadInputsContainer.addEventListener(
      'dragster:enter',
      () => {
        fileUploadInputsContainer.classList.remove('border-gray-300')
        fileUploadInputsContainer.classList.add('border-indigo-600')
        fileUploadInputsContainer.classList.add('dropzone')
      },
      false
    )

    fileUploadInputsContainer.addEventListener(
      'dragster:leave',
      () => {
        restoreDropzoneStyles()
      },
      false
    )

    fileUploadInputsContainer.addEventListener('drop', (event) => {
      event.preventDefault()

      let newFiles = Array.from(event.dataTransfer.files || [])

      uploadFile(newFiles[0])

      restoreDropzoneStyles()
    })

    fileUploadInputsContainer.addEventListener('dragenter', (e) =>
      e.preventDefault()
    )
    fileUploadInputsContainer.addEventListener('dragover', (e) =>
      e.preventDefault()
    )

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadFile(newFiles[0])
    })
  },
}
