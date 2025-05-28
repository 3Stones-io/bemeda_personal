defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobListComponent
  alias Phoenix.Socket.Broadcast

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("job_posting")
    end

    {:ok, assign(socket, :page_title, dgettext("jobs", "Job Listings"))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :filter_params, params)}
  end

  @impl Phoenix.LiveView
  def handle_info({:filters_updated, filters}, socket) do
    {:noreply, push_patch(socket, to: ~p"/jobs?#{filters}")}
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in ["job_posting_created", "job_posting_updated"] do
    send_update(JobListComponent,
      id: "job-post-list",
      job_postings: payload.job_posting
    )

    {:noreply, socket}
  end
end
