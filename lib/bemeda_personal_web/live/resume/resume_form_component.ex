defmodule BemedaPersonalWeb.Resume.ResumeFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Resumes

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="resume-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:headline]}
          type="text"
          label="Professional Headline"
          placeholder="e.g., Senior Software Engineer"
        />
        <.input
          field={@form[:summary]}
          type="textarea"
          label="Professional Summary"
          placeholder="Briefly describe your professional background, skills, and career goals"
        />
        <.input
          field={@form[:location]}
          type="text"
          label="Location"
          placeholder="e.g., San Francisco, CA"
        />
        <.input
          field={@form[:contact_email]}
          type="email"
          label="Contact Email"
          placeholder="Your preferred contact email"
        />
        <.input
          field={@form[:phone_number]}
          type="text"
          label="Phone Number"
          placeholder="Your phone number"
        />
        <.input
          field={@form[:website_url]}
          type="url"
          label="Website URL"
          placeholder="Your personal website or portfolio"
        />
        <.input field={@form[:is_public]} type="checkbox" label="Make resume public" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Resume</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{resume: resume} = assigns, socket) do
    changeset = Resumes.change_resume(resume)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"resume" => resume_params}, socket) do
    changeset =
      socket.assigns.resume
      |> Resumes.change_resume(resume_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"resume" => resume_params}, socket) do
    save_resume(socket, socket.assigns.action, resume_params)
  end

  defp save_resume(socket, :edit_resume, resume_params) do
    case Resumes.update_resume(socket.assigns.resume, resume_params) do
      {:ok, _resume} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resume updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
