defmodule BemedaPersonalWeb.CompanyJobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting
  alias BemedaPersonalWeb.JobListComponent
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job_posting:company:#{socket.assigns.company.id}"
      )

      # Subscribe to video upload events using the global job-video topic
      Phoenix.PubSub.subscribe(
        BemedaPersonal.PubSub,
        "job-video"
      )
    end

    {:ok,
     socket
     |> assign(:job_posting, %JobPosting{})
     |> assign(:filters, %{company_id: socket.assigns.company.id})}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    job_posting = Jobs.get_job_posting!(id)

    if job_posting.company_id != socket.assigns.company.id do
      push_patch(socket, to: ~p"/companies/#{socket.assigns.company.id}/jobs")
    else
      socket
      |> assign(:page_title, "Edit Job")
      |> assign(:job_posting, job_posting)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Post New Job")
    |> assign(:job_posting, %JobPosting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Company Jobs")
    |> assign(:job_posting, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    SharedHelpers.process_job_filters(filter_params, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({event, job_posting}, socket)
      when event in [:job_posting_created, :job_posting_updated] do
    send_update(JobListComponent, id: "job-post-list", job_posting: job_posting)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:video_ready, %{asset_id: asset_id, playback_id: playback_id}}, socket) do
    IO.puts(IO.ANSI.format([:green, "Video ready: #{asset_id} with playback_id: #{playback_id}"]))

    send_update(BemedaPersonalWeb.CompanyJobLive.FormComponent,
      id: "company-job-form",
      mux_data: %{asset_id: asset_id, playback_id: playback_id}
    )

    {:noreply, socket}
  end
end
