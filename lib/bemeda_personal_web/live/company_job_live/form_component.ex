defmodule BemedaPersonalWeb.CompanyJobLive.FormComponent do
  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.MuxHelper

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

        <div
          id={"#{@id}-video-upload"}
          class={[
            "relative w-full rounded-lg border-2 border-dashed border-gray-300 p-8 bg-gray-50 cursor-pointer"
          ]}
          phx-hook="VideoUpload"
          data-company-id={@company.id}
        >
          <div class="text-center flex flex-col items-center justify-center">
            <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-indigo-100">
              <.icon name="hero-cloud-arrow-up" class="h-6 w-6 text-indigo-600" />
            </div>
            <h3 class="mb-2 text-lg font-medium text-gray-900">Drag and drop to upload your video</h3>
            <p class="mb-4 text-sm text-gray-500">or</p>
            <div>
              <label
                for="hidden-file-input"
                class="cursor-pointer rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                Browse Files
                <input
                  id="hidden-file-input"
                  type="file"
                  class="hidden"
                  accept="video/*"
                  data-max-file-size="50000000"
                />
              </label>
            </div>
            <p class="mt-2 text-xs text-gray-500">
              Max file size: 50MB
            </p>
          </div>
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
  def update(%{mux_data: mux_data}, socket) do
    IO.puts(IO.ANSI.format([:yellow, "#{inspect(mux_data)}"]))
    {:ok, assign(socket, :mux_data, mux_data)}
  end

  def update(%{job_posting: job_posting} = assigns, socket) do
    IO.puts(IO.ANSI.format([:yellow, "OTHER UPDATE:: #{inspect(assigns)}"]))
    changeset = Jobs.change_job_posting(job_posting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:mux_data, %{})
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"job_posting" => job_params}, socket) do
    job_params = Map.put(job_params, "mux_data", socket.assigns.mux_data)

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

  def handle_event("upload-video", _params, socket) do
    case MuxHelper.create_direct_upload() do
      %{url: upload_url} ->
        {:reply, %{upload_url: upload_url}, socket}

      {:error, reason} ->
        {:reply, %{error: "Failed to create upload URL: #{inspect(reason)}"}, socket}
    end
  end

  defp save_job_posting(socket, :new, job_params) do
    job_params = Map.put(job_params, "mux_data", socket.assigns.mux_data)

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
    job_params = Map.put(job_params, "mux_data", socket.assigns.mux_data)

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
