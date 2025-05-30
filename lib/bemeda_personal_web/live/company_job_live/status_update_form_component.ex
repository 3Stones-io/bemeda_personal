defmodule BemedaPersonalWeb.CompanyJobLive.StatusUpdateFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobApplicationStateTransition

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
            label={dgettext("jobs", "Status")}
            type="select"
            prompt={dgettext("jobs", "Select a status")}
            options={status_options(@available_statuses)}
            required
          />
        </div>

        <div class="mb-4">
          <.input
            field={f[:notes]}
            type="textarea"
            rows="4"
            label={dgettext("jobs", "Notes")}
            placeholder={dgettext("jobs", "Add notes about this status change...")}
          />
        </div>

        <div class="flex justify-end space-x-2">
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 hover:bg-gray-300 rounded-md transition-colors duration-150 ease-in-out"
            id={"cancel-status-update-#{@applicant.id}"}
          >
            {dgettext("general", "Cancel")}
          </button>
          <button
            type="submit"
            class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md transition-colors duration-150 ease-in-out"
            id={"update-status-#{@applicant.id}"}
          >
            {dgettext("jobs", "Update Status")}
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
      {:ok, updated_job_application} ->
        SharedHelpers.enqueue_email_notification_job(%{
          job_application_id: updated_job_application.id,
          type: "job_application_status_update",
          url:
            url(
              ~p"/jobs/#{updated_job_application.job_posting_id}/job_applications/#{updated_job_application.id}"
            )
        })

        {:noreply, put_flash(socket, :info, dgettext("jobs", "Status updated successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("jobs", "Failed to update status"))
         |> assign(:update_job_application_status_form, changeset)}
    end
  end

  defp status_options(available_statuses) do
    Enum.map(available_statuses, fn key ->
      {I18n.translate_status_action(key), key}
    end)
  end
end
