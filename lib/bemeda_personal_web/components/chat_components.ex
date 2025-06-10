defmodule BemedaPersonalWeb.ChatComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Account.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonalWeb.DocumentTemplateComponent
  alias BemedaPersonalWeb.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers

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
        placeholder={dgettext("general", "Type a message or drag and drop a file...")}
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

  attr :job_application, JobApplication
  attr :is_employer?, :boolean

  @spec chat_contact_name(assigns()) :: output()
  def chat_contact_name(%{is_employer?: true} = assigns) do
    ~H"""
    <span>
      {"#{@job_application.user.first_name} #{@job_application.user.last_name}"}
    </span>
    """
  end

  def chat_contact_name(assigns) do
    ~H"""
    <span>
      {@job_application.job_posting.company.name}
    </span>
    """
  end

  attr :current_user, User
  attr :id, :string
  attr :is_employer?, :boolean
  attr :job_application, JobApplication
  attr :message, Message

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

      <div class={@class}>
        <SharedComponents.video_player media_asset={@message.media_asset} />
      </div>
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
        @message.type == :status_update && "mx-auto bg-purple-100 rounded-2xl",
        @message.sender_id == @current_user.id && @message.type != :status_update &&
          "ml-auto rounded-2xl rounded-br-none",
        @message.sender_id != @current_user.id && @message.type != :status_update &&
          "mr-auto rounded-2xl rounded-bl-none",
        @message.content && @message.sender_id == @current_user.id && "bg-blue-100 ",
        @message.content && @message.sender_id != @current_user.id && "bg-gray-100 "
      ]}
    >
      <.chat_message
        current_user={@current_user}
        is_employer?={@is_employer?}
        job_application={@job_application}
        message={@message}
      />
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :current_user, User
  attr :is_employer?, :boolean
  attr :job_application, :any, default: nil
  attr :message, Message

  defp chat_message(
         %{message: %{media_asset: %MediaAsset{type: "video" <> _rest, status: :pending}}} =
           assigns
       ) do
    ~H"""
    <div class="w-full h-[200px] bg-zinc-200 rounded-lg flex items-center justify-center">
      <.icon name="hero-arrow-up-on-square" class="h-12 w-12 text-[#075389] animate-pulse" />
    </div>
    """
  end

  defp chat_message(
         %{
           message: %{
             media_asset: %MediaAsset{
               type: "video" <> _rest,
               status: :uploaded
             }
           }
         } = assigns
       ) do
    ~H"""
    <SharedComponents.video_player class="w-full" media_asset={@message.media_asset} />
    """
  end

  defp chat_message(
         %{message: %{media_asset: %MediaAsset{type: "audio" <> _rest, status: :pending}}} =
           assigns
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

  defp chat_message(
         %{
           message: %{
             media_asset: %MediaAsset{
               type: "audio" <> _rest,
               status: :uploaded
             }
           }
         } = assigns
       ) do
    ~H"""
    <audio class="w-full" controls>
      <source src={SharedHelpers.get_presigned_url(@message.media_asset.upload_id)} type="audio/mp3" />
    </audio>
    """
  end

  defp chat_message(
         %{message: %{media_asset: %MediaAsset{type: "image" <> _rest, status: :pending}}} =
           assigns
       ) do
    ~H"""
    <div class="w-full h-[200px] bg-zinc-200 rounded-lg flex items-center justify-center">
      <.icon name="hero-photo" class="h-12 w-12 text-[#075389] animate-pulse" />
    </div>
    """
  end

  defp chat_message(%{message: %{media_asset: %MediaAsset{type: "image" <> _rest}}} = assigns) do
    ~H"""
    <div class="w-full overflow-hidden rounded-lg">
      <img
        src={SharedHelpers.get_presigned_url(@message.media_asset.upload_id)}
        alt={@message.media_asset.file_name || dgettext("general", "Image")}
        class="w-full h-auto object-contain max-h-[400px]"
      />
    </div>
    """
  end

  defp chat_message(%{message: %{media_asset: %MediaAsset{status: :pending}}} = assigns) do
    ~H"""
    <div class="w-full bg-[#e9eef2] rounded-lg p-3 flex items-center">
      <.icon name="hero-document" class="h-6 w-6 text-[#075389] mr-3" />
      <div class="flex flex-col">
        <span class="text-sm font-medium text-zinc-800">
          {dgettext("general", "Uploading file...")}
        </span>
        <span class="text-xs text-zinc-500">{dgettext("general", "Processing...")}</span>
      </div>
    </div>
    """
  end

  defp chat_message(%{message: %{media_asset: %MediaAsset{status: :uploaded}}} = assigns) do
    assigns =
      assign_new(assigns, :extension, fn %{message: message} ->
        message.media_asset.file_name
        |> String.split(".")
        |> List.last()
      end)

    ~H"""
    <div class="w-full bg-[#e9eef2] rounded-lg p-3">
      <.link
        href={SharedHelpers.get_presigned_url(@message.media_asset.upload_id)}
        target="_blank"
        class="flex items-center hover:bg-[#d6e6f1] p-2 rounded-lg transition-colors"
      >
        <.icon name="hero-document" class="h-6 w-6 text-[#075389] mr-3" />
        <p class="text-sm font-medium text-zinc-800">
          <span>{@message.media_asset.file_name}</span>
        </p>
      </.link>

      <.additional_actions
        current_user={@current_user}
        extension={@extension}
        job_application={@job_application}
        message={@message}
      />
    </div>
    """
  end

  defp chat_message(%{message: %{type: :status_update}} = assigns) do
    ~H"""
    <div class="w-full flex justify-center my-2">
      <div class="bg-purple-100 text-purple-800 rounded-xl py-2 px-4 text-center text-sm">
        <p>{get_message_content(@message.content, @is_employer?)}</p>
      </div>
    </div>
    """
  end

  defp chat_message(assigns) do
    ~H"""
    <div class="p-3">
      <p class="text-sm">{@message.content}</p>
    </div>
    """
  end

  defp get_message_content(content, employer?)

  defp get_message_content(content, true) do
    employer_messages = %{
      "applied" => dgettext("jobs", "This application has been submitted"),
      "interview_scheduled" =>
        dgettext("jobs", "An interview has been scheduled for this application"),
      "interviewed" => dgettext("jobs", "This candidate has been interviewed"),
      "offer_accepted" => dgettext("jobs", "The offer has been accepted"),
      "offer_declined" => dgettext("jobs", "The offer has been declined"),
      "offer_extended" => dgettext("jobs", "An offer has been extended for this position"),
      "rejected" => dgettext("jobs", "This application has been rejected"),
      "screening" => dgettext("jobs", "This application is now in the screening phase"),
      "under_review" => dgettext("jobs", "This application is now under review"),
      "withdrawn" => dgettext("jobs", "This application has been withdrawn")
    }

    Map.get(employer_messages, content, content)
  end

  defp get_message_content(content, false) do
    candidate_messages = %{
      "applied" => dgettext("jobs", "You have submitted your application"),
      "interview_scheduled" => dgettext("jobs", "Your interview has been scheduled"),
      "interviewed" => dgettext("jobs", "You have been interviewed"),
      "offer_accepted" => dgettext("jobs", "You have accepted the offer"),
      "offer_declined" => dgettext("jobs", "You have declined the offer"),
      "offer_extended" => dgettext("jobs", "An offer has been extended to you"),
      "rejected" => dgettext("jobs", "Your application has been rejected"),
      "screening" => dgettext("jobs", "Your application is in the screening phase"),
      "under_review" => dgettext("jobs", "Your application is now under review"),
      "withdrawn" => dgettext("jobs", "You have withdrawn your application")
    }

    Map.get(candidate_messages, content, content)
  end

  defp additional_actions(%{extension: extension} = assigns) when extension in ["doc", "docx"] do
    ~H"""
    <.live_component
      current_user={@current_user}
      id={"document-template-#{@message.id}"}
      job_application={@job_application}
      message={@message}
      module={DocumentTemplateComponent}
    />
    """
  end

  defp additional_actions(assigns) do
    ~H"""
    """
  end
end
