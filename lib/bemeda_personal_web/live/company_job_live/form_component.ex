defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id="job-posting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <.input field={f[:title]} type="text" label="Job Title" required />

        <.input field={f[:description]} type="textarea" label="Job Description" rows={6} required />

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input field={f[:location]} type="text" label="Location" />

          <.input
            field={f[:employment_type]}
            type="select"
            label="Employment Type"
            options={[
              {"Full-time", "Full-time"},
              {"Part-time", "Part-time"},
              {"Contract", "Contract"},
              {"Temporary", "Temporary"},
              {"Internship", "Internship"}
            ]}
          />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.input
            field={f[:experience_level]}
            type="select"
            label="Experience Level"
            options={[
              {"Entry Level", "Entry Level"},
              {"Mid Level", "Mid Level"},
              {"Senior Level", "Senior Level"},
              {"Executive", "Executive"}
            ]}
          />

          <.input field={f[:remote_allowed]} type="checkbox" label="Remote Work Allowed" />
        </div>

        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-3">
          <.input field={f[:salary_min]} type="number" label="Minimum Salary" min="0" />

          <.input field={f[:salary_max]} type="number" label="Maximum Salary" min="0" />

          <.input
            field={f[:currency]}
            type="select"
            label="Currency"
            options={[
              {"USD", "USD"},
              {"EUR", "EUR"},
              {"GBP", "GBP"},
              {"CAD", "CAD"},
              {"AUD", "AUD"},
              {"JPY", "JPY"}
            ]}
          />
        </div>

        <div class="flex justify-end space-x-3">
          <.button :if={@action == :edit} type="submit" phx-disable-with="Saving...">
            Save Changes
          </.button>
          <.button :if={@action == :new} type="submit" phx-disable-with="Posting...">
            Post Job
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_posting: job_posting} = assigns, socket) do
    changeset = Jobs.change_job_posting(job_posting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_params}, socket) do
    changeset =
      socket.assigns.job_posting
      |> Jobs.change_job_posting(job_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"job_posting" => job_params}, socket) do
    save_job_posting(socket, socket.assigns.action, job_params)
  end

  defp save_job_posting(socket, :new, job_params) do
    case Jobs.create_job_posting(socket.assigns.company, job_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job posted successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_job_posting(socket, :edit, job_params) do
    case Jobs.update_job_posting(socket.assigns.job_posting, job_params) do
      {:ok, _job_posting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job updated successfully.")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
