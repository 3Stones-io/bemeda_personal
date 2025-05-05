defmodule BemedaPersonalWeb.JobApplicationLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Chat
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Resumes
  alias BemedaPersonal.TigrisHelper
  alias BemedaPersonalWeb.ChatComponents
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias Phoenix.Socket.Broadcast

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
     |> stream(:messages, [])}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  # REVIEW: USE JS FOR MODAL.
  # BETTER NAME FOR EVENT
  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    job_application = socket.assigns.job_application

    uploaded_files =
      consume_uploaded_entries(socket, :resume, fn %{path: path}, entry ->
        # Create a media asset for the job application
        case Media.create_media_asset_for_job_application(job_application, %{
               file_name: entry.client_name,
               content_type: entry.client_type,
               path: path,
               status: :uploaded
             }) do
          {:ok, media_asset} -> {:ok, media_asset}
          {:error, _} -> {:error, :upload_failed}
        end
      end)

    case uploaded_files do
      [_asset] ->
        updated_job_application = Jobs.get_job_application!(job_application.id)

        {:noreply,
         socket
         |> put_flash(:info, "Resume uploaded successfully.")
         |> assign(:job_application, updated_job_application)}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to upload resume.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("open-state-modal", %{"state" => to_state}, socket) do
    # Create a changeset for the state transition form
    changeset = %{"notes" => ""}

    {:noreply,
     socket
     |> assign(:show_state_modal, true)
     |> assign(:transition_to_state, to_state)
     |> assign(:state_form, to_form(changeset, as: :state_update))}
  end

  def handle_event("close-state-modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_state_modal, false)
     |> assign(:transition_to_state, nil)
     |> assign(:state_form, nil)}
  end

  # MAYBE DO THIS IN CONTEXT -> MESSAGE CREATION THAT IS
  # YIKES: this is a mess.
  def handle_event("update-state-with-notes", %{"state_update" => params}, socket) do
    job_application = socket.assigns.job_application
    current_user = socket.assigns.current_user
    from_state = job_application.state
    to_state = socket.assigns.transition_to_state
    notes = params["notes"]

    case Jobs.update_job_application_state(
           job_application,
           to_state,
           %{notes: notes},
           current_user
         ) do
      {:ok, updated_job_application} ->
        # Create a status update message
        status_message =
          "Status changed from #{format_state_name(from_state)} to #{format_state_name(to_state)} by #{current_user.email}"

        {:ok, message} =
          Chat.create_message(
            current_user,
            updated_job_application,
            %{content: status_message}
          )

        # Get the latest state transition
        [latest_transition | _] =
          Jobs.list_job_application_state_transitions(updated_job_application)
          |> Enum.reverse()

        # Add the transition to the socket assigns for rendering in the template
        socket =
          socket
          |> assign(:latest_transition, latest_transition)
          |> assign(:show_state_modal, false)
          |> assign(:transition_to_state, nil)
          |> assign(:state_form, nil)

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:job_application, updated_job_application)}

      {:error, reason} when is_binary(reason) ->
        {:noreply,
         socket
         |> assign(:show_state_modal, false)
         |> put_flash(:error, reason)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = translate_errors(changeset)

        {:noreply,
         socket
         |> assign(:show_state_modal, false)
         |> put_flash(:error, "Error: #{errors}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset =
      %Chat.Message{}
      |> Chat.change_message(message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_chat_form(socket, changeset)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("send-message", %{"message" => message_params}, socket) do
    case Chat.create_message(
           socket.assigns.current_user,
           socket.assigns.job_application,
           message_params
         ) do
      {:ok, message} ->
        changeset = Chat.change_message(%Chat.Message{})

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign_chat_form(changeset)}

      {:error, changeset} ->
        {:noreply, assign_chat_form(socket, changeset)}
    end
  end

  # JS
  def handle_event("close-modal", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload-media", %{"filename" => filename, "type" => type}, socket) do
    {:ok, message} =
      Chat.create_message_with_media(
        socket.assigns.current_user,
        socket.assigns.job_application,
        %{
          "media_data" => %{
            "file_name" => filename,
            "type" => type,
            "status" => :pending
          }
        }
      )

    upload_url = TigrisHelper.get_presigned_upload_url(message.id)

    {:reply, %{upload_url: upload_url, message_id: message.id},
     stream_insert(socket, :messages, message)}
  end

  def handle_event(
        "update-message",
        %{"message_id" => message_id, "status" => "uploaded"},
        socket
      ) do
    message = Chat.get_message!(message_id)

    media_asset =
      Media.get_media_asset_by_message_id(message.id)

    {:ok, _media_asset} =
      Media.update_media_asset(media_asset, %{status: :uploaded})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "message_created",
             "message_updated"
           ] do
    {:noreply, stream_insert(socket, :messages, payload.message)}
  end

  def handle_info(%Broadcast{event: "media_asset_updated", payload: %{message: message}}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(
        %Broadcast{event: "media_asset_updated", payload: %{job_application: job_application}},
        socket
      ) do
    {:noreply, assign(socket, :job_application, job_application)}
  end

  def handle_info(
        %Broadcast{
          event: "job_application_state_changed",
          payload: %{job_application: job_application, from_state: from_state, to_state: to_state}
        },
        socket
      ) do
    # If the state change was triggered by someone else, create a status message
    if job_application.id == socket.assigns.job_application.id &&
         socket.assigns.current_user.id != job_application.current_user.id do
      # Get the latest transition
      [latest_transition | _] =
        Jobs.list_job_application_state_transitions(job_application)
        |> Enum.reverse()

      # Create a status update message
      transitioned_by = latest_transition.transitioned_by.email

      status_message =
        "Status changed from #{format_state_name(from_state)} to #{format_state_name(to_state)} by #{transitioned_by}"

      {:ok, _message} =
        Chat.create_message(
          latest_transition.transitioned_by,
          job_application,
          %{content: status_message}
        )
    end

    {:noreply, assign(socket, :job_application, job_application)}
  end

  defp apply_action(socket, :show, %{"id" => job_application_id}) do
    job_application = Jobs.get_job_application!(job_application_id)
    messages = Chat.list_messages(job_application)
    changeset = Chat.change_message(%Chat.Message{})

    job_posting = Jobs.get_job_posting!(job_application.job_posting_id)
    # Ensure admin_user is preloaded in company
    job_posting = Repo.preload(job_posting, company: :admin_user)

    # Get the applicant's resume
    applicant_resume = Resumes.get_user_resume(job_application.user)

    if connected?(socket) do
      Endpoint.subscribe("messages:job_application:#{job_application_id}")
      Endpoint.subscribe("job_application_messages_assets_#{job_application_id}")
      Endpoint.subscribe("job_application_assets_#{job_application_id}")
      Endpoint.subscribe("job_application:#{job_application_id}")
    end

    socket
    |> stream(:messages, messages)
    |> assign(:job_application, job_application)
    |> assign(:job_posting, job_posting)
    |> assign(:applicant_resume, applicant_resume)
    |> assign(:show_state_modal, false)
    |> assign(:transition_to_state, nil)
    |> assign_chat_form(changeset)
  end

  defp assign_chat_form(socket, changeset) do
    assign(socket, :chat_form, to_form(changeset))
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
  end

  def get_application_state_transitions(job_application) do
    Jobs.list_job_application_state_transitions(job_application)
  end

  def get_download_url(media_asset) do
    TigrisHelper.get_presigned_download_url(media_asset.id)
  end

  def owner?(current_user, job_application) do
    current_user.id == job_application.user_id
  end

  def format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  def has_resume?(job_application) do
    job_application.media_asset != nil
  end

  def render_application_status(state) do
    status_class = JobsComponents.status_color(state)
    state_name = JobsComponents.format_state_name(state)

    assigns = %{status_class: status_class, state_name: state_name}

    ~H"""
    <span class={"px-3 py-1 rounded-full text-sm font-medium #{@status_class}"}>
      {@state_name}
    </span>
    """
  end

  def format_state_name(state) do
    JobsComponents.format_state_name(state)
  end

  def format_state_action(state) do
    JobsComponents.format_state_action(state)
  end

  def get_next_states(current_state) do
    transitions = %{
      "applied" => ["under_review", "withdrawn", "rejected"],
      "under_review" => ["screening", "withdrawn", "rejected"],
      "screening" => ["interview_scheduled", "withdrawn", "rejected"],
      "interview_scheduled" => ["interviewed", "withdrawn", "rejected"],
      "interviewed" => ["offer_pending", "withdrawn", "rejected"],
      "offer_pending" => ["offer_extended", "withdrawn", "rejected"],
      "offer_extended" => ["offer_accepted", "offer_declined", "withdrawn"],
      "offer_accepted" => [],
      "offer_declined" => [],
      "withdrawn" => [],
      "rejected" => []
    }

    transitions[current_state] || []
  end

  def can_transition?(current_user, job_application) do
    is_admin = current_user.id == job_application.job_posting.company.admin_user_id
    is_applicant = current_user.id == job_application.user_id

    # Determine if current state is terminal
    terminal_states = ["withdrawn", "offer_declined", "offer_accepted", "rejected"]
    is_terminal = job_application.state in terminal_states

    # Applicants can't see actions for terminal states, admins can see explanatory message
    cond do
      is_applicant && is_terminal -> false
      is_admin || is_applicant -> true
      true -> false
    end
  end

  def is_admin?(current_user, job_application) do
    current_user.id == job_application.job_posting.company.admin_user_id
  end

  def is_owner?(current_user, job_application) do
    current_user.id == job_application.user_id
  end

  def is_terminal?(state) do
    state in ["withdrawn", "offer_declined", "offer_accepted", "rejected"]
  end

  def can_transition_to?(current_user, job_application, to_state) do
    is_admin = current_user.id == job_application.job_posting.company.admin_user_id
    is_applicant = current_user.id == job_application.user_id
    current_state = job_application.state

    # Terminal states that can't be transitioned from
    terminal_states = ["withdrawn", "offer_declined", "offer_accepted", "rejected"]

    # Don't allow any transitions if current state is terminal
    if current_state in terminal_states do
      false
    else
      user_allowed_states = ["withdrawn"]
      admin_allowed_states = get_next_states(current_state) -- ["withdrawn"]

      cond do
        is_admin && to_state in admin_allowed_states ->
          true

        is_applicant && to_state in user_allowed_states ->
          true

        is_applicant && current_state == "offer_extended" &&
            to_state in ["offer_accepted", "offer_declined"] ->
          true

        true ->
          false
      end
    end
  end

  def get_action_button_class(state) do
    JobsComponents.get_action_button_class(state)
  end
end
