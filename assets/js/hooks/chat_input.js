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

    const uploadFile = (newFiles) => {
      hook.pushEvent(
        'upload-media',
        { filename: newFiles.name, type: newFiles.type },
        ({ upload_url: uploadUrl }) => {
          UpChunk.createUpload({
            endpoint: uploadUrl,
            file: newFiles,
            chunkSize: 30720,
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
