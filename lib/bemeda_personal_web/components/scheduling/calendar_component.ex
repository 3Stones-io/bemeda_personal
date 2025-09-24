defmodule BemedaPersonalWeb.Scheduling.CalendarComponent do
  @moduledoc """
  Calendar component for displaying interviews in a monthly view.
  """

  use BemedaPersonalWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="calendar-container">
      <div class="flex items-center justify-between mb-4">
        <button
          phx-click="prev_month"
          phx-target={@myself || ""}
          class="p-2 hover:bg-gray-100 rounded-lg"
        >
          <.icon name="hero-chevron-left" class="w-5 h-5" />
        </button>

        <div class="flex items-center gap-2">
          <h2 class="text-xl font-semibold">
            {format_month_year(@current_date)}
          </h2>
          <button
            phx-click="toggle_month_selector"
            phx-target={@myself || ""}
            class="p-1 hover:bg-gray-100 rounded"
          >
            <.icon name="hero-chevron-down" class="w-4 h-4" />
          </button>
        </div>

        <button
          phx-click="next_month"
          phx-target={@myself || ""}
          class="p-2 hover:bg-gray-100 rounded-lg"
        >
          <.icon name="hero-chevron-right" class="w-5 h-5" />
        </button>
      </div>

      <div class="grid grid-cols-7 gap-px bg-gray-200">
        <div
          :for={day <- ~w(Sun Mon Tue Wed Thu Fri Sat)}
          class="bg-white p-2 text-center text-sm font-medium text-gray-700"
        >
          {day}
        </div>
      </div>

      <div class="grid grid-cols-7 gap-px bg-gray-200">
        <div
          :for={day <- @calendar_days}
          class={[
            "bg-white min-h-[100px] p-2",
            day.current_month? || "bg-gray-50",
            day.today? && "bg-blue-50"
          ]}
        >
          <div class="text-sm text-gray-900 mb-1">
            {day.date.day}
          </div>
          <div class="space-y-1">
            <div
              :for={interview <- day.interviews}
              phx-click="show_interview_details"
              phx-value-id={interview.id}
              phx-target={@myself || ""}
              class="text-xs p-1 bg-purple-100 text-purple-800 rounded cursor-pointer hover:bg-purple-200 truncate"
              title={interview_title(interview)}
            >
              {format_interview_time(interview)}
              <span class="font-medium">{interview_title(interview)}</span>
            </div>
          </div>
          <div
            :if={length(day.interviews) > 2}
            class="text-xs text-gray-500 mt-1"
          >
            +{length(day.interviews) - 2} more
          </div>
        </div>
      </div>

      <div class="mt-6 space-y-3">
        <div :if={@selected_date} class="border-t pt-4">
          <h3 class="font-semibold mb-3">
            {format_date(@selected_date)} - {length(@selected_interviews)} {ngettext(
              "interview",
              "interviews",
              length(@selected_interviews)
            )}
          </h3>
          <div class="space-y-2">
            <div
              :for={interview <- @selected_interviews}
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
            >
              <div>
                <div class="flex items-center gap-2">
                  <.icon name="hero-clock" class="w-4 h-4 text-gray-500" />
                  <span class="text-sm">
                    {format_interview_time_range(interview)}
                  </span>
                </div>
                <p class="font-medium mt-1">
                  {dgettext("jobs", "Meeting with candidate")} {interview.job_application.user.full_name}
                </p>
                <p class="text-sm text-gray-600">
                  {interview.job_application.job_posting.title}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  phx-click="edit_interview"
                  phx-value-id={interview.id}
                  phx-target={@myself || ""}
                  class="p-2 text-gray-600 hover:bg-gray-200 rounded"
                >
                  <.icon name="hero-pencil" class="w-4 h-4" />
                </button>
                <a
                  href={interview.meeting_link}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="p-2 text-blue-600 hover:bg-blue-50 rounded"
                >
                  <.icon name="hero-video-camera" class="w-4 h-4" />
                </a>
              </div>
            </div>
          </div>
        </div>

        <div :if={@upcoming_today.interviews != []} class="border-t pt-4">
          <h3 class="font-semibold mb-3 text-green-600">
            {dgettext("jobs", "Today's Interviews")}
          </h3>
          <div :for={interview <- @upcoming_today.interviews} class="p-3 bg-green-50 rounded-lg mb-2">
            <div class="flex items-center gap-2 text-green-800">
              <.icon name="hero-clock" class="w-4 h-4" />
              <span class="font-medium">
                {format_interview_time(interview)} - {interview_title(interview)}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    current_date = assigns[:current_date] || Date.utc_today()
    interviews = assigns[:interviews] || []

    {:ok,
     socket
     |> assign(:current_date, current_date)
     |> assign(:interviews, interviews)
     |> assign(:current_scope, assigns[:current_scope])
     |> assign(:calendar_days, build_calendar_days(current_date, interviews))
     |> assign(:selected_date, nil)
     |> assign(:selected_interviews, [])
     |> assign(:upcoming_today, get_today_interviews(interviews))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("prev_month", _params, socket) do
    new_date =
      socket.assigns.current_date
      |> Date.beginning_of_month()
      |> Date.add(-1)
      |> Date.beginning_of_month()

    send(self(), {:calendar_navigate, new_date})

    {:noreply,
     socket
     |> assign(:current_date, new_date)
     |> assign(:calendar_days, build_calendar_days(new_date, socket.assigns.interviews))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next_month", _params, socket) do
    new_date =
      socket.assigns.current_date
      |> Date.end_of_month()
      |> Date.add(1)
      |> Date.beginning_of_month()

    send(self(), {:calendar_navigate, new_date})

    {:noreply,
     socket
     |> assign(:current_date, new_date)
     |> assign(:calendar_days, build_calendar_days(new_date, socket.assigns.interviews))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("show_interview_details", %{"id" => id}, socket) do
    interview = Enum.find(socket.assigns.interviews, &(&1.id == id))

    if interview do
      send(self(), {:show_interview_details, interview})
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_month_selector", _params, socket) do
    # Placeholder for future month selector functionality
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("edit_interview", %{"id" => id}, socket) do
    send(self(), {:edit_interview, id})
    {:noreply, socket}
  end

  defp build_calendar_days(current_date, interviews) do
    first_day = Date.beginning_of_month(current_date)

    # Get the first Sunday before or on the first day of month
    first_calendar_day =
      case Date.day_of_week(first_day) do
        # Sunday
        7 -> first_day
        n -> Date.add(first_day, -n)
      end

    # Generate 6 weeks (42 days) for consistent calendar grid
    Enum.map(0..41, fn offset ->
      date = Date.add(first_calendar_day, offset)
      day_interviews = filter_interviews_for_date(interviews, date)

      %{
        date: date,
        current_month?: date.month == current_date.month,
        today?: date == Date.utc_today(),
        interviews: day_interviews
      }
    end)
  end

  defp filter_interviews_for_date(interviews, date) do
    Enum.filter(interviews, fn interview ->
      DateTime.to_date(interview.scheduled_at) == date
    end)
  end

  defp get_today_interviews(interviews) do
    today = Date.utc_today()

    %{
      date: today,
      interviews: filter_interviews_for_date(interviews, today)
    }
  end

  defp format_month_year(date) do
    Calendar.strftime(date, "%B %Y")
  end

  defp format_date(date) do
    Calendar.strftime(date, "%A, %B %d")
  end

  defp format_interview_time(interview) do
    Calendar.strftime(interview.scheduled_at, "%H:%M")
  end

  defp format_interview_time_range(interview) do
    start_time = Calendar.strftime(interview.scheduled_at, "%H:%M")
    end_time = Calendar.strftime(interview.end_time, "%H:%M")
    "#{start_time} - #{end_time}"
  end

  defp interview_title(interview) do
    user = interview.job_application.user
    full_name = "#{user.first_name} #{user.last_name}"
    "#{full_name} - #{interview.job_application.job_posting.title}"
  end
end
