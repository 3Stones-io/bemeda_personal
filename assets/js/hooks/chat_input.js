import 'dragster'
import * as UpChunk from '@mux/upchunk'

export default ChatInput = {
  mounted() {
    const hook = this
    const chatInput = hook.el
    const fileInput = chatInput.querySelector('#hidden-file-input')

    const restoreDropzoneStyles = () => {
      chatInput.classList.remove('border-2')
      chatInput.classList.remove('border-dashed')
      chatInput.classList.remove('border-indigo-600')
    }

    const uploadFile = (file) => {
      hook.pushEvent(
        'upload-media',
        { filename: file.name, type: file.type },
        ({ upload_url: uploadUrl, message_id: messageId }) => {
          const upload = UpChunk.createUpload({
            endpoint: uploadUrl,
            file: file,
            chunkSize: 30720,
            method: 'PUT',
            headers: {
              'Content-Type': file.type,
            },
          })

          upload.on('error', (e) => {
            console.log('error', e.detail)
          })

          upload.on('success', () => {
            hook.pushEvent('update-message', {
              message_id: messageId,
              status: 'uploaded',
            })
          })
        }
      )
    }

    new Dragster(chatInput)

    chatInput.addEventListener('dragster:enter', () => {
      chatInput.classList.add('border-2')
      chatInput.classList.add('border-dashed')
      chatInput.classList.add('border-indigo-600')
    })

    chatInput.addEventListener('dragster:leave', () => {
      restoreDropzoneStyles()
    })

    chatInput.addEventListener('drop', (event) => {
      event.preventDefault()

      let newFiles = Array.from(event.dataTransfer.files || [])

      uploadFile(newFiles[0])

      restoreDropzoneStyles()
    })

    chatInput.addEventListener('dragenter', (e) => e.preventDefault())
    chatInput.addEventListener('dragover', (e) => e.preventDefault())

    fileInput.addEventListener('change', () => {
      let newFiles = Array.from(fileInput.files || [])

      uploadFile(newFiles[0])
    })
  },
}
