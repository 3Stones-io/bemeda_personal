import 'dragster'

export default VideoUpload = {
  mounted() {
    const hook = this;
    const videoUploadContainer = hook.el;
    
    // Debug: log the container and its ID
    console.log("Video upload container:", videoUploadContainer);
    console.log("Container ID:", videoUploadContainer.id);
    
    // Extract the base ID, but now we're using class-based selectors so this is only for debugging
    const baseId = videoUploadContainer.id.replace('-video-upload', '');
    console.log("Base ID (for debugging only):", baseId);
    
    // Find the file input within the container - still need this
    const input = videoUploadContainer.querySelector(`#${baseId}-video-upload-input`);
    console.log("Input element:", input);

    // Handle video-processing event from server
    hook.handleEvent("video-processing", () => {
      console.log("Received video-processing event");
      
      // Use the same direct element approach
      const uploadStatus = videoUploadContainer.querySelector('.upload-status-container');
      const loadingState = uploadStatus.querySelector('[id$="-loading-state"]');
      const progressState = uploadStatus.querySelector('[id$="-progress-state"]');
      const errorState = uploadStatus.querySelector('[id$="-error-state"]');
      const successState = uploadStatus.querySelector('[id$="-success-state"]');
      
      if (!uploadStatus) {
        console.error("Upload status element not found for video-processing event");
        return;
      }
      
      // Show processing info
      uploadStatus.style.display = "block";
      loadingState.style.display = "none";
      progressState.style.display = "none";
      successState.style.display = "none";
      errorState.style.display = "none";
      
      // Show custom processing message
      const processingState = document.createElement('div');
      processingState.className = "flex items-center";
      processingState.innerHTML = `
        <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span>Video upload complete! Processing video...</span>
      `;
      
      uploadStatus.appendChild(processingState);
    });
    
    // Handle video-ready event from server
    hook.handleEvent("video-ready", ({ asset_id, playback_id }) => {
      console.log("Received video-ready event");
      
      // Use the same direct element approach
      const uploadStatus = videoUploadContainer.querySelector('.upload-status-container');
      const loadingState = uploadStatus.querySelector('[id$="-loading-state"]');
      const progressState = uploadStatus.querySelector('[id$="-progress-state"]');
      const errorState = uploadStatus.querySelector('[id$="-error-state"]');
      const successState = uploadStatus.querySelector('[id$="-success-state"]');
      
      if (!uploadStatus || !successState) {
        console.error("Required elements not found for video-ready event");
        return;
      }
      
      // Show success state
      uploadStatus.style.display = "block";
      loadingState.style.display = "none";
      progressState.style.display = "none";
      successState.style.display = "block";
      errorState.style.display = "none";
      
      console.log(`Video ready event received: asset_id=${asset_id}, playback_id=${playback_id}`);
      
      // Update success message with player if we have a playback ID
      if (playback_id) {
        successState.innerHTML = `
          <div class="text-green-600 flex items-center mb-2">
            <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
            </svg>
            Video processing complete!
          </div>
          <div class="mt-3 max-w-full aspect-video">
            <iframe
              src="https://stream.mux.com/${playback_id}.m3u8"
              class="w-full aspect-video"
              frameborder="0"
              allowfullscreen
            ></iframe>
          </div>
        `;
      }
    });

    const restoreDropzoneStyles = () => {
      videoUploadContainer.classList.remove('border-indigo-600')
      videoUploadContainer.classList.add('border-gray-300')
      videoUploadContainer.classList.remove('dropzone')
    }

    const uploadVideo = (newFiles) => {
      if (!newFiles || newFiles.length === 0) return;
      
      const file = newFiles[0];
      
      // More comprehensive debugging
      console.log("------------------- VIDEO UPLOAD DEBUG -------------------");
      console.log("Video file being uploaded:", file.name);
      console.log("Video upload container:", videoUploadContainer);
      
      // Try alternative selection methods - using direct child selection instead of IDs
      // These selectors should be more reliable since they don't depend on IDs
      const uploadStatus = videoUploadContainer.querySelector('.upload-status-container');
      const loadingState = uploadStatus.querySelector('[id$="-loading-state"]');
      const progressState = uploadStatus.querySelector('[id$="-progress-state"]');
      const errorState = uploadStatus.querySelector('[id$="-error-state"]');
      const successState = uploadStatus.querySelector('[id$="-success-state"]');
      const filename = progressState.querySelector('[id$="-filename"]');
      const progressBar = progressState.querySelector('[id$="-progress-bar"]');
      const progressText = progressState.querySelector('[id$="-progress-text"]');
      
      console.log("Elements found with alternative selectors:", {
        uploadStatus: !!uploadStatus,
        loadingState: !!loadingState,
        progressState: !!progressState,
        errorState: !!errorState,
        successState: !!successState,
        filename: !!filename,
        progressBar: !!progressBar,
        progressText: !!progressText
      });
      
      if (!uploadStatus || !loadingState || !progressState || !errorState || !successState || !progressBar || !progressText) {
        console.error("One or more upload UI elements not found");
        return;
      }
      
      // Show the container and loading state, hide other states
      uploadStatus.style.display = "block";
      loadingState.style.display = "flex";
      progressState.style.display = "none";
      errorState.style.display = "none";
      successState.style.display = "none";

      console.log("Requesting upload URL...");
      hook.pushEventTo(
        '#job-posting-form', 
        'begin-video-upload', 
        {},
        ({url, id, error}) => {
          if (error) {
            console.error("Upload error:", error);
            loadingState.style.display = "none";
            errorState.style.display = "block";
            errorState.textContent = `Error: ${error}`;
            return;
          }
          
          console.log("Got URL:", url, "ID:", id);
          
          // Hide loading state, show progress state
          loadingState.style.display = "none";
          progressState.style.display = "block";
          
          // Set filename
          filename.textContent = file.name;
          
          // Reset progress indicators
          progressBar.style.width = "0%";
          progressText.textContent = "0%";
          
          // Upload the file using XMLHttpRequest
          const xhr = new XMLHttpRequest();
          
          xhr.upload.addEventListener('progress', (event) => {
            if (event.lengthComputable) {
              const percentComplete = Math.round((event.loaded / event.total) * 100);
              console.log(`Upload progress: ${percentComplete}%`);
              
              // Update progress indicators
              progressBar.style.width = `${percentComplete}%`;
              progressText.textContent = `${percentComplete}%`;
            }
          });
          
          xhr.addEventListener('load', () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              // Success - hide progress, show wait for processing message
              progressState.style.display = "none";
              
              // Display a waiting message - updates will come via webhooks
              const processingDiv = document.createElement('div');
              processingDiv.className = "flex items-center";
              processingDiv.innerHTML = `
                <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span>Upload complete! Waiting for video processing...</span>
              `;
              
              // Clear and show the success state
              successState.innerHTML = '';
              successState.appendChild(processingDiv);
              successState.style.display = "block";
              
              // We don't need to notify the server about upload completion
              // The Mux webhooks will handle that automatically
              console.log("Upload successful, waiting for Mux webhooks for further processing");
              console.log("Asset info - ID from direct upload:", id);
            } else {
              // Error
              progressState.style.display = "none";
              errorState.style.display = "block";
              errorState.textContent = `Upload failed with status: ${xhr.status}`;
            }
          });
          
          xhr.addEventListener('error', () => {
            progressState.style.display = "none";
            errorState.style.display = "block";
            errorState.textContent = "Upload failed. Please try again.";
          });
          
          xhr.open('PUT', url, true);
          xhr.send(file);
        }
      );
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

      uploadVideo(newFiles)

      restoreDropzoneStyles()
    })

    videoUploadContainer.addEventListener('dragenter', (e) => e.preventDefault())
    videoUploadContainer.addEventListener('dragover', (e) => e.preventDefault())

    input.addEventListener('change', () => {
      let newFiles = Array.from(input.files || [])

      uploadVideo(newFiles)
    })
  }
}


