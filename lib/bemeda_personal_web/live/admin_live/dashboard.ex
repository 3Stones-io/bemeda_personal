defmodule BemedaPersonalWeb.AdminLive.Dashboard do
  @moduledoc """
  Admin dashboard displaying comprehensive application statistics.
  """

  use BemedaPersonalWeb, :live_view

  import Ecto.Query

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Components.Shared.LanguageSwitcher

  @type socket :: Phoenix.LiveView.Socket.t()

  # 60 seconds
  @refresh_interval 60_000

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      schedule_refresh()
    end

    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:current_time, DateTime.utc_now())
     |> load_statistics()}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh_stats, socket) do
    schedule_refresh()

    {:noreply,
     socket
     |> assign(:current_time, DateTime.utc_now())
     |> load_statistics()}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} socket={@socket}>
      <div class="container mx-auto px-4 py-8 max-w-7xl">
        <!-- Header -->
        <div class="mb-8">
          <div class="flex justify-between items-center">
            <div>
              <h1 class="text-3xl font-bold text-gray-900">{gettext("Admin Dashboard")}</h1>
              <p class="mt-2 text-gray-600">{gettext("Systemübersicht und Statistiken")}</p>
            </div>
            <div class="flex items-center gap-4">
              <div class="text-sm text-gray-500">
                <p>{gettext("Letzte Aktualisierung:") <> " "} {format_datetime(@current_time)}</p>
                <p class="text-xs">{gettext("Automatische Aktualisierung alle 60 Sekunden")}</p>
              </div>
              <LanguageSwitcher.language_switcher id="admin-language-switcher" locale={@locale} />
            </div>
          </div>
        </div>
        
    <!-- Chart Data Element -->
        <div id="chart-data" class="hidden" aria-hidden="true">
          {Jason.encode!(@chart_data)}
        </div>
        
    <!-- Statistics Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">{gettext("Benutzer gesamt")}</p>
                <p class="text-3xl font-bold text-gray-900">{@total_users}</p>
                <div class="mt-2 space-y-1">
                  <p class="text-xs text-gray-500">
                    {gettext("Arbeitgeber") <> ": "} {@total_employers}
                  </p>
                  <p class="text-xs text-gray-500">
                    {gettext("Jobsuchende") <> ": "} {@total_job_seekers}
                  </p>
                </div>
              </div>
              <div class="text-purple-600">
                <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">{gettext("Unternehmen")}</p>
                <p class="text-3xl font-bold text-gray-900">{@total_companies}</p>
              </div>
              <div class="text-blue-600">
                <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">{gettext("Stellenanzeigen")}</p>
                <p class="text-3xl font-bold text-gray-900">{@total_job_postings}</p>
              </div>
              <div class="text-green-600">
                <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M21 13.255A8.925 8.925 0 0112.24 21a8.925 8.925 0 01-8.15-12.651A2.992 2.992 0 012 5.25C2 3.845 3.12 2.75 4.5 2.75h15c1.38 0 2.5 1.095 2.5 2.5a2.992 2.992 0 01-2.09 3.105z"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-600">{gettext("Bewerbungen")}</p>
                <p class="text-3xl font-bold text-gray-900">{@total_applications}</p>
              </div>
              <div class="text-orange-600">
                <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  >
                  </path>
                </svg>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Application Status Breakdown -->
        <div class="bg-white rounded-lg shadow p-6 mb-8">
          <h2 class="text-xl font-semibold mb-4">{gettext("Bewerbungsstatus-Übersicht")}</h2>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <%= for {state, count} <- @application_state_counts do %>
              <div class="text-center p-3 bg-gray-50 rounded">
                <p class="text-2xl font-bold text-gray-900">{count}</p>
                <p class="text-sm text-gray-600">{humanize_state(state)}</p>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Charts Container (placeholder for Step 3) -->
        <div id="charts-container" class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold mb-4">
              {gettext("Tägliche Registrierungen (30 Tage)")}
            </h2>
            <div class="h-64 flex items-center justify-center text-gray-400">
              <canvas
                id="registrations-chart"
                phx-hook="AdminChart"
                phx-update="ignore"
                data-chart-type="registrations"
                data-label-registrations={gettext("Registrierungen")}
                data-label-applications={gettext("Bewerbungen")}
              >
              </canvas>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold mb-4">{gettext("Tägliche Bewerbungen (30 Tage)")}</h2>
            <div class="h-64 flex items-center justify-center text-gray-400">
              <canvas
                id="applications-chart"
                phx-hook="AdminChart"
                phx-update="ignore"
                data-chart-type="applications"
                data-label-registrations={gettext("Registrierungen")}
                data-label-applications={gettext("Bewerbungen")}
              >
              </canvas>
            </div>
          </div>
        </div>
        
    <!-- Recent Activity Tables -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Recent Users -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold mb-4">{gettext("Neue Benutzer")}</h3>
            <div class="space-y-3">
              <%= for user <- @recent_users do %>
                <div class="flex items-center justify-between py-2 border-b last:border-0">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {user.email}
                    </p>
                    <p class="text-xs text-gray-500">
                      {if user.user_type == :employer,
                        do: gettext("Arbeitgeber"),
                        else: gettext("Jobsuchender")}
                    </p>
                  </div>
                  <div class="text-xs text-gray-400 ml-2">
                    {format_date(user.inserted_at)}
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Recent Job Postings -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold mb-4">{gettext("Neue Stellenanzeigen")}</h3>
            <div class="space-y-3">
              <%= for job <- @recent_job_postings do %>
                <div class="flex items-center justify-between py-2 border-b last:border-0">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {job.title}
                    </p>
                    <p class="text-xs text-gray-500 truncate">
                      {job.company.name}
                    </p>
                  </div>
                  <div class="text-xs text-gray-400 ml-2">
                    {format_date(job.inserted_at)}
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Recent Applications -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold mb-4">{gettext("Neue Bewerbungen")}</h3>
            <div class="space-y-3">
              <%= for application <- @recent_applications do %>
                <div class="flex items-center justify-between py-2 border-b last:border-0">
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {application.job_posting.title}
                    </p>
                    <p class="text-xs text-gray-500 truncate">
                      {application.user.email}
                    </p>
                  </div>
                  <div class="text-xs text-gray-400 ml-2">
                    {format_date(application.inserted_at)}
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @spec load_statistics(socket()) :: socket()
  defp load_statistics(socket) do
    user_stats = get_user_statistics()
    company_stats = get_company_statistics()
    recent_activity = get_recent_activity()
    chart_data = get_chart_data()

    socket
    |> assign(:total_users, user_stats.total_users)
    |> assign(:total_employers, user_stats.total_employers)
    |> assign(:total_job_seekers, user_stats.total_job_seekers)
    |> assign(:total_companies, company_stats.total_companies)
    |> assign(:total_job_postings, company_stats.total_job_postings)
    |> assign(:total_applications, company_stats.total_applications)
    |> assign(:application_state_counts, company_stats.application_state_counts)
    |> assign(:recent_users, recent_activity.users)
    |> assign(:recent_job_postings, recent_activity.job_postings)
    |> assign(:recent_applications, recent_activity.applications)
    |> assign(:chart_data, chart_data)
  end

  @spec get_user_statistics() :: map()
  defp get_user_statistics do
    total_users = Repo.aggregate(User, :count)

    query_employers = from(u in User, where: u.user_type == :employer)
    total_employers = Repo.aggregate(query_employers, :count)

    query_job_seekers = from(u in User, where: u.user_type == :job_seeker)
    total_job_seekers = Repo.aggregate(query_job_seekers, :count)

    %{
      total_users: total_users,
      total_employers: total_employers,
      total_job_seekers: total_job_seekers
    }
  end

  @spec get_company_statistics() :: map()
  defp get_company_statistics do
    total_companies = Repo.aggregate(Company, :count)
    total_job_postings = Repo.aggregate(JobPosting, :count)
    total_applications = Repo.aggregate(JobApplication, :count)

    application_state_counts =
      from(a in JobApplication,
        group_by: a.state,
        select: {a.state, count(a.id)}
      )
      |> Repo.all()
      |> Enum.sort_by(fn {state, _count} -> state end)

    %{
      total_companies: total_companies,
      total_job_postings: total_job_postings,
      total_applications: total_applications,
      application_state_counts: application_state_counts
    }
  end

  @spec get_recent_activity() :: map()
  defp get_recent_activity do
    query_recent_users =
      from(u in User,
        order_by: [desc: u.inserted_at],
        limit: 10
      )

    recent_users = Repo.all(query_recent_users)

    query_recent_jobs =
      from(j in JobPosting,
        order_by: [desc: j.inserted_at],
        limit: 10,
        preload: [:company]
      )

    recent_job_postings = Repo.all(query_recent_jobs)

    query_recent_apps =
      from(a in JobApplication,
        order_by: [desc: a.inserted_at],
        limit: 10,
        preload: [:user, :job_posting]
      )

    recent_applications = Repo.all(query_recent_apps)

    %{
      users: recent_users,
      job_postings: recent_job_postings,
      applications: recent_applications
    }
  end

  @spec get_chart_data() :: map()
  defp get_chart_data do
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    daily_registrations =
      from(u in User,
        where: u.inserted_at >= ^thirty_days_ago,
        group_by: fragment("DATE(?)", u.inserted_at),
        select: {fragment("DATE(?)", u.inserted_at), count(u.id)}
      )
      |> Repo.all()
      |> Map.new()

    daily_applications =
      from(a in JobApplication,
        where: a.inserted_at >= ^thirty_days_ago,
        group_by: fragment("DATE(?)", a.inserted_at),
        select: {fragment("DATE(?)", a.inserted_at), count(a.id)}
      )
      |> Repo.all()
      |> Map.new()

    # Generate complete date range
    dates =
      for i <- 29..0//-1 do
        DateTime.utc_now()
        |> DateTime.add(-i, :day)
        |> DateTime.to_date()
      end

    %{
      dates: Enum.map(dates, &Date.to_iso8601/1),
      registrations: Enum.map(dates, fn date -> Map.get(daily_registrations, date, 0) end),
      applications: Enum.map(dates, fn date -> Map.get(daily_applications, date, 0) end)
    }
  end

  @spec schedule_refresh() :: reference()
  defp schedule_refresh do
    Process.send_after(self(), :refresh_stats, @refresh_interval)
  end

  @spec format_datetime(DateTime.t()) :: String.t()
  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%d.%m.%Y %H:%M:%S UTC")
  end

  @spec format_date(DateTime.t()) :: String.t()
  defp format_date(datetime) do
    Calendar.strftime(datetime, "%d.%m.%Y")
  end

  @spec humanize_state(String.t()) :: String.t()
  defp humanize_state("applied"), do: "Beworben"
  defp humanize_state("offer_extended"), do: "Angebot gemacht"
  defp humanize_state("offer_accepted"), do: "Angebot angenommen"
  defp humanize_state("withdrawn"), do: "Zurückgezogen"
  defp humanize_state(state), do: to_string(state)
end
