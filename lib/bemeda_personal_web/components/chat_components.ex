defmodule BemedaPersonalWeb.ChatComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Chat.MediaData
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.Jobs.JobApplication
  alias BemedaPersonal.S3Helper.Client

  @type assigns :: map()
  @type output :: Phoenix.LiveView.Rendered.t()

  attr :chat_form, :any, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  @spec chat_form(assigns()) :: output()
  def chat_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@chat_form}
      id="chat-form"
      phx-change="validate"
      phx-submit="send-message"
      class={[
        "bg-[#ebedee] overflow-hidden rounded-xl p-2",
        @class
      ]}
      phx-hook="ChatInput"
      {@rest}
    >
      <.input
        type="chat-input"
        id="message-input"
        placeholder="Type a message or drag and drop a file..."
        field={f[:content]}
        phx-debounce="1000"
      />

      <div class="flex items-center justify-between px-2">
        <label for="hidden-file-input" class="cursor-pointer">
          <.icon name="hero-paper-clip" class="text-bold text-[#667085] h-5 w-5" />

          <input id="hidden-file-input" type="file" class="hidden" accept="*" />
        </label>

        <button type="submit" class="bg-black text-white px-2 py-1 rounded-lg">
          <.icon name="hero-paper-airplane" class="h-5 w-5" />
        </button>
      </div>
    </.form>
    """
  end

  @spec chat_container(assigns()) :: output()
  def chat_container(%{message: %JobApplication{}} = assigns) do
    assigns =
      assign_new(assigns, :class, fn %{message: message, current_user: current_user} ->
        [
          "w-[85%] md:w-[60%] lg:w-[40%] mb-3",
          message.user_id == current_user.id && "ml-auto rounded-2xl rounded-br-none bg-blue-100",
          message.user_id != current_user.id && "mr-auto rounded-2xl rounded-bl-none bg-gray-100"
        ]
      end)

    ~H"""
    <div id={@id} class="grid">
      <div class={@class}>
        <div
          class={[
            "text-sm text-zinc-900 py-2 px-4"
          ]}
          id={"cover-letter-#{@message.id}"}
          data-truncate-length="250"
          phx-hook="TextTruncate"
        >
          {@message.cover_letter}
        </div>
      </div>

      <div :if={@message.mux_data && @message.mux_data.playback_id} class={@class}>
        <mux-player playback-id={@message.mux_data.playback_id}></mux-player>
      </div>

      <.link
        :if={@message.user_id == @current_user.id}
        navigate={~p"/jobs/#{@message.job_posting_id}/job_applications/#{@message.id}/edit"}
        class={[
          "py-3 bg-blue-500 text-white font-medium rounded-xl hover:bg-blue-600 transition-colors",
          "ml-auto mb-3 inline-blockw-[85%] md:w-[60%] lg:w-[40%] flex items-center justify-center"
        ]}
      >
        Edit Your Application
      </.link>
    </div>
    """
  end

  @spec chat_container(assigns()) :: output()
  def chat_container(%{message: %Message{}} = assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "w-[85%] md:w-[60%] lg:w-[40%] mb-3",
        @message.sender_id == @current_user.id && "ml-auto rounded-2xl rounded-br-none",
        @message.sender_id != @current_user.id && "mr-auto rounded-2xl rounded-bl-none",
        @message.content && @message.sender_id == @current_user.id && "bg-blue-100 ",
        @message.content && @message.sender_id != @current_user.id && "bg-gray-100 "
      ]}
    >
      <.chat_message message={@message} />
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :message, :any
  attr :job_application, :any, default: nil
  attr :index, :string, default: nil

  @spec chat_message(assigns()) :: output()
  def chat_message(
        %{message: %{media_data: %MediaData{type: "video" <> _rest, playback_id: nil}}} = assigns
      ) do
    ~H"""
    <div class="w-full h-[200px] bg-zinc-200 rounded-lg flex items-center justify-center">
      <.icon name="hero-arrow-up-on-square" class="h-12 w-12 text-[#075389] animate-pulse" />
    </div>
    """
  end

  def chat_message(%{message: %{media_data: %MediaData{type: "video" <> _rest}}} = assigns) do
    ~H"""
    <mux-player playback-id={@message.media_data.playback_id}></mux-player>
    """
  end

  def chat_message(
        %{message: %{media_data: %MediaData{type: "audio" <> _rest, playback_id: nil}}} = assigns
      ) do
    ~H"""
    <div class="w-full bg-[#e9eef2] rounded-lg p-3">
      <div class="flex items-center gap-3">
        <.icon name="hero-speaker-wave" class="h-5 w-5 text-[#075389]" />
        <div class="h-2 w-full bg-[#d6e6f1] rounded-full overflow-hidden">
          <div class={[
            "h-full w-full animate-pulse",
            "bg-gradient-to-r from-[#075389] from-0% via-[#d6e6f1] via-33% to-[#075389] to-67% bg-[length:400%_100%]"
          ]}>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def chat_message(%{message: %{media_data: %MediaData{type: "audio" <> _rest}}} = assigns) do
    ~H"""
    <mux-player
      playback-id={@message.media_data.playback_id}
      audio
      primary-color="#075389"
      secondary-color="#d6e6f1"
    >
    </mux-player>
    """
  end

  def chat_message(
        %{message: %{media_data: %MediaData{type: "image" <> _rest, status: :pending}}} = assigns
      ) do
    ~H"""
    <div class="w-full h-[200px] bg-zinc-200 rounded-lg flex items-center justify-center">
      <.icon name="hero-photo" class="h-12 w-12 text-[#075389] animate-pulse" />
    </div>
    """
  end

  def chat_message(%{message: %{media_data: %MediaData{type: "image" <> _rest}}} = assigns) do
    ~H"""
    <div class="w-full overflow-hidden rounded-lg">
      <img
        src={get_presigned_url(@message.id)}
        alt="@media_data.file_name"
        class="w-full h-auto object-contain max-h-[400px]"
      />
    </div>
    """
  end

  def chat_message(%{message: %{media_data: %MediaData{status: :pending}}} = assigns) do
    ~H"""
    <div class="w-full bg-[#e9eef2] rounded-lg p-3 flex items-center">
      <.icon name="hero-document" class="h-6 w-6 text-[#075389] mr-3" />
      <div class="flex flex-col">
        <span class="text-sm font-medium text-zinc-800">Uploading file...</span>
        <span class="text-xs text-zinc-500">Processing...</span>
      </div>
    </div>
    """
  end

  def chat_message(%{message: %{media_data: %MediaData{status: :uploaded}}} = assigns) do
    ~H"""
    <div class="w-full bg-[#e9eef2] rounded-lg p-3">
      <.link
        href={get_presigned_url(@message.id)}
        target="_blank"
        class="flex items-center hover:bg-[#d6e6f1] p-2 rounded-lg transition-colors"
      >
        <.icon name="hero-document" class="h-6 w-6 text-[#075389] mr-3" />
        <p class="text-sm font-medium text-zinc-800">
          <span>{@message.media_data.file_name}</span>
        </p>
      </.link>
    </div>
    """
  end

  def chat_message(assigns) do
    ~H"""
    <div class="p-3">
      <p class="text-sm">{@message.content}</p>
    </div>
    """
  end

  defp get_presigned_url(message_id) do
    {:ok, url} = Client.get_presigned_url(message_id, :get)
    url
  end
end
