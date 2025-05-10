defmodule BemedaPersonalWeb.DocumentTemplateComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Documents
  alias BemedaPersonal.TigrisHelper
  alias Phoenix.LiveView.AsyncResult

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:error, nil)
     |> assign(:form, to_form(%{}))
     |> assign(:variables, [])
     |> assign(:variables_status, nil)
     |> assign(:step, nil)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="p-2 mt-2 border-t border-gray-200" id={@id} phx-hook="DocumentTemplate">
      <div class="space-y-2 mt-3">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <button
              type="button"
              phx-click="toggle_form"
              phx-target={@myself}
              class="px-2 py-1 text-xs font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Fill Template
            </button>
          </div>
        </div>

        <div :if={@step} class="bg-white rounded-md p-4 border border-gray-300 shadow-sm">
          <.extract_variables_form
            :if={@step == :extract_variables}
            myself={@myself}
            variables_status={@variables_status}
          />
          <.generate_pdf_form
            :if={@step == :generate_pdf}
            error={@error}
            form={@form}
            myself={@myself}
            variables={@variables}
          />
        </div>
      </div>
    </div>
    """
  end

  defp extract_variables_form(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <p class="text-sm text-gray-700 mb-6">
        First, scan the document to extract variables that can be filled.
      </p>

      <p :if={@variables_status && @variables_status.loading} class="text-sm text-gray-600">
        Extracting variables from document...
      </p>

      <p :if={@variables_status && @variables_status.failed} class="text-sm text-red-600">
        Failed to extract variables: {inspect(@variables_status.failed)}
      </p>

      <div
        :if={!@variables_status || (@variables_status && !@variables_status.loading)}
        class="flex items-center gap-2"
      >
        <button
          type="button"
          phx-click="toggle_form"
          phx-target={@myself}
          class="flex-1 px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400"
        >
          Cancel
        </button>
        <button
          type="button"
          phx-click="extract_variables"
          phx-target={@myself}
          class="flex-1 px-3 py-1.5 text-xs font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-indigo-400"
        >
          Extract Variables
        </button>
      </div>
    </div>
    """
  end

  defp generate_pdf_form(assigns) do
    ~H"""
    <p :if={@error} class="mb-3 text-sm text-red-600 font-medium">{@error}</p>

    <.form for={@form} phx-submit="process_template" phx-target={@myself}>
      <h3 class="text-sm font-semibold text-gray-700 mb-6">Fill in template variables:</h3>

      <div :for={variable <- @variables} class="form-group mb-3">
        <.input
          field={@form[variable]}
          class="form-control w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500"
          label={variable}
          label_class="form-label text-xs font-medium text-gray-700 mb-1 block"
          type="text"
        />
      </div>

      <div class="mt-6">
        <div class="flex items-center gap-2">
          <button
            type="button"
            phx-click="toggle_form"
            phx-target={@myself}
            class="flex-1 px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400"
          >
            Cancel
          </button>
          <button
            class="flex-1 px-3 py-1.5 text-xs font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-indigo-400"
            phx-disable-with="Generating..."
            type="submit"
          >
            Generate PDF
          </button>
        </div>
      </div>
    </.form>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("extract_variables", _params, socket) do
    message_id = socket.assigns.message.id

    {:noreply,
     socket
     |> assign(:variables_status, AsyncResult.loading())
     |> start_async(:extract_variables, fn ->
       Documents.extract_template_variables(message_id)
     end)}
  end

  def handle_event("process_template", %{} = variables, socket) do
    case Documents.generate_pdf(
           socket.assigns.message.id,
           variables,
           socket.assigns.current_user,
           socket.assigns.job_application
         ) do
      {:ok, %Chat.Message{media_asset: %{upload_id: upload_id}}} ->
        pdf_url = TigrisHelper.get_presigned_download_url(upload_id)

        send(self(), {:flash, :info, "Document generated successfully!"})

        socket =
          socket
          |> assign(:error, nil)
          |> assign(:step, nil)
          |> assign(:variables_status, nil)
          |> push_event("open-pdf-#{socket.assigns.id}", %{url: pdf_url})

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, assign(socket, :error, "Failed to process document: #{inspect(reason)}")}
    end
  end

  def handle_event("toggle_form", _params, %{assigns: %{step: nil}} = socket) do
    {:noreply, assign(socket, :step, :extract_variables)}
  end

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :step, nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_async(:extract_variables, {:ok, {:ok, variables}}, socket) do
    form =
      variables
      |> Enum.reduce(%{}, fn variable, acc ->
        Map.put(acc, variable, "")
      end)
      |> to_form()

    send(self(), {:flash, :info, "Found #{map_size(form.source)} variables"})

    {:noreply,
     socket
     |> assign(:error, nil)
     |> assign(:form, form)
     |> assign(:variables, variables)
     |> assign(:variables_status, AsyncResult.ok(socket.assigns.variables_status, variables))
     |> assign(:step, :generate_pdf)}
  end

  def handle_async(:extract_variables, result, socket) do
    reason =
      case result do
        {:ok, {:error, reason}} -> reason
        {:exit, reason} -> reason
      end

    {:noreply,
     socket
     |> assign(:error, "Failed to extract variables: #{inspect(reason)}")
     |> assign(:variables_status, AsyncResult.failed(socket.assigns.variables_status, reason))}
  end
end
