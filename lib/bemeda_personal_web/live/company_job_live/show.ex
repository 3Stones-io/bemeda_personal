defmodule BemedaPersonalWeb.CompanyJobLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonalWeb.Components.Job.JobsComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Use the scope already set by the mount hook which includes company for employers
    current_scope = socket.assigns[:current_scope]
    current_user = socket.assigns[:current_user]

    # Fall back to building scope if mount hook didn't set it
    scope = current_scope || Scope.for_user(current_user)

    {:ok, assign(socket, :scope, scope)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    SharedHelpers.assign_job_posting(socket, id)
  end

  @impl Phoenix.LiveView
  def handle_info(payload, socket) do
    SharedHelpers.reassign_job_posting(socket, payload)
  end
end
