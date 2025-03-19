defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    job_postings = Jobs.list_job_postings()

    {:ok,
     socket
     |> assign(:page_title, "Job Listings")
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream(:job_postings, job_postings)}
  end
end
