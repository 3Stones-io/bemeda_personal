import 'dragster'

export default VideoUpload = {
  mounted() {
    const hook = this;
    const videoUploadContainer = hook.el;
    const input = videoUploadContainer.querySelector('#hidden-file-input');

    const restoreDropzoneStyles = () => {
      videoUploadContainer.classList.remove('border-indigo-600')
      videoUploadContainer.classList.add('border-gray-300')
      videoUploadContainer.classList.remove('dropzone')
    }

    const uploadVideo = (newFiles) => {
      hook.pushEventTo("#job-posting-form",
        "upload-video",
        {
          files: newFiles
        },
        ({upload_url: uploadUrl}) => {
          async function uploadVideo(file, uploadUrl) {
            try {
              const response = await fetch(uploadUrl, {
                method: 'PUT',
                body: file,
                headers: {
                  'Content-Type': newFiles.type
                }
              });
      
              if (response.ok) {
                console.log('Video upload successful!');
              } else {
                console.log(response)
                console.error('Video upload failed:', response.status);
              }
            } catch (error) {
              console.error('Error during upload:', error);
            }
          }

          uploadVideo(newFiles, uploadUrl)
        }
      )
    }

    new Dragster(videoUploadContainer);

    videoUploadContainer.addEventListener(
      'dragster:enter',
      () => {
        videoUploadContainer.classList.remove('border-gray-300')
        videoUploadContainer.classList.add('border-indigo-600')
        videoUploadContainer.classList.add('dropzone')
      },
      false
    )

    videoUploadContainer.addEventListener(
      'dragster:leave',
      () => {
        restoreDropzoneStyles()
      },
      false
    )

    videoUploadContainer.addEventListener('drop', (event) => {
      event.preventDefault()

      let newFiles = Array.from(event.dataTransfer.files || [])

      uploadVideo(newFiles[0])

      restoreDropzoneStyles()
    })

    videoUploadContainer.addEventListener('dragenter', (e) => e.preventDefault())
    videoUploadContainer.addEventListener('dragover', (e) => e.preventDefault())

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadVideo(newFiles[0])
    })
  }
}


