defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.JobListComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> assign(:page_title, "Job Listings")
     |> assign(:filters, %{})}
  end
end
