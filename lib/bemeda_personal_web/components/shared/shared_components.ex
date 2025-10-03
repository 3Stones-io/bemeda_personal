defmodule BemedaPersonalWeb.Components.Shared.SharedComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.FileSizeUtils
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: Phoenix.LiveView.Socket.assigns()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :class, :string, default: "w-full h-full"
  attr :media_asset, MediaAsset

  @spec video_player(assigns()) :: output()
  def video_player(assigns) do
    ~H"""
    <div :if={@media_asset} class={@class}>
      <video controls class="w-full h-full">
        <source src={SharedHelpers.get_presigned_url(@media_asset.upload_id)} type="video/mp4" />
      </video>
    </div>
    """
  end

  attr :accept, :string, required: true
  attr :class, :string, default: nil
  attr :events_target, :string
  attr :id, :string, required: true
  attr :max_file_size, :integer, required: true
  attr :target, :any, default: nil
  attr :type, :string, required: true

  @spec file_input_component(assigns()) :: output()
  def file_input_component(assigns) do
    ~H"""
    <label
      id={"#{@id}-file-upload"}
      class={[
        "relative w-full",
        @class
      ]}
      phx-hook="FileUpload"
      phx-target={@target}
      phx-update="ignore"
      data-events-target={@events_target}
    >
      <div
        id={"#{@id}-file-upload-inputs-container"}
        class="text-center flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-8 cursor-pointer hover:border-gray-400 transition-colors"
      >
        <div class="mb-4">
          <.icon name="hero-photo" class="h-12 w-12 text-gray-400" />
        </div>
        <p class="mb-2 text-base text-gray-700">
          Drag and drop {@type} or <span class="text-blue-600 underline">browse</span>
        </p>
        <p class="text-sm text-gray-500">
          Upload a {@type} not more than {FileSizeUtils.pretty(@max_file_size)}, in mp4 format.
        </p>
        <input
          id={"#{@id}-hidden-file-input"}
          type="file"
          class="hidden file-input"
          accept={@accept}
          data-max-file-size={@max_file_size}
        />
      </div>
      <p id={"#{@id}-file-upload-error"} class="mt-2 text-sm text-danger-600 text-center mt-4 hidden">
        <.icon name="hero-exclamation-circle" class="h-4 w-4" /> {dgettext(
          "errors",
          "Unsupported file type."
        )}
      </p>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  @spec file_upload_progress(assigns()) :: output()
  def file_upload_progress(assigns) do
    ~H"""
    <div
      id={"#{@id}"}
      class={[
        @class
      ]}
      {@rest}
    >
      <div class="mt-4 bg-white rounded-md border border-secondary-200 file-upload-progress hidden grid">
        <div class="h-48 w-full bg-white blur-[2px] image-container rounded-sm col-start-1 row-start-1">
          <img src="" alt="" />
        </div>
        <div class="overlay-container col-start-1 row-start-1 flex flex-col items-center justify-center relative">
          <div class="relative">
            <svg class="w-20 h-20 transform -rotate-90" viewBox="0 0 36 36">
              <path
                class="text-gray-300"
                stroke="currentColor"
                stroke-width="2"
                fill="none"
                d="M18 2.0845
            a 15.9155 15.9155 0 0 1 0 31.831
            a 15.9155 15.9155 0 0 1 0 -31.831"
              />
              <path
                class="text-blue-600 progress-circle"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                fill="none"
                stroke-dasharray="0, 100"
                d="M18 2.0845
            a 15.9155 15.9155 0 0 1 0 31.831
            a 15.9155 15.9155 0 0 1 0 -31.831"
              />
            </svg>

            <button
              type="button"
              class="upload-cancel-btn absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-8 h-8 bg-opacity-50 rounded-full flex items-center justify-center text-white hover:bg-opacity-70 transition-all duration-200 z-20"
              title="Cancel upload"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <div class="mt-4 text-center">
            <p class="text-white text-sm font-medium">Uploading Video...</p>
          </div>
        </div>
      </div>

      <div class="video-preview hidden">
        <video controls class="w-full h-full">
          <source src="" type="video/mp4" />
        </video>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :url, :string, required: true

  @spec video_preview(assigns()) :: output()
  def video_preview(assigns) do
    ~H"""
    <div class={"uploaded-video-placeholder" <> @class}>
      <video controls class="w-full h-full">
        <source src={@url} type="video/mp4" />
      </video>
    </div>
    """
  end

  attr :asset_preview_id, :string, required: true
  attr :media_asset, :any, required: true
  attr :show_asset_description, :boolean, default: false
  attr :type, :string, required: true

  @spec asset_preview(assigns()) :: output()
  def asset_preview(assigns) do
    ~H"""
    <div
      :if={@show_asset_description}
      id="asset-description"
      phx-click={
        JS.toggle(
          to: "##{@asset_preview_id}",
          in: "transition-all duration-200 ease-in-out",
          out: "transition-all duration-200 ease-in-out"
        )
      }
      title={dgettext("general", "Show %{type}", type: @type)}
    >
      <div
        class="relative w-full bg-white rounded-lg border border-secondary-200 p-sm cursor-pointer hover:bg-surface-secondary"
        role="button"
        phx-click={
          JS.toggle(
            to: "##{@asset_preview_id}",
            in: "transition-all duration-500 ease-in-out",
            out: "transition-all duration-500 ease-in-out"
          )
        }
      >
        <div class="flex items-center space-x-4">
          <div class="flex-shrink-0">
            <.icon name="hero-paper-clip" class="h-8 w-8 text-primary-600" />
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-secondary-900 truncate">
              {@media_asset.file_name}
            </p>
          </div>
          <div class="flex-shrink-0">
            <button type="button" class="text-danger-600 hover:text-danger-800">
              <.icon name="hero-trash" class="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a download button/link for files stored in object storage.

  ## Examples

      <.download_button upload_id="abc123" filename="document.pdf" />
      <.download_button upload_id="abc123" filename="template.docx" class="custom-class" />

  """
  attr :upload_id, :string, required: true
  attr :filename, :string, required: true

  attr :class, :string,
    default:
      "inline-flex items-center px-xs py-2 border border-secondary-300 shadow-sm text-sm leading-4 font-medium rounded-md text-secondary-700 bg-white hover:bg-surface-secondary focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"

  attr :icon_class, :string, default: "h-4 w-4 mr-2"
  attr :rest, :global

  @spec download_button(assigns()) :: output()
  def download_button(assigns) do
    ~H"""
    <a href={SharedHelpers.get_presigned_url(@upload_id)} download={@filename} class={@class} {@rest}>
      <.icon name="hero-arrow-down-tray" class={@icon_class} />
      {dgettext("general", "Download")}
    </a>
    """
  end
end
