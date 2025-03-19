defmodule BemedaPersonalWeb.JobLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    job_postings = Jobs.list_job_postings()

    {:ok,
     socket
     |> assign(:page_title, "Job Listings")
     |> assign(:job_postings, job_postings)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Job Listings")
  end
end
# Start here -> Streams, UI fix (esp for show)
