import * as UpChunk from "@mux/upchunk"

let Uploaders = {}

Uploaders.UpChunk = function(entries, onViewError){
  entries.forEach(entry => {
    console.log(entry, "ENTRY")
    // create the upload session with UpChunk
    let { file, meta: { endpoint } } = entry
    console.log(endpoint, "ENTRYPOINT")
    let upload = UpChunk.createUpload({ 
        endpoint: endpoint, 
        method: "PUT",
        file 
      })

    // stop uploading in the event of a view error
    onViewError(() => upload.pause())

    // upload error triggers LiveView error
    upload.on("error", (e) => {
      console.log(e, "ERROR")
      entry.error(e.detail.message)
    })

    // notify progress events to LiveView
    upload.on("progress", (e) => {
      console.log(e.detail, "PROGRESS")
      if(e.detail < 100){ entry.progress(e.detail) }
    })

    // success completes the UploadEntry
    upload.on("success", () => entry.progress(100))
  })
}

export default Uploaders