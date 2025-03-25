defmodule BemedaPersonalWeb.JobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    job_posting = Jobs.get_job_posting!(id)

    {:noreply,
     socket
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, job_posting.title)}
  end
end
