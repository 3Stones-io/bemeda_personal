defmodule BemedaPersonalWeb.CompanyJobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonalWeb.Components.Company.CompanyComponents
  alias BemedaPersonalWeb.Components.Job.JobComponents
  alias BemedaPersonalWeb.Components.Media.MediaComponents

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    SharedHelpers.assign_job_posting(socket, id)
  end

  @impl Phoenix.LiveView
  def handle_info(payload, socket) do
    SharedHelpers.reassign_job_posting(socket, payload)
  end
end
