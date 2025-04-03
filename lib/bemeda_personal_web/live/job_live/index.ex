defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.JobListComponent
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign(:filters, %{})
     |> assign(:page_title, "Job Listings")}
  end

  @impl Phoenix.LiveView
  def handle_event("filter_jobs", %{"filters" => filter_params}, socket) do
    SharedHelpers.process_job_filters(filter_params, socket)
  end
end
