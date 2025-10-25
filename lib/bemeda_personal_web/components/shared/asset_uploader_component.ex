defmodule BemedaPersonalWeb.Components.Shared.AssetUploaderComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonalWeb.Components.Shared.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

  attr :id, :string, required: true
  attr :type, :atom, required: true, values: [:image, :video]
  attr :accept, :string, default: nil
  attr :max_file_size, :integer, default: nil
  attr :media_asset, :any, default: nil
  attr :label, :string, default: nil
  attr :class, :string, default: ""
  attr :placeholder_image, :string, default: "/images/empty-states/avatar_empty.png"

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <div id={@id} class={["asset-uploader", @class]}>
      <%= if @type == :image do %>
        <div class="flex items-center gap-4">
          <div
            id={"#{@id}-container"}
            phx-hook="FileUpload"
            phx-target={@myself}
            phx-update="ignore"
            data-events-target={@id}
            class="avatar relative"
          >
            <svg
              id={"#{@id}-progress-circle"}
              class="absolute inset-0 w-full h-full hidden"
              style="transform: rotate(-90deg)"
            >
              <circle
                cx="50"
                cy="50"
                r="48"
                fill="none"
                stroke="#e5e7eb"
                stroke-width="4"
              />
              <circle
                id={"#{@id}-progress-indicator"}
                cx="50"
                cy="50"
                r="48"
                fill="none"
                stroke="#4f46e5"
                stroke-width="4"
                stroke-dasharray="0 302"
                stroke-linecap="round"
                class="transition-all duration-300"
              />
            </svg>

            <div class="border-[1px] border-[#e4e9ef] w-[fit-content] p-1 rounded-full bg-white overflow-hidden">
              <div class="w-24 h-24 rounded-full border-[1px] border-[#e4e9ef] overflow-hidden relative">
                <img
                  id={"#{@id}-preview-image"}
                  src={@asset_url || @placeholder_image}
                  alt={dgettext("assets", "Avatar")}
                  class="w-full h-full object-cover"
                />
              </div>
            </div>
            <input
              id={"#{@id}-hidden-file-input"}
              type="file"
              class="hidden file-input"
              accept={@accept}
              data-max-file-size={@max_file_size}
            />
          </div>

          <div class="flex items-center gap-2">
            <button
              type="button"
              class="cursor-pointer text-form-txt-primary text-sm border border-form-input-border hover:border-primary-400 rounded-full px-4 py-3 flex items-center justify-center gap-2"
              phx-click={JS.dispatch("click", to: "##{@id}-hidden-file-input")}
            >
              <.icon name="hero-arrow-up-tray" class="h-4 w-4" />
              <span>{if @has_asset?, do: @replace_text, else: @upload_label}</span>
            </button>

            <button
              :if={@has_asset?}
              type="button"
              class="cursor-pointer text-red-700 p-2 border border-red-300 hover:border-red-400 rounded-full flex items-center justify-center"
              phx-click="delete_asset"
              phx-target={@myself}
              title={@delete_text}
            >
              <.icon name="hero-trash" class="h-4 w-4" />
            </button>
          </div>
        </div>
      <% end %>

      <%= if @type == :video do %>
        <div :if={!@has_asset?}>
          <SharedComponents.file_input_component
            id={@id}
            type={@asset_type}
            accept={@accept}
            max_file_size={@max_file_size}
            target={@myself}
            events_target={@id}
          />

          <SharedComponents.file_upload_progress
            id={"#{@id}-progress"}
            phx-update="ignore"
          />
        </div>

        <div :if={@has_asset?}>
          <div class="video-preview border border-white rounded-md mb-4">
            <video controls class="w-full h-full">
              <source src={@asset_url} type="video/mp4" />
            </video>
          </div>

          <button
            type="button"
            class="cursor-pointer text-red-700 text-sm border border-red-300 hover:border-red-400 rounded-full px-4 py-2 flex items-center justify-center gap-2"
            phx-click="delete_asset"
            phx-target={@myself}
          >
            <.icon name="hero-trash" class="h-4 w-4" />
            <span>{@delete_text}</span>
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(:media_data, %{})
     |> assign(:uploading?, false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    has_asset? = has_media_asset?(assigns.media_asset)

    asset_url =
      if has_asset?, do: SharedHelpers.get_media_asset_url(assigns.media_asset), else: nil

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:has_asset?, has_asset?)
     |> assign(:asset_url, asset_url)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("upload_file", params, socket) do
    {:reply, response, updated_socket} = SharedHelpers.create_file_upload(socket, params)

    notify_parent({:upload_started, updated_socket.assigns.media_data}, socket)

    {:reply, response, assign(updated_socket, :uploading?, true)}
  end

  def handle_event("upload_completed", %{"upload_id" => upload_id}, socket) do
    file_name = Map.get(socket.assigns.media_data, "file_name", "uploaded_file")

    media_data = %{
      "upload_id" => upload_id,
      "file_name" => file_name
    }

    video_url =
      if socket.assigns.type == :video do
        SharedHelpers.get_presigned_url(upload_id)
      end

    response = if video_url, do: %{video_url: video_url}, else: %{}

    notify_parent({:upload_completed, media_data}, socket)

    {:reply, response,
     socket
     |> assign(:media_data, media_data)
     |> assign(:uploading?, false)
     |> assign(:has_asset?, true)
     |> assign(:asset_url, SharedHelpers.get_presigned_url(upload_id))}
  end

  def handle_event("replace_asset", _params, socket) do
    notify_parent({:replace_asset, socket.assigns.media_data}, socket)

    {:noreply,
     socket
     |> assign(:has_asset?, false)
     |> assign(:asset_url, nil)
     |> assign(:media_data, %{})}
  end

  def handle_event("delete_asset", _params, socket) do
    notify_parent({:delete_asset, socket.assigns.media_data}, socket)

    {:noreply,
     socket
     |> assign(:has_asset?, false)
     |> assign(:asset_url, nil)
     |> assign(:media_data, %{})}
  end

  def handle_event("upload_cancelled", _params, socket) do
    notify_parent({:upload_cancelled, socket.assigns.media_data}, socket)

    {:noreply,
     socket
     |> assign(:uploading?, false)
     |> assign(:media_data, %{})}
  end

  defp notify_parent(msg, _socket) do
    send(self(), {__MODULE__, msg})
  end

  defp assign_defaults(assigns) do
    type = assigns.type

    assigns
    |> Map.put(:accept, get_accept(assigns, type))
    |> Map.put(:max_file_size, get_max_file_size(assigns, type))
    |> Map.put(:asset_type, get_asset_type(type))
    |> Map.put(:upload_label, get_upload_label(assigns, type))
    |> Map.put(:replace_text, get_replace_text(type))
    |> Map.put(:delete_text, get_delete_text(type))
  end

  defp get_accept(assigns, type) do
    assigns[:accept] || default_accept(type)
  end

  defp default_accept(:video), do: "video/*"
  defp default_accept(:image), do: "image/*"

  defp get_max_file_size(assigns, type) do
    assigns[:max_file_size] || default_max_file_size(type)
  end

  defp default_max_file_size(:video), do: 52_000_000
  defp default_max_file_size(:image), do: 10_000_000

  defp get_asset_type(:video), do: "video"
  defp get_asset_type(:image), do: "image"

  defp get_upload_label(assigns, type) do
    assigns[:label] || default_upload_label(type)
  end

  defp default_upload_label(:video), do: dgettext("assets", "Upload video")
  defp default_upload_label(:image), do: dgettext("assets", "Upload photo")

  defp get_replace_text(:video), do: dgettext("assets", "Change video")
  defp get_replace_text(:image), do: dgettext("assets", "Replace photo")

  defp get_delete_text(:video), do: dgettext("assets", "Delete video")
  defp get_delete_text(:image), do: dgettext("assets", "Delete photo")

  defp has_media_asset?(nil), do: false
  defp has_media_asset?(%{upload_id: nil}), do: false
  defp has_media_asset?(%{upload_id: _others}), do: true
  defp has_media_asset?(_other), do: false
end
