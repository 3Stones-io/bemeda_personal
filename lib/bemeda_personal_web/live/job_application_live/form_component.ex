defmodule BemedaPersonalWeb.JobApplicationLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="job_application-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:cover_letter]}
          type="textarea"
          label="Cover Letter"
          rows={8}
          phx-debounce="blur"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Submit Application</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application} = assigns, socket) do
    changeset = Jobs.change_job_application(job_application)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_application" => job_application_params}, socket) do
    changeset =
      socket.assigns.job_application
      |> Jobs.change_job_application(job_application_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_application" => job_application_params}, socket) do
    save_job_application(socket, socket.assigns.action, job_application_params)
  end

  defp save_job_application(socket, :edit, job_application_params) do
    case Jobs.update_job_application(socket.assigns.job_application, job_application_params) do
      {:ok, job_application} ->
        notify_parent({:saved, job_application})

        {:noreply,
         socket
         |> put_flash(:info, "Application updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_job_application(socket, :new, job_application_params) do
    case Jobs.create_job_application(
           socket.assigns.current_user,
           socket.assigns.job_posting,
           job_application_params
         ) do
      {:ok, job_application} ->
        notify_parent({:saved, job_application})

        {:noreply,
         socket
         |> put_flash(:info, "Application submitted successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

# Show the application preview instead -> Here show / remind the user about the resume
