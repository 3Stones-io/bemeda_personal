import 'dragster'
import * as UpChunk from '@mux/upchunk'

export default VideoUpload = {
  mounted() {
    const hook = this
    const videoUploadContainer = hook.el
    const videoUploadInputsContainer = videoUploadContainer.querySelector('#video-upload-inputs-container')

    const filenameElement = videoUploadContainer.querySelector(`#company-job-form-upload-filename`)
    const input = videoUploadContainer.querySelector('#hidden-file-input')
    const percentageElement = videoUploadContainer.querySelector(`#company-job-form-upload-percentage`)
    const progressElement = videoUploadContainer.querySelector(`#company-job-form-upload-progress`)
    const sizeElement = videoUploadContainer.querySelector(`#company-job-form-upload-size`)

    const videoUploadProgressContainer = videoUploadContainer.querySelector(`#video-upload-progress-container`)
    const uploadProgressBar = videoUploadProgressContainer.querySelector(`#upload-progress-bar`)

    const fileSizeSI = (bytes) => {
      const exponent = Math.floor(Math.log(bytes) / Math.log(1000.0))
      const decimal = (bytes / Math.pow(1000.0, exponent)).toFixed(exponent ? 2 : 0)
      return `${decimal} ${exponent ? `${'kMGTPEZY'[exponent - 1]}B` : 'B'}`
    }

    const restoreDropzoneStyles = () => {
      videoUploadInputsContainer.classList.remove('border-indigo-600')
      videoUploadInputsContainer.classList.add('border-gray-300')
      videoUploadInputsContainer.classList.remove('dropzone')
    }

    const uploadVideo = (newFiles) => {
      hook.pushEventTo("#job-posting-form",
        "upload-video",
        {},
        ({ upload_url: uploadUrl }) => {
          videoUploadProgressContainer.classList.remove('hidden')
          filenameElement.textContent = newFiles.name
          sizeElement.textContent = fileSizeSI(newFiles.size)

          const upload = UpChunk.createUpload({
            endpoint: uploadUrl,
            file: newFiles,
            chunkSize: 30720,
          });

          upload.on('progress', (entry) => {
            let progress = Math.round(entry.detail)
            console.log(progress)
            percentageElement.textContent = `${progress}%`
            progressElement.setAttribute('aria-valuenow', progress)
            uploadProgressBar.style.width = `${progress}%`
          })

          upload.on('error', (_error) => {
            uploadProgressBar.classList.remove('bg-indigo-600')
            uploadProgressBar.classList.add('bg-red-600')
            percentageElement.textContent = 'An error has occurred, please try again'
          })

          upload.on('success', () => {
            percentageElement.textContent = 'Completed'
          })
        }
      )
    }

    new Dragster(videoUploadContainer);

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

    videoUploadInputsContainer.addEventListener('dragenter', (e) => e.preventDefault())
    videoUploadInputsContainer.addEventListener('dragover', (e) => e.preventDefault())

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadVideo(newFiles[0])
    })
  },
}


