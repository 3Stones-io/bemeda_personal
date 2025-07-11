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
      <video controls>
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
        class="text-center flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-secondary-300 p-lg bg-surface-secondary cursor-pointer"
      >
        <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary-100">
          <.icon name="hero-cloud-arrow-up" class="h-6 w-6 text-primary-600" />
        </div>
        <h3 class="mb-2 text-lg font-medium text-secondary-900">
          {dgettext("general", "Drag and drop to upload your %{type}", type: @type)}
        </h3>
        <p class="mb-4 text-sm text-secondary-500">{dgettext("general", "or")}</p>
        <div>
          <div class="cursor-pointer rounded-md bg-primary-600 px-sm py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600">
            {dgettext("general", "Browse Files")}
            <input
              id={"#{@id}-hidden-file-input"}
              type="file"
              class="hidden"
              accept={@accept}
              data-max-file-size={@max_file_size}
            />
          </div>
        </div>
        <p class="mt-2 text-xs text-secondary-500">
          {dgettext("general", "Max file size: %{size}", size: FileSizeUtils.pretty(@max_file_size))}
        </p>
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
        "mt-4 bg-white rounded-lg border border-secondary-200 p-sm file-upload-progress",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center space-x-2">
          <.icon name="hero-paper-clip" class="h-5 w-5 text-secondary-400" />
          <span class="text-sm font-medium text-secondary-700" id={"#{@id}-upload-filename"}></span>
        </div>
      </div>
      <div class="relative w-full">
        <div
          id={"#{@id}-upload-progress"}
          role="progressbar"
          aria-label={dgettext("general", "Upload progress")}
          aria-valuemin="0"
          aria-valuemax="100"
          class="w-full bg-secondary-200 rounded-full h-2.5"
        >
          <div
            class="bg-primary-600 h-2.5 rounded-full transition-all duration-300"
            style="width: 0%"
            id={"#{@id}-upload-progress-bar"}
          >
          </div>
        </div>
      </div>
      <div class="flex justify-between mt-2">
        <span id={"#{@id}-upload-size"} class="text-xs text-secondary-500"></span>
        <span id={"#{@id}-upload-percentage"} class="text-xs text-secondary-500"></span>
      </div>
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
