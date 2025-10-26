defmodule BemedaPersonalWeb.Components.Shared.AssetUploaderComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Components.Shared.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
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
                  data-placeholder-src={@placeholder_image}
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
              <span>{if @media_asset, do: @replace_text, else: @upload_label}</span>
            </button>

            <button
              :if={@media_asset}
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
        <div class="flex items-center justify-between mb-3">
          <h3 class="capitalize text-sm font-semibold text-gray-900">
            {@title}
          </h3>
          <.custom_button
            :if={@media_asset}
            type="edit"
            class=""
            phx-click="delete_asset"
            phx-target={@myself}
          />
        </div>

        <div :if={!@media_asset}>
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

        <div :if={@media_asset} class="video-preview border border-white rounded-md">
          <video controls class="w-full h-full">
            <source src={@asset_url} type="video/mp4" />
          </video>
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
    socket = assign(socket, assigns)

    media_asset = load_media_asset(socket.assigns.parent_record)
    type = socket.assigns.type
    asset_url = get_asset_url(media_asset)

    {:ok,
     socket
     |> assign_defaults()
     |> assign_media_data(media_asset, asset_url, type)
     |> assign_labels(type, socket.assigns[:label])}
  end

  defp load_media_asset(parent_record) do
    parent_record
    |> Repo.preload(:media_asset)
    |> Map.get(:media_asset)
  end

  defp get_asset_url(nil), do: nil
  defp get_asset_url(media_asset), do: SharedHelpers.get_media_asset_url(media_asset)

  defp assign_defaults(socket) do
    socket
    |> assign_new(:class, fn -> "" end)
    |> assign_new(:placeholder_image, fn -> "/images/empty-states/avatar_empty.png" end)
    |> assign_new(:title, fn -> "" end)
  end

  defp assign_media_data(socket, media_asset, asset_url, type) do
    socket
    |> assign(:media_asset, media_asset)
    |> assign(:asset_url, asset_url)
    |> assign(:asset_type, if(type == :video, do: "video", else: "image"))
    |> assign_new(:accept, fn -> if type == :video, do: "video/*", else: "image/*" end)
    |> assign_new(:max_file_size, fn -> if type == :video, do: 52_000_000, else: 10_000_000 end)
  end

  defp assign_labels(socket, type, custom_label) do
    socket
    |> assign(:upload_label, custom_label || get_upload_label(type))
    |> assign(:replace_text, get_replace_text(type))
    |> assign(:delete_text, get_delete_text(type))
  end

  defp get_upload_label(:video), do: dgettext("assets", "Upload video")
  defp get_upload_label(_other), do: dgettext("assets", "Upload photo")

  defp get_replace_text(:video), do: dgettext("assets", "Change video")
  defp get_replace_text(_other), do: dgettext("assets", "Replace photo")

  defp get_delete_text(:video), do: dgettext("assets", "Delete video")
  defp get_delete_text(_other), do: dgettext("assets", "Delete photo")

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
     |> assign(:media_asset, true)
     |> assign(:asset_url, SharedHelpers.get_presigned_url(upload_id))}
  end

  def handle_event("replace_asset", _params, socket) do
    notify_parent({:replace_asset, socket.assigns.media_data}, socket)

    {:noreply,
     socket
     |> assign(:media_asset, false)
     |> assign(:asset_url, nil)
     |> assign(:media_data, %{})}
  end

  def handle_event("delete_asset", _params, socket) do
    if socket.assigns.media_asset do
      Media.delete_media_asset(
        socket.assigns.current_scope,
        socket.assigns.media_asset
      )
    end

    notify_parent({:delete_asset, socket.assigns.media_data}, socket)

    {:noreply,
     socket
     |> assign(:media_asset, nil)
     |> assign(:asset_url, nil)
     |> assign(:media_data, %{})
     |> push_event("delete-asset-success", %{})}
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
end
