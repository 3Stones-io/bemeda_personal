defmodule BemedaPersonalWeb.ChatComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Jobs.MuxData

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

          <input id="hidden-file-input" type="file" class="hidden" accept="image/*,video/*,audio/*" />
        </label>

        <button type="submit" class="bg-black text-white px-2 py-1 rounded-lg">
          <.icon name="hero-paper-airplane" class="h-5 w-5" />
        </button>
      </div>
    </.form>
    """
  end

  attr :class, :string, default: nil
  attr :message, :any, required: true

  @spec chat_message(assigns()) :: output()
  def chat_message(
        %{message: %{mux_data: %MuxData{type: "video" <> _rest, playback_id: nil}}} = assigns
      ) do
    ~H"""
    <div class="w-full h-[200px] bg-zinc-200 rounded-lg flex items-center justify-center">
      <.icon name="hero-arrow-up-on-square" class="h-12 w-12 text-[#075389] animate-pulse" />
    </div>
    """
  end

  def chat_message(%{message: %{mux_data: %MuxData{type: "video" <> _rest}}} = assigns) do
    ~H"""
    <mux-player playback-id={@message.mux_data.playback_id}></mux-player>
    """
  end

  def chat_message(
        %{message: %{mux_data: %MuxData{type: "audio" <> _rest, playback_id: nil}}} = assigns
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

  def chat_message(%{message: %{mux_data: %MuxData{type: "audio" <> _rest}}} = assigns) do
    ~H"""
    <mux-player
      playback-id={@message.mux_data.playback_id}
      audio
      primary-color="#075389"
      secondary-color="#d6e6f1"
    >
    </mux-player>
    """
  end

  def chat_message(assigns) do
    ~H"""
    <div
      class={[
        "text-sm text-zinc-900 py-2 px-4",
        @class
      ]}
      id={"message-content-#{@message.id}"}
      data-truncate-length="250"
      phx-hook="TextTruncate"
    >
      {@message.content}
    </div>
    """
  end
end
