defmodule BemedaPersonalWeb.Resume.WorkExperienceFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Resumes
  alias BemedaPersonal.Resumes.Resume
  alias BemedaPersonalWeb.Components.ResumeComponents

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="work-experience-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:company_name]}
          type="text"
          label="Company Name"
          placeholder="e.g., Google"
          required
        />
        <.input
          field={@form[:title]}
          type="text"
          label="Job Title"
          placeholder="e.g., Software Engineer"
          required
        />
        <.input
          field={@form[:location]}
          type="text"
          label="Location"
          placeholder="e.g., Mountain View, CA"
        />
        <ResumeComponents.date_input field={@form[:start_date]} label="Start Date" required={true} />
        <.input
          field={@form[:current]}
          type="checkbox"
          label="I currently work here"
          phx-hook="CurrentCheckbox"
          data-end-date-id={@form[:end_date].id}
        />
        <ResumeComponents.date_input
          field={@form[:end_date]}
          label="End Date"
          disabled={Phoenix.HTML.Form.input_value(@form, :current)}
          label_class={Phoenix.HTML.Form.input_value(@form, :current) && "opacity-50"}
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Describe your responsibilities, achievements, projects, etc."
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Work Experience</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{work_experience: work_experience, resume: %Resume{} = resume} = assigns, socket) do
    changeset =
      work_experience
      |> Resumes.change_work_experience()
      |> Ecto.Changeset.put_assoc(:resume, resume)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:work_experience, work_experience)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"work_experience" => work_experience_params}, socket) do
    changeset =
      socket.assigns.work_experience
      |> Resumes.change_work_experience(work_experience_params)
      |> Ecto.Changeset.put_assoc(:resume, socket.assigns.resume)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"work_experience" => work_experience_params}, socket) do
    save_work_experience(socket, work_experience_params)
  end

  defp save_work_experience(socket, work_experience_params) do
    case Resumes.create_or_update_work_experience(
           socket.assigns.work_experience,
           socket.assigns.resume,
           work_experience_params
         ) do
      {:ok, _work_experience} ->
        {:noreply,
         socket
         |> put_flash(:info, "Work experience saved successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
