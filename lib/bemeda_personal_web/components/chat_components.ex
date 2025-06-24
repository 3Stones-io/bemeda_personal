defmodule BemedaPersonalWeb.ChatComponents do
  @moduledoc false

  use BemedaPersonalWeb, :html

  alias BemedaPersonal.Account.User
  alias BemedaPersonal.Chat.Message
  alias BemedaPersonal.DateUtils
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.Media.MediaAsset
  alias BemedaPersonal.Resumes.Resume
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
  def chat_container(%{message: %Resume{}} = assigns) do
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
        <div class="p-3">
          <.resume_document_link message={@message} />
          <.resume_expanded_content message={@message} />
        </div>
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

  defp chat_message(
         %{message: %{media_asset: %MediaAsset{type: "application/pdf", status: :uploaded}}} =
           assigns
       ) do
    ~H"""
    <div
      id={"pdf-preview-#{@message.id}"}
      class="pdf-message w-full bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden"
      phx-hook="PdfPreview"
      data-pdf-url={SharedHelpers.get_presigned_url(@message.media_asset.upload_id)}
      data-upload-id={@message.media_asset.upload_id}
      data-max-pages="4"
      data-loading-text={dgettext("general", "Loading PDF preview...")}
      data-error-preview-unavailable={dgettext("general", "Preview unavailable")}
      data-error-details-unavailable={dgettext("general", "Unable to load PDF preview")}
      data-error-invalid-pdf={dgettext("general", "Invalid PDF file")}
      data-error-file-corrupted={dgettext("general", "The file appears to be corrupted")}
      data-error-not-found={dgettext("general", "PDF not found")}
      data-error-file-not-loaded={dgettext("general", "The file could not be loaded")}
      data-error-loading={dgettext("general", "Loading error")}
      data-error-viewer-unavailable={dgettext("general", "PDF viewer temporarily unavailable")}
      data-error-timeout={dgettext("general", "Loading timeout")}
      data-error-timeout-details={dgettext("general", "The PDF is taking too long to load")}
      data-error-service-unavailable={dgettext("general", "Service unavailable")}
      data-error-viewer-not-loaded={dgettext("general", "PDF viewer could not be loaded")}
      data-access-file-message={
        dgettext("general", "Use the download button below to access the file")
      }
    >
      <div class="pdf-preview-container">
        <div class="animate-pulse bg-gray-200 h-[120px] rounded-t-lg flex items-center justify-center">
          <p class="text-gray-500 text-sm">{dgettext("general", "Loading PDF preview...")}</p>
        </div>
      </div>

      <div class="p-3 bg-gray-50 border-t border-gray-200">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <.icon name="hero-document-text" class="h-5 w-5 text-red-600 mr-2" />
            <p class="text-sm font-medium text-gray-800">
              {@message.media_asset.file_name}
            </p>
          </div>
          <button
            phx-click="download_pdf"
            phx-value-upload-id={@message.media_asset.upload_id}
            class="inline-flex items-center px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md font-medium transition-colors duration-200"
          >
            <.icon name="hero-arrow-down-tray" class="w-4 h-4 mr-1" /> {dgettext(
              "general",
              "Download"
            )}
          </button>
        </div>
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

  defp format_date_range(start_date, end_date, current) do
    start_formatted = BemedaPersonal.DateUtils.format_date(start_date)

    end_formatted =
      if current do
        "Present"
      else
        BemedaPersonal.DateUtils.format_date(end_date)
      end

    "#{start_formatted} - #{end_formatted}"
  end

  attr :message, Resume, required: true

  defp resume_document_link(assigns) do
    ~H"""
    <div
      class="bg-white border border-gray-200 rounded-lg shadow-sm cursor-pointer hover:shadow-md transition-shadow"
      phx-click={JS.toggle(to: "#resume-content-#{@message.id}")}
    >
      <div class="flex items-center p-4">
        <div class="flex-shrink-0 mr-3">
          <div class="w-10 h-10 bg-red-500 rounded-lg flex items-center justify-center">
            <.icon name="hero-document-text" class="h-6 w-6 text-white" />
          </div>
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-medium text-gray-900 truncate">
            {if @message.user,
              do: "#{@message.user.first_name} #{@message.user.last_name}",
              else: "Resume"}
          </h3>
          <p class="text-xs text-gray-500">
            {dgettext("resumes", "Resume")} • {DateUtils.format_emails_date(@message.updated_at)}
          </p>
        </div>
        <div class="flex-shrink-0">
          <.icon name="hero-chevron-down" class="h-4 w-4 text-gray-400" />
        </div>
      </div>
    </div>
    """
  end

  attr :message, Resume, required: true

  defp resume_expanded_content(assigns) do
    ~H"""
    <div
      id={"resume-content-#{@message.id}"}
      class="hidden mt-3 bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden"
    >
      <.resume_header />

      <div class="divide-y divide-gray-200">
        <.resume_section
          message={@message}
          section_id="profile"
          icon="hero-user"
          title="Profile"
          other_sections={["work", "education"]}
        >
          <.resume_profile_content message={@message} />
        </.resume_section>

        <.resume_section
          :if={@message.work_experiences && length(@message.work_experiences) > 0}
          message={@message}
          section_id="work"
          icon="hero-briefcase"
          title={"#{dgettext("resumes", "Work Experience")} (#{length(@message.work_experiences)})"}
          other_sections={["profile", "education"]}
        >
          <.resume_work_content message={@message} />
        </.resume_section>

        <.resume_section
          :if={@message.educations && length(@message.educations) > 0}
          message={@message}
          section_id="education"
          icon="hero-academic-cap"
          title={"#{dgettext("resumes", "Education")} (#{length(@message.educations)})"}
          other_sections={["profile", "work"]}
        >
          <.resume_education_content message={@message} />
        </.resume_section>

        <.resume_empty_state :if={
          (!@message.work_experiences || length(@message.work_experiences) == 0) &&
            (!@message.educations || length(@message.educations) == 0)
        } />
      </div>
    </div>
    """
  end

  defp resume_header(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-4 py-3">
      <h2 class="text-lg font-semibold text-white flex items-center">
        <.icon name="hero-document-text" class="h-5 w-5 mr-2" />
        {dgettext("resumes", "Resume")}
      </h2>
    </div>
    """
  end

  attr :message, Resume, required: true
  attr :section_id, :string, required: true
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :other_sections, :list, required: true
  slot :inner_block, required: true

  defp resume_section(assigns) do
    hide_commands =
      Enum.reduce(assigns.other_sections, %Phoenix.LiveView.JS{}, fn section, acc ->
        JS.hide(acc, to: "#resume-#{section}-#{assigns.message.id}")
      end)

    assigns = assign(assigns, :hide_commands, hide_commands)

    ~H"""
    <div
      class="p-4 cursor-pointer hover:bg-gray-50"
      phx-click={@hide_commands |> JS.toggle(to: "#resume-#{@section_id}-#{@message.id}")}
    >
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-gray-900 flex items-center">
          <.icon name={@icon} class="h-4 w-4 mr-2 text-gray-600" />
          {@title}
        </h3>
        <.icon name="hero-chevron-down" class="h-4 w-4 text-gray-400" />
      </div>
      <div id={"resume-#{@section_id}-#{@message.id}"} class="hidden mt-3 space-y-3">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :message, Resume, required: true

  defp resume_profile_content(assigns) do
    ~H"""
    <div>
      <h4 class="text-sm font-semibold text-gray-800">
        {@message.headline || dgettext("resumes", "Professional")}
      </h4>
      <p class="text-xs text-gray-600 mt-1 leading-relaxed">
        {@message.summary || dgettext("resumes", "No summary provided")}
      </p>
    </div>
    <div class="grid grid-cols-1 gap-2 text-xs">
      <.contact_info_item
        icon="hero-envelope"
        text={
          @message.contact_email || (@message.user && @message.user.email) ||
            dgettext("resumes", "Email not provided")
        }
      />
      <.contact_info_item :if={@message.phone_number} icon="hero-phone" text={@message.phone_number} />
      <.contact_info_item
        :if={@message.website_url}
        icon="hero-link"
        text={@message.website_url}
        is_link={true}
      />
    </div>
    """
  end

  attr :message, Resume, required: true

  defp resume_work_content(assigns) do
    ~H"""
    <.experience_item
      :for={work_exp <- @message.work_experiences}
      title={work_exp.title}
      subtitle={work_exp.company_name}
      location={work_exp.location}
      start_date={work_exp.start_date}
      end_date={work_exp.end_date}
      current={work_exp.current}
      description={work_exp.description}
      border_color="border-blue-200"
    />
    """
  end

  attr :message, Resume, required: true

  defp resume_education_content(assigns) do
    ~H"""
    <.experience_item
      :for={education <- @message.educations}
      title={education.institution}
      subtitle={
        if education.field_of_study,
          do: "#{education.degree} #{dgettext("resumes", "in")} #{education.field_of_study}",
          else: education.degree
      }
      location=""
      start_date={education.start_date}
      end_date={education.end_date}
      current={education.current}
      description={education.description}
      border_color="border-green-200"
    />
    """
  end

  attr :icon, :string, required: true
  attr :text, :string, required: true
  attr :is_link, :boolean, default: false

  defp contact_info_item(assigns) do
    ~H"""
    <div class="flex items-center text-gray-600">
      <.icon name={@icon} class="h-3 w-3 mr-2 text-gray-500" />
      <span :if={!@is_link}>{@text}</span>
      <a :if={@is_link} href={@text} target="_blank" class="text-blue-600 hover:underline truncate">
        {@text}
      </a>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :location, :string, default: ""
  attr :start_date, :any, required: true
  attr :end_date, :any, required: true
  attr :current, :boolean, required: true
  attr :description, :string, default: nil
  attr :border_color, :string, required: true

  defp experience_item(assigns) do
    ~H"""
    <div class={"border-l-2 #{@border_color} pl-3"}>
      <h4 class="text-xs font-medium text-gray-800">{@title}</h4>
      <p class="text-xs text-gray-600">{@subtitle}</p>
      <p :if={@location} class="text-xs text-gray-500">{@location}</p>
      <p class="text-xs text-gray-500">
        {format_date_range(@start_date, @end_date, @current)}
      </p>
      <p :if={@description} class="text-xs text-gray-600 mt-1 line-clamp-2">
        {@description}
      </p>
    </div>
    """
  end

  defp resume_empty_state(assigns) do
    ~H"""
    <div class="p-4 text-center text-gray-500 text-xs">
      No additional information available
    </div>
    """
  end
end
