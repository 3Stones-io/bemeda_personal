import 'dragster'
import * as UpChunk from '@mux/upchunk'

export default VideoUpload = {
  mounted() {
    const hook = this
    const videoUploadInput = hook.el
    const videoUploadInputsContainer = videoUploadInput.querySelector(
      '#video-upload-inputs-container'
    )
    const eventsTarget = videoUploadInput.dataset.eventsTarget
    console.log(eventsTarget)

    const input = videoUploadInput.querySelector('#hidden-file-input')
    const videoDescription = document.querySelector('#video-description')

    const uploadProgressElement = document.querySelector(
      '.video-upload-progress'
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
    let uploadId

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
        `#${eventsTarget}`,
        'upload-video',
        { filename: newFiles.name, type: newFiles.type },
        (response) => {
          if (response.error) {
            uploadProgressElement.classList.remove('hidden')
            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent = response.error

            hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')

            return
          }

          uploadId = response.upload_id

          progressBar.classList.add('bg-indigo-600')
          progressBar.classList.remove('bg-green-600')
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
            hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')

            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-red-600')
            percentageElement.textContent =
              'An error has occurred, please try again'
          })

          currentUpload.on('success', (_entry) => {
            progressBar.classList.remove('bg-indigo-600')
            progressBar.classList.add('bg-blue-500')
            progressBar.classList.add('processing-bar')
            percentageElement.textContent = 'Processing...'

            progressBar.style.width = '100%'

            hook.pushEventTo(`#${eventsTarget}`, 'upload-completed', {
              upload_id: uploadId,
            })

            hook.handleEvent('video_upload_completed', () => {
              progressBar.classList.remove('bg-blue-500')
              progressBar.classList.add('bg-green-600')
              progressBar.classList.remove('processing-bar')
              percentageElement.textContent = 'Completed'
            })
          })
        }
      )
    }

    const deleteButton = videoDescription?.querySelector(
      'button[type="button"]'
    )
    if (deleteButton) {
      deleteButton.addEventListener('click', () => {
        videoUploadInput.classList.remove('hidden')
        videoDescription.classList.add('hidden')
        hook.pushEventTo(`#${eventsTarget}`, 'edit-video')
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
