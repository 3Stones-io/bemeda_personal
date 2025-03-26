defmodule BemedaPersonalWeb.VideoUploadsLive.Index do
  use BemedaPersonalWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:uploads, [])

    {:ok, socket, layout: false}
  end

  # Upload begin inside the form component -> On drag/drop or input -> send a custom event to this view which is mounted
  # Should only be accessible to people who have rights to a company -> that way a user can post multiple jobs without worrying about uploads
  # Show uploads icon (animated if there are ongoing uploads)
  # We start upload from here and notify the form about the upload_id(helps to keep track of the upload later)
  # Track progress from here + If the form is still on the page, also show the progress there
  # Upload is complete -> Find the job by the upload_id and update the job with the upload_id with asset and playback id
  # User opens a job posting of an job whose upload is incomplete(no playback_id), don't show the video
  # User can also delete the upload from here -> Maybe not now!?
  # Reusing the same component to track the upload progress -> Move this to job_posting components
  # If the user closes the tab, the upload should still be there and show progresss
end
