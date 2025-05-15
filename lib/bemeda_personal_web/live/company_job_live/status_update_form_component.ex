defmodule BemedaPersonalWeb.CompanyJobLive.StatusUpdateFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobApplicationStateTransition
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@update_job_application_status_form}
        id={@id}
        phx-submit="update_job_application_status"
        phx-target={@myself}
        data-applicant-id={@applicant.id}
      >
        <div class="mb-4">
          <.input
            field={f[:to_state]}
            label="Status"
            type="select"
            prompt="Select a status"
            options={
              Enum.map(@available_statuses, fn key ->
                {SharedHelpers.translate_status(:action)[key], key}
              end)
            }
            required
          />
        </div>

        <div class="mb-4">
          <.input
            field={f[:notes]}
            type="textarea"
            rows="4"
            label="Notes"
            placeholder="Add notes about this status change..."
          />
        </div>

        <div class="flex justify-end space-x-2">
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 rounded-md transition-colors duration-150 ease-in-out"
            id={"cancel-status-update-#{@applicant.id}"}
          >
            Cancel
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors duration-150 ease-in-out"
            id={"update-status-#{@applicant.id}"}
          >
            Update Status
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    update_job_application_status_form =
      %JobApplicationStateTransition{}
      |> Jobs.change_job_application_status()
      |> Phoenix.Component.to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:update_job_application_status_form, update_job_application_status_form)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "update_job_application_status",
        %{
          "job_application_state_transition" => params
        },
        socket
      ) do
    job_application = socket.assigns.applicant
    user = socket.assigns.current_user

    params =
      Map.merge(params, %{
        "from_state" => job_application.state
      })

    case Jobs.update_job_application_status(job_application, user, params) do
      {:ok, _updated_job_application} ->
        {:noreply, put_flash(socket, :info, "Status updated successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update status")
         |> assign(:update_job_application_status_form, changeset)}
    end
  end
end
