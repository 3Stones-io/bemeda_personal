import 'dragster'
import * as UpChunk from '@mux/upchunk'
import generateImageThumbnail from '../utils/image_thumbnail_generator'
import generateVideoThumbnail from '../utils/video_thumbnail_generator'

export default FileUpload = {
  initializeTranslations() {
    this.translations = {
      uploadError:
        this.el.dataset.uploadErrorText ||
        'An error has occurred, please try again',
      completed: this.el.dataset.uploadCompletedText || 'Completed',
    }
  },

  mounted() {
    this.initializeTranslations()
    const hook = this
    const fileUploadInput = hook.el
    const fileUploadInputsContainer = fileUploadInput.querySelector(
      '[id$="-file-upload-inputs-container"]'
    )
    const eventsTarget = fileUploadInput.dataset.eventsTarget

    const input = fileUploadInput.querySelector('[id$="-hidden-file-input"]')
    const assetDescription = document.querySelector('#asset-description')

    const uploadProgressElement = document.querySelector(
      '.file-upload-progress'
    )
    const progressCircle =
      uploadProgressElement?.querySelector('.progress-circle')
    const cancelButton =
      uploadProgressElement?.querySelector('.upload-cancel-btn')

    const videoPreview = document.querySelector('.video-preview')
    const imageContainer = uploadProgressElement?.querySelector(
      '.image-container img'
    )
    const imageUploadContainer = fileUploadInput.querySelector(
      'button[type="button"]'
    )

    const previewImage = fileUploadInput.querySelector('[id$="-preview-image"]')
    const avatarProgressCircle = fileUploadInput.querySelector(
      '[id$="-progress-circle"]'
    )
    const avatarProgressIndicator = fileUploadInput.querySelector(
      '[id$="-progress-indicator"]'
    )

    let currentUpload

    const restoreDropzoneStyles = () => {
      if (fileUploadInputsContainer) {
        fileUploadInputsContainer.classList.remove('border-indigo-600')
        fileUploadInputsContainer.classList.add('border-gray-300')
        fileUploadInputsContainer.classList.remove('dropzone')
      }
    }

    const cancelUpload = () => {
      if (currentUpload) {
        currentUpload.abort()
        currentUpload = null
      }

      if (uploadProgressElement) {
        uploadProgressElement.classList.add('hidden')
      }

      if (fileUploadInputsContainer) {
        fileUploadInputsContainer.classList.remove('hidden')
      }

      if (imageUploadContainer) {
        imageUploadContainer.classList.remove('hidden')
      }

      hook.pushEventTo(`#${eventsTarget}`, 'upload_cancelled')
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

      const generateThumbnail = async (file) => {
        if (file.type.startsWith('video/')) {
          return await generateVideoThumbnail(file, [300, 300])
        } else if (file.type.startsWith('image/')) {
          return await generateImageThumbnail(file, [300, 300])
        } else {
          return null
        }
      }
      const getPayload = async () => {
        let thumbnail = await generateThumbnail(file)
        return {
          filename: file.name,
          thumbnail: thumbnail,
          type: file.type,
        }
      }

      getPayload().then((payload) => {
        hook.pushEventTo(
          `#${eventsTarget}`,
          'upload_file',
          { filename: payload.filename, type: payload.type },
          (response) => {
            if (response.error) {
              // Put error message with an exclamation icon
              if (uploadProgressElement) {
                uploadProgressElement.classList.remove('hidden')
              }

              hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')

              return
            }

            if (uploadProgressElement) {
              uploadProgressElement.classList.remove('hidden')
            }

            if (imageUploadContainer) {
              imageUploadContainer.classList.add('hidden')
            }

            if (fileUploadInputsContainer) {
              fileUploadInputsContainer.classList.add('hidden')
            }

            if (payload.thumbnail && imageContainer) {
              imageContainer.src = payload.thumbnail
            }

            if (payload.thumbnail && previewImage) {
              previewImage.src = payload.thumbnail
            }

            if (avatarProgressCircle) {
              avatarProgressCircle.classList.remove('hidden')
            }

            if (avatarProgressIndicator) {
              avatarProgressIndicator.style.strokeDasharray = '0 302'
            }

            if (progressCircle) {
              progressCircle.style.strokeDasharray = '0, 100'
            }

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

              if (progressCircle) {
                progressCircle.style.strokeDasharray = `${progress}, 100`
              }

              if (avatarProgressIndicator) {
                const circumference = 2 * Math.PI * 48
                const progressValue = (progress / 100) * circumference
                avatarProgressIndicator.style.strokeDasharray = `${progressValue} ${circumference}`
              }
            })

            currentUpload.on('error', (_error) => {
              hook.pushEventTo(`#${eventsTarget}`, 'enable-submit')
            })

            currentUpload.on('success', (_entry) => {
              if (uploadProgressElement) {
                uploadProgressElement.classList.add('hidden')
              }

              if (avatarProgressCircle) {
                avatarProgressCircle.classList.add('hidden')
              }

              if (assetDescription) {
                assetDescription.classList.remove('hidden')
              }

              hook.pushEventTo(
                `#${eventsTarget}`,
                'upload_completed',
                { upload_id: response.upload_id },
                (response) => {
                  if (response.video_url && videoPreview) {
                    videoPreview.classList.remove('hidden')
                    const videoSource = videoPreview.querySelector('source')
                    if (videoSource) {
                      videoSource.src = response.video_url
                    }
                    const videoElement = videoPreview.querySelector('video')
                    if (videoElement) {
                      videoElement.load()
                    }
                  }
                }
              )
            })
          }
        )
      })
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

    if (cancelButton) {
      cancelButton.addEventListener('click', () => {
        cancelUpload()
      })
    }

    if (fileUploadInputsContainer) {
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
    }

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadFile(newFiles[0])
    })
  },
}
