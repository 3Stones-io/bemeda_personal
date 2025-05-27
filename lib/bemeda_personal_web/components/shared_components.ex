defmodule BemedaPersonalWeb.SharedComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.FileSizeUtils
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.SharedHelpers

  @type assigns :: map()
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
    <div
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
        id="file-upload-inputs-container"
        class="text-center flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 p-8 bg-gray-50 cursor-pointer"
      >
        <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-indigo-100">
          <.icon name="hero-cloud-arrow-up" class="h-6 w-6 text-indigo-600" />
        </div>
        <h3 class="mb-2 text-lg font-medium text-gray-900">
          {dgettext("forms", "Drag and drop to upload your %{type}", type: @type)}
        </h3>
        <p class="mb-4 text-sm text-gray-500">{dgettext("forms", "or")}</p>
        <div>
          <label
            for="hidden-file-input"
            class="cursor-pointer rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            {dgettext("actions", "Browse Files")}
            <input
              id="hidden-file-input"
              type="file"
              class="hidden"
              accept={@accept}
              data-max-file-size={@max_file_size}
            />
          </label>
        </div>
        <p class="mt-2 text-xs text-gray-500">
          {dgettext("forms", "Max file size: %{size}", size: FileSizeUtils.pretty(@max_file_size))}
        </p>
      </div>
      <p id="file-upload-error" class="mt-2 text-sm text-red-600 text-center mt-4 hidden">
        <.icon name="hero-exclamation-circle" class="h-4 w-4" /> {dgettext(
          "errors",
          "Unsupported file type."
        )}
      </p>
    </div>
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
        "mt-4 bg-white rounded-lg border border-gray-200 p-4 file-upload-progress",
        @class
      ]}
      {@rest}
    >
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center space-x-2">
          <.icon name="hero-paper-clip" class="h-5 w-5 text-gray-400" />
          <span class="text-sm font-medium text-gray-700" id="upload-filename"></span>
        </div>
      </div>
      <div class="relative w-full">
        <div
          id="upload-progress"
          role="progressbar"
          aria-label={dgettext("general", "Upload progress")}
          aria-valuemin="0"
          aria-valuemax="100"
          class="w-full bg-gray-200 rounded-full h-2.5"
        >
          <div
            class="bg-indigo-600 h-2.5 rounded-full transition-all duration-300"
            style="width: 0%"
            id="upload-progress-bar"
          >
          </div>
        </div>
      </div>
      <div class="flex justify-between mt-2">
        <span id="upload-size" class="text-xs text-gray-500"></span>
        <span id="upload-percentage" class="text-xs text-gray-500"></span>
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
      title={dgettext("actions", "Show %{type}", type: @type)}
    >
      <div
        class="relative w-full bg-white rounded-lg border border-gray-200 p-4 cursor-pointer hover:bg-gray-50"
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
            <.icon name="hero-paper-clip" class="h-8 w-8 text-indigo-600" />
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">
              {@media_asset.file_name}
            </p>
          </div>
          <div class="flex-shrink-0">
            <button type="button" class="text-red-600 hover:text-red-800">
              <.icon name="hero-trash" class="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
