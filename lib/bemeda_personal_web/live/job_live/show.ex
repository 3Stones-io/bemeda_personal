defmodule BemedaPersonalWeb.JobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    job_posting = Jobs.get_job_posting!(id)

    {:ok,
     socket
     |> assign(:page_title, job_posting.title)
     |> assign(:job_posting, job_posting)}
  end
end
