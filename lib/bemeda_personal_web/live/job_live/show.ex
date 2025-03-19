defmodule BemedaPersonalWeb.JobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs
  alias BemedaPersonalWeb.JobsComponents

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    job_posting = Jobs.get_job_posting!(id)

    {:noreply,
     socket
     |> assign(:page_title, job_posting.title)
     |> assign(:job_posting, job_posting)}
  end
end
