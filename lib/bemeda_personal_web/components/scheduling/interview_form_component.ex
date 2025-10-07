defmodule BemedaPersonalWeb.Scheduling.InterviewFormComponent do
  @moduledoc false

  use BemedaPersonalWeb, :live_component

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Scheduling
  alias BemedaPersonalWeb.SharedHelpers

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {dgettext("jobs", "Schedule a Meeting")}
        <:subtitle>{dgettext("jobs", "Schedule an interview with the candidate")}</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="interview-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        phx-hook="TimezoneDetector"
      >
        <.input
          field={@form[:title]}
          type="text"
          label={dgettext("jobs", "Add a title")}
          placeholder={dgettext("jobs", "Interview with") <> " " <> User.full_name(@job_application.user)}
        />

        <div class="grid grid-cols-2 gap-4">
          <.input
            field={@form[:scheduled_at_date]}
            type="date"
            label={dgettext("jobs", "Date")}
            required
          />
          <.input
            field={@form[:scheduled_at_time]}
            type="time"
            label={dgettext("jobs", "Start Time")}
            required
          />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <.input
            field={@form[:end_date]}
            type="date"
            label={dgettext("jobs", "End Date")}
            required
          />
          <.input
            field={@form[:end_time]}
            type="time"
            label={dgettext("jobs", "End Time")}
            required
          />
        </div>

        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700">
            {dgettext("jobs", "Attendees")}
          </label>
          <div class="flex items-center gap-2 p-2 bg-gray-50 rounded-md">
            <.icon name="hero-user-circle" class="w-5 h-5 text-gray-500" />
            <span class="text-sm">{@current_company.name}</span>
            <button
              type="button"
              class="ml-auto text-gray-400 hover:text-gray-600"
              phx-click="remove_attendee"
              phx-value-type="company"
              phx-target={@myself}
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>
          <div class="flex items-center gap-2 p-2 bg-gray-50 rounded-md">
            <img
              :if={@job_application.user.media_asset}
              src={SharedHelpers.get_media_asset_url(@job_application.user.media_asset)}
              alt=""
              class="w-5 h-5 rounded-full"
            />
            <.icon
              :if={!@job_application.user.media_asset}
              name="hero-user-circle"
              class="w-5 h-5 text-gray-500"
            />
            <span class="text-sm">{User.full_name(@job_application.user)}</span>
          </div>
          <input
            type="text"
            placeholder={dgettext("jobs", "Type email or name here...")}
            class="w-full px-3 py-2 border border-gray-300 rounded-md"
            phx-keyup="search_attendees"
            phx-target={@myself}
          />
        </div>

        <.input
          field={@form[:meeting_link]}
          type="url"
          label={dgettext("jobs", "Add a Link")}
          placeholder="https://zoom.us/j/..."
          required
        />

        <.input
          field={@form[:reminder_minutes_before]}
          type="select"
          label={dgettext("jobs", "Notify me")}
          options={reminder_options()}
          value={30}
        />

        <.input
          field={@form[:notes]}
          type="textarea"
          label={dgettext("jobs", "Leave a note")}
          placeholder={dgettext("jobs", "Additional information for the interview...")}
        />

        <input
          type="hidden"
          name={@form[:timezone].name}
          id="interview_timezone"
          value={@form[:timezone].value || ""}
        />

        <:actions>
          <.button
            type="button"
            variant="secondary"
            phx-click={JS.push("close_modal", target: @myself)}
          >
            {dgettext("jobs", "Cancel")}
          </.button>
          <.button type="submit" variant="primary" data-test-id="done-button">
            {dgettext("jobs", "Done")}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{job_application: job_application} = assigns, socket) do
    # Check if we're editing an existing interview
    {interview, changeset} =
      case Map.get(assigns, :edit_interview) do
        nil ->
          new_interview = %Scheduling.Interview{}
          default_attrs = %{timezone: "UTC"}
          {new_interview, Scheduling.change_interview(new_interview, default_attrs)}

        existing_interview ->
          # Populate virtual date/time fields for the form
          edit_attrs = extract_datetime_fields(existing_interview)
          {existing_interview, Scheduling.change_interview(existing_interview, edit_attrs)}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:job_application, job_application)
     |> assign(:interview, interview)
     |> assign(:edit_mode, !is_nil(Map.get(assigns, :edit_interview)))
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"interview" => interview_params}, socket) do
    params = merge_datetime_params(interview_params)

    changeset =
      socket.assigns.interview
      |> Scheduling.change_interview(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"interview" => interview_params}, socket) do
    params = prepare_interview_params(interview_params, socket)
    result = save_interview(params, socket)

    handle_save_result(result, socket)
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_attendee", %{"type" => "company"}, socket) do
    # In this basic implementation, we just ignore the remove request
    # since company attendance is required
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("search_attendees", %{"value" => _query}, socket) do
    # Attendee search not implemented - currently only supports company and job applicant attendees
    # Future enhancement: implement user search for additional attendees
    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp has_datetime_fields?(params) do
    Map.has_key?(params, "scheduled_at_date") or
      Map.has_key?(params, "scheduled_at_time") or
      Map.has_key?(params, "end_date") or
      Map.has_key?(params, "end_time")
  end

  defp merge_datetime_params(params) do
    scheduled_at =
      build_datetime(
        params["scheduled_at_date"],
        params["scheduled_at_time"]
      )

    end_time =
      build_datetime(
        params["end_date"] || params["scheduled_at_date"],
        params["end_time"]
      )

    params
    |> Map.drop(["scheduled_at_date", "scheduled_at_time", "end_date", "end_time"])
    |> Map.put("scheduled_at", scheduled_at)
    |> Map.put("end_time", end_time)
  end

  defp build_datetime(nil, _time), do: nil
  defp build_datetime(_date, nil), do: nil
  defp build_datetime("", _time), do: nil
  defp build_datetime(_date, ""), do: nil

  defp build_datetime(date, time) do
    with {:ok, date} <- Date.from_iso8601(date),
         {:ok, time} <- Time.from_iso8601(time <> ":00") do
      DateTime.new!(date, time, "Etc/UTC")
    else
      _error -> nil
    end
  end

  defp prepare_interview_params(interview_params, socket) do
    params = process_datetime_params(interview_params, socket)
    maybe_add_creation_params(params, socket)
  end

  defp process_datetime_params(interview_params, socket) do
    if has_datetime_fields?(interview_params) do
      process_merged_datetime_params(interview_params, socket)
    else
      process_base_datetime_params(interview_params, socket)
    end
  end

  defp process_merged_datetime_params(interview_params, socket) do
    merged =
      interview_params
      |> merge_datetime_params()
      |> Map.put("timezone", interview_params["timezone"] || "UTC")

    maybe_preserve_existing_datetimes(merged, socket)
  end

  defp process_base_datetime_params(interview_params, socket) do
    base_params = Map.put(interview_params, "timezone", interview_params["timezone"] || "UTC")
    maybe_add_missing_datetimes(base_params, socket)
  end

  defp maybe_preserve_existing_datetimes(merged, %{
         assigns: %{edit_mode: true, interview: interview}
       }) do
    merged
    |> Map.update("scheduled_at", interview.scheduled_at, fn
      nil -> interview.scheduled_at
      val -> val
    end)
    |> Map.update("end_time", interview.end_time, fn
      nil -> interview.end_time
      val -> val
    end)
  end

  defp maybe_preserve_existing_datetimes(merged, _socket), do: merged

  defp maybe_add_missing_datetimes(base_params, %{
         assigns: %{edit_mode: true, interview: interview}
       }) do
    base_params
    |> Map.put_new("scheduled_at", interview.scheduled_at)
    |> Map.put_new("end_time", interview.end_time)
  end

  defp maybe_add_missing_datetimes(base_params, _socket), do: base_params

  defp maybe_add_creation_params(params, %{assigns: %{edit_mode: true}}), do: params

  defp maybe_add_creation_params(params, socket) do
    params
    |> Map.put("job_application_id", socket.assigns.job_application.id)
    |> Map.put("created_by_id", socket.assigns.current_user.id)
  end

  defp save_interview(params, socket) do
    if socket.assigns.edit_mode do
      Scheduling.update_interview(
        socket.assigns.current_scope,
        socket.assigns.interview,
        params
      )
    else
      Scheduling.create_interview(socket.assigns.current_scope, params)
    end
  end

  defp handle_save_result(result, socket) do
    case result do
      {:ok, interview} ->
        flash_message =
          if socket.assigns.edit_mode do
            dgettext("jobs", "Interview updated successfully")
          else
            dgettext("jobs", "Interview scheduled successfully")
          end

        notify_parent({:saved, interview, flash_message})

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           dgettext("jobs", "You are not authorized to modify this interview")
         )
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp reminder_options do
    [
      {dgettext("jobs", "5 minutes before"), 5},
      {dgettext("jobs", "10 minutes before"), 10},
      {dgettext("jobs", "15 minutes before"), 15},
      {dgettext("jobs", "30 minutes before"), 30},
      {dgettext("jobs", "1 hour before"), 60},
      {dgettext("jobs", "1 day before"), 1440}
    ]
  end

  defp extract_datetime_fields(%Scheduling.Interview{} = interview) do
    %{}
    |> maybe_add_scheduled_at_fields(interview.scheduled_at)
    |> maybe_add_end_time_fields(interview.end_time)
  end

  defp maybe_add_scheduled_at_fields(attrs, nil), do: attrs

  defp maybe_add_scheduled_at_fields(attrs, scheduled_at) do
    {date, time} = {DateTime.to_date(scheduled_at), DateTime.to_time(scheduled_at)}

    time_string =
      time
      |> Time.to_iso8601()
      |> String.slice(0, 5)

    attrs
    |> Map.put("scheduled_at_date", Date.to_iso8601(date))
    |> Map.put("scheduled_at_time", time_string)
  end

  defp maybe_add_end_time_fields(attrs, nil), do: attrs

  defp maybe_add_end_time_fields(attrs, end_time) do
    {date, time} = {DateTime.to_date(end_time), DateTime.to_time(end_time)}

    time_string =
      time
      |> Time.to_iso8601()
      |> String.slice(0, 5)

    attrs
    |> Map.put("end_date", Date.to_iso8601(date))
    |> Map.put("end_time", time_string)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
