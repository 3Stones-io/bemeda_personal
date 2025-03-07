defmodule BemedaPersonalWeb.Resume.EducationFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Resume

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="education-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:institution]}
          type="text"
          label="Institution"
          placeholder="e.g., Stanford University"
          required
        />
        <.input
          field={@form[:degree]}
          type="text"
          label="Degree"
          placeholder="e.g., Bachelor of Science"
        />
        <.input
          field={@form[:field_of_study]}
          type="text"
          label="Field of Study"
          placeholder="e.g., Computer Science"
        />
        <.input field={@form[:start_date]} type="date" label="Start Date" required />
        <.input field={@form[:current]} type="checkbox" label="I am currently studying here" />
        <.input field={@form[:end_date]} type="date" label="End Date" />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Describe your studies, achievements, activities, etc."
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Education</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{education: education, resume: %Resume{} = resume} = assigns, socket) do
    changeset =
      education
      |> Resumes.change_education()
      |> Ecto.Changeset.put_assoc(:resume, resume)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:education, education)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"education" => education_params}, socket) do
    changeset =
      socket.assigns.education
      |> Resumes.change_education(education_params)
      |> Ecto.Changeset.put_assoc(:resume, socket.assigns.resume)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"education" => education_params}, socket) do
    save_education(socket, education_params)
  end

  defp save_education(socket, education_params) do
    case Resumes.create_or_update_education(
           socket.assigns.education,
           socket.assigns.resume,
           education_params
         ) do
      {:ok, education} ->
        notify_parent({:saved, education})

        {:noreply,
         socket
         |> put_flash(:info, "Education saved successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
