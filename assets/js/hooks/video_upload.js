import 'dragster'
import * as UpChunk from '@mux/upchunk'

export default VideoUpload = {
  mounted() {
    const hook = this
    const videoUploadInput = hook.el
    const videoUploadInputsContainer = videoUploadInput.querySelector(
      '#video-upload-inputs-container'
    )
    const input = videoUploadInput.querySelector('#hidden-file-input')
    const videoDescription = document.querySelector(
      '#job-posting-form-video-description'
    )

    const uploadProgressElement = document.querySelector(
      '.job-form-video-upload-progress'
    )
    const filenameElement = uploadProgressElement.querySelector(
      '#company-job-form-video-upload-filename'
    )
    const fileSizeElement = uploadProgressElement.querySelector(
      '#company-job-form-video-upload-size'
    )
    const percentageElement = uploadProgressElement.querySelector(
      '#company-job-form-video-upload-percentage'
    )
    const progressBar = uploadProgressElement.querySelector(
      '#company-job-form-video-upload-progress-bar'
    )
    const progressElement = uploadProgressElement.querySelector(
      '#company-job-form-video-upload-progress'
    )

    let currentUpload

    const restoreDropzoneStyles = () => {
      videoUploadInputsContainer.classList.remove('border-indigo-600')
      videoUploadInputsContainer.classList.add('border-gray-300')
      videoUploadInputsContainer.classList.remove('dropzone')
    }

    const fileSizeSI = (bytes) => {
      const exponent = Math.floor(Math.log(bytes) / Math.log(1000.0))
      const decimal = (bytes / Math.pow(1000.0, exponent)).toFixed(
        exponent ? 2 : 0
      )
      return `${decimal} ${exponent ? `${'kMGTPEZY'[exponent - 1]}B` : 'B'}`
    }

    const uploadVideo = (newFiles) => {
      if (currentUpload) {
        currentUpload.abort()
        currentUpload = null
      }

      hook.pushEventTo(
        '#job-posting-form',
        'upload-video',
        { filename: newFiles.name },
        (response) => {
          if (response.error) {
            uploadProgressElement.classList.remove('hidden')
            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent = response.error

            hook.pushEventTo('#job-posting-form', 'enable-submit')
            return
          }

          uploadProgressElement.classList.remove('hidden')
          filenameElement.textContent = newFiles.name
          fileSizeElement.textContent = fileSizeSI(newFiles.size)

          currentUpload = UpChunk.createUpload({
            endpoint: response.upload_url,
            file: newFiles,
            chunkSize: 30720,
          })

          currentUpload.on('progress', (entry) => {
            let progress = Math.round(entry.detail)

            percentageElement.textContent = `${progress}%`
            progressElement.setAttribute('aria-valuenow', progress)
            progressBar.style.width = `${progress}%`
          })

          currentUpload.on('error', (_error) => {
            hook.pushEventTo('#job-posting-form', 'enable-submit')

            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent =
              'An error has occurred, please try again'
          })

          currentUpload.on('success', (_entry) => {
            hook.pushEventTo('#job-posting-form', 'enable-submit')

            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-green-600')
            percentageElement.textContent = 'Completed'
          })
        }
      )
    }

    // Handle delete button click
    const deleteButton = videoDescription?.querySelector(
      'button[type="button"]'
    )
    if (deleteButton) {
      deleteButton.addEventListener('click', () => {
        videoUploadInput.classList.remove('hidden')
        videoDescription.classList.add('hidden')
        hook.pushEventTo('#job-posting-form', 'edit-video')
      })
    }

    new Dragster(videoUploadInput)

    videoUploadInputsContainer.addEventListener(
      'dragster:enter',
      () => {
        videoUploadInputsContainer.classList.remove('border-gray-300')
        videoUploadInputsContainer.classList.add('border-indigo-600')
        videoUploadInputsContainer.classList.add('dropzone')
      },
      false
    )

    videoUploadInputsContainer.addEventListener(
      'dragster:leave',
      () => {
        restoreDropzoneStyles()
      },
      false
    )

    videoUploadInputsContainer.addEventListener('drop', (event) => {
      event.preventDefault()

      let newFiles = Array.from(event.dataTransfer.files || [])

      uploadVideo(newFiles[0])

      restoreDropzoneStyles()
    })

    videoUploadInputsContainer.addEventListener('dragenter', (e) =>
      e.preventDefault()
    )
    videoUploadInputsContainer.addEventListener('dragover', (e) =>
      e.preventDefault()
    )

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadVideo(newFiles[0])
    })
  },
}
