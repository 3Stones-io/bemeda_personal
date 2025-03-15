defmodule BemedaPersonalWeb.JobPostingLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs

  @employment_types ["Full-time", "Part-time", "Contract", "Temporary", "Internship", "Volunteer"]
  @experience_levels ["Entry level", "Mid level", "Senior level", "Director", "Executive"]

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="job_posting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input
          field={@form[:employment_type]}
          type="select"
          label="Employment type"
          options={@employment_types}
        />
        <.input
          field={@form[:experience_level]}
          type="select"
          label="Experience level"
          options={@experience_levels}
        />
        <.input field={@form[:salary_min]} type="number" label="Salary min" />
        <.input field={@form[:salary_max]} type="number" label="Salary max" />
        <.input field={@form[:currency]} type="text" label="Currency" />
        <.input field={@form[:remote_allowed]} type="checkbox" label="Remote allowed" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Job posting</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = Jobs.change_job_posting(job_posting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:employment_types, @employment_types)
     |> assign(:experience_levels, @experience_levels)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_posting_params}, socket) do
    changeset =
      socket.assigns.job_posting
      |> Jobs.change_job_posting(job_posting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_posting" => job_posting_params}, socket) do
    save_job_posting(socket, socket.assigns.action, job_posting_params)
  end

  defp save_job_posting(socket, :edit, job_posting_params) do
    case Jobs.update_job_posting(
           socket.assigns.current_user,
           socket.assigns.job_posting,
           job_posting_params
         ) do
      {:ok, job_posting} ->
        notify_parent({:saved, job_posting})

        {:noreply,
         socket
         |> put_flash(:info, "Job posting updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to update this job posting")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :company_not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "You need to create a company first")
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp save_job_posting(socket, :new, job_posting_params) do
    case Jobs.create_job_posting(socket.assigns.current_user, job_posting_params) do
      {:ok, job_posting} ->
        notify_parent({:saved, job_posting})

        {:noreply,
         socket
         |> put_flash(:info, "Job posting created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to create job postings")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :company_not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "You need to create a company first")
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
