defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.Repo
  alias BemedaPersonal.Workers.ProcessTemplate
  alias BemedaPersonalWeb.Components.Company.FormComponent
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias Ecto.Multi
  alias Phoenix.Socket.Broadcast

  @allowed_file_types [
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ]

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    company = Companies.get_company_by_user(current_user)

    if connected?(socket) do
      Endpoint.subscribe("company:#{current_user.id}")

      if company do
        Endpoint.subscribe("company:#{company.id}:templates")
        Endpoint.subscribe("job_application:company:#{company.id}")
        Endpoint.subscribe("job_posting:company:#{company.id}")
        Endpoint.subscribe("rating:Company:#{company.id}")
      end
    end

    template =
      if company do
        CompanyTemplates.get_current_template(company.id)
      end

    current_scope = create_scope_for_user(current_user)

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream_configure(:recent_applicants, dom_id: &"applicant-#{&1.id}")
     |> assign(:company, company)
     |> assign(:current_scope, current_scope)
     |> assign(:template, template)
     |> assign(:template_data, %{})
     |> assign(:show_template_modal, false)
     |> assign(:show_variables_modal, false)
     |> assign(:show_create_company_section, is_nil(company))
     |> assign(:active_tab, "overview")
     |> assign(:calendar_date, Date.utc_today())
     |> assign_company_data(company)
     |> assign_schedule_data(company, current_user)}
  end

  defp assign_company_data(socket, nil) do
    socket
    |> assign(:job_count, 0)
    |> stream(:job_postings, [])
    |> stream(:recent_applicants, [])
  end

  defp assign_company_data(socket, company) do
    socket
    |> assign_job_count(company)
    |> assign_job_postings(company)
    |> assign_recent_applicants(company)
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{company: nil}} = socket, :new, _params) do
    socket
    |> assign(:company, %Companies.Company{})
    |> assign(:page_title, dgettext("companies", "Create Company Profile"))
  end

  defp apply_action(%{assigns: %{company: _company}} = socket, :new, _params) do
    socket
    |> put_flash(:info, dgettext("companies", "You already have a company profile."))
    |> push_patch(to: ~p"/company")
  end

  defp apply_action(socket, :edit, %{"company_id" => company_id}) do
    scope = create_scope_for_user(socket.assigns.current_user)
    company = Companies.get_company!(scope, company_id)

    socket
    |> assign(:company, company)
    |> assign(:page_title, dgettext("companies", "Edit Company Profile"))
  end

  defp apply_action(socket, :edit, _params) do
    # Reload company to ensure we have the latest data
    current_user = socket.assigns.current_user
    updated_company = Companies.get_company_by_user(current_user)

    socket
    |> assign(:company, updated_company)
    |> assign(:page_title, dgettext("companies", "Edit Company Profile"))
  end

  defp apply_action(%{assigns: %{company: nil}} = socket, :index, _params) do
    assign(socket, :page_title, dgettext("companies", "Create Your Company Profile"))
  end

  defp apply_action(%{assigns: %{company: _company}} = socket, :index, _params) do
    # Reload company data to ensure we have the latest updates
    current_user = socket.assigns.current_user
    updated_company = Companies.get_company_by_user(current_user)

    socket
    |> assign(:company, updated_company)
    |> assign(:page_title, dgettext("companies", "Company Dashboard"))
  end

  @impl Phoenix.LiveView
  def handle_event("upload_file", params, socket) do
    case validate_file_type(params) do
      {:ok, params} ->
        {:reply, response, updated_socket} =
          BemedaPersonalWeb.SharedHelpers.create_file_upload(socket, params)

        updated_socket_with_template_data =
          assign(updated_socket, :template_data, updated_socket.assigns.media_data)

        {:reply, response, updated_socket_with_template_data}

      {:error, error} ->
        {:reply, %{error: error}, socket}
    end
  end

  def handle_event("upload_completed", _params, socket) do
    case process_template_upload(socket) do
      {:ok, template} -> handle_upload_success(socket, template)
      {:error, _reason} -> handle_upload_error(socket)
    end
  end

  def handle_event("delete_file", _params, socket) do
    {:noreply, assign(socket, :template_data, %{})}
  end

  def handle_event("upload_cancelled", _params, socket) do
    {:noreply, assign(socket, :template_data, %{})}
  end

  def handle_event("show_variables", _params, socket) do
    {:noreply, assign(socket, :show_variables_modal, true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_template_modal, false)
     |> assign(:show_variables_modal, false)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("archive_template", _params, socket) do
    case socket.assigns.template do
      nil ->
        {:noreply, socket}

      template ->
        case CompanyTemplates.archive_template(template) do
          {:ok, _template} ->
            {:noreply,
             socket
             |> assign(:template, nil)
             |> put_flash(:info, dgettext("companies", "Template archived successfully"))}

          {:error, _changeset} ->
            {:noreply,
             put_flash(socket, :error, dgettext("companies", "Failed to archive template"))}
        end
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "company_created", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:company, payload.company)
     |> assign(:show_create_company_section, false)
     |> assign_company_data(payload.company)
     |> put_flash(:info, dgettext("companies", "Company profile created successfully!"))}
  end

  def handle_info(%Broadcast{event: "company_updated", payload: payload}, socket) do
    updated_company = Repo.preload(payload.company, :media_asset, force: true)

    {:noreply,
     socket
     |> assign(:company, updated_company)
     |> assign_job_postings(updated_company)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "job_posting_created",
             "job_posting_updated",
             "company_job_posting_created"
           ] do
    job_count =
      socket.assigns.current_user
      |> create_scope_for_user()
      |> JobPostings.company_jobs_count(socket.assigns.company.id)

    {:noreply,
     socket
     |> assign(:job_count, job_count)
     |> stream_insert(:job_postings, payload.job_posting)}
  end

  def handle_info(%Broadcast{event: "job_posting_deleted", payload: payload}, socket) do
    {:noreply, stream_delete(socket, :job_postings, payload.job_posting)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "company_job_application_created",
             "company_job_application_status_updated",
             "company_job_application_updated",
             "job_application_created",
             "job_application_updated"
           ] do
    {:noreply, stream_insert(socket, :recent_applicants, payload.job_application, at: 0)}
  end

  def handle_info(%Broadcast{event: "template_status_updated", payload: template}, socket) do
    template_with_media = Repo.preload(template, :media_asset)
    {:noreply, assign(socket, :template, template_with_media)}
  end

  def handle_info({:calendar_navigate, new_date}, socket) do
    scope = create_scope_for_user(socket.assigns.current_user)
    interviews = load_interviews_for_month(scope, new_date)

    {:noreply,
     socket
     |> assign(:calendar_date, new_date)
     |> assign(:interviews, interviews)}
  end

  def handle_info({:edit_interview, interview_id}, socket) do
    # For now, just show a flash message - in a full implementation,
    # this would redirect to an edit modal or page
    {:noreply,
     put_flash(
       socket,
       :info,
       dgettext("jobs", "Edit functionality coming soon for interview %{id}", id: interview_id)
     )}
  end

  def handle_info({:cancel_interview, interview_id}, socket) do
    scope = create_scope_for_user(socket.assigns.current_user)
    interview = BemedaPersonal.Scheduling.get_interview!(scope, interview_id)

    case BemedaPersonal.Scheduling.cancel_interview(
           scope,
           interview,
           dgettext("jobs", "Cancelled by employer")
         ) do
      {:ok, _cancelled_interview} ->
        # Reload interviews to reflect the cancellation
        interviews = load_interviews_for_month(scope, socket.assigns.calendar_date)

        {:noreply,
         socket
         |> assign(:interviews, interviews)
         |> put_flash(:info, dgettext("jobs", "Interview cancelled successfully"))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, dgettext("jobs", "Could not cancel interview"))}
    end
  end

  def handle_info({:show_interview_details, interview}, socket) do
    # For now, just show a flash message - in a full implementation,
    # this would show interview details modal
    {:noreply,
     put_flash(
       socket,
       :info,
       dgettext("jobs", "Interview details: %{title}", title: interview.title || "Interview")
     )}
  end

  def handle_info({:interview_updated, _interview}, socket) do
    # Reload interviews when one is updated
    scope = create_scope_for_user(socket.assigns.current_user)
    interviews = load_interviews_for_month(scope, socket.assigns.calendar_date)

    {:noreply, assign(socket, :interviews, interviews)}
  end

  def handle_info({:interview_cancelled, _interview}, socket) do
    # Reload interviews when one is cancelled
    scope = create_scope_for_user(socket.assigns.current_user)
    interviews = load_interviews_for_month(scope, socket.assigns.calendar_date)

    {:noreply, assign(socket, :interviews, interviews)}
  end

  defp assign_job_postings(socket, nil), do: stream(socket, :job_postings, [])

  defp assign_job_postings(socket, _company) do
    scope = create_scope_for_user(socket.assigns.current_user)

    job_postings =
      scope
      |> JobPostings.list_job_postings()
      |> Enum.take(5)

    stream(socket, :job_postings, job_postings)
  end

  defp assign_recent_applicants(socket, nil), do: stream(socket, :recent_applicants, [])

  defp assign_recent_applicants(socket, company) do
    recent_applicants =
      BemedaPersonal.JobApplications.list_job_applications(%{company_id: company.id}, 10)

    stream(socket, :recent_applicants, recent_applicants)
  end

  defp assign_job_count(socket, nil), do: assign(socket, :job_count, 0)

  defp assign_job_count(socket, company) do
    socket.assigns.current_user
    |> create_scope_for_user()
    |> JobPostings.company_jobs_count(company.id)
    |> then(&assign(socket, :job_count, &1))
  end

  defp validate_file_type(params) do
    docx? =
      params["filename"]
      |> String.downcase()
      |> String.ends_with?(".docx")

    cond do
      !docx? ->
        {:error, dgettext("companies", "Only DOCX files are allowed")}

      params["type"] not in @allowed_file_types ->
        {:error, dgettext("companies", "Invalid file type. Please upload a DOCX file")}

      true ->
        {:ok, params}
    end
  end

  defp build_media_attrs(template_data) do
    %{
      file_name: template_data.file_name,
      upload_id: Map.get(template_data, :upload_id),
      status: :uploaded,
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    }
  end

  defp process_template_upload(socket) do
    company = socket.assigns.company
    template_data = socket.assigns.template_data

    with %{file_name: _file_name} <- template_data,
         template_attrs = build_template_attrs(template_data),
         media_attrs = build_media_attrs(template_data),
         multi = build_upload_transaction(company, template_attrs, media_attrs),
         {:ok, %{template: template}} <- Repo.transaction(multi) do
      {:ok, template}
    else
      _reason -> {:error, :upload_failed}
    end
  end

  defp build_template_attrs(template_data) do
    %{
      name: template_data.file_name,
      status: :processing
    }
  end

  defp build_upload_transaction(company, template_attrs, media_attrs) do
    Multi.new()
    |> Multi.run(:template, fn _repo, _changes ->
      CompanyTemplates.replace_active_template(company, template_attrs)
    end)
    |> Multi.run(:media_asset, fn _repo, %{template: template} ->
      BemedaPersonal.Media.create_media_asset(template, media_attrs)
    end)
  end

  defp handle_upload_success(socket, template) do
    template_with_media = Repo.preload(template, :media_asset)

    %{"template_id" => template.id}
    |> ProcessTemplate.new()
    |> Oban.insert()

    {:noreply,
     socket
     |> assign(:template, template_with_media)
     |> assign(:template_data, %{})
     |> put_flash(
       :info,
       dgettext("companies", "Template uploaded and processing started")
     )}
  end

  defp handle_upload_error(socket) do
    {:noreply,
     socket
     |> assign(:template_data, %{})
     |> put_flash(:error, dgettext("companies", "Failed to upload template"))}
  end

  defp create_scope_for_user(user) do
    scope = Scope.for_user(user)

    if user.user_type == :employer do
      case Companies.get_company_by_user(user) do
        nil -> scope
        company -> Scope.put_company(scope, company)
      end
    else
      scope
    end
  end

  defp assign_schedule_data(socket, nil, _user), do: assign(socket, :interviews, [])

  defp assign_schedule_data(socket, _company, user) do
    scope = create_scope_for_user(user)
    interviews = load_interviews_for_month(scope, Date.utc_today())

    assign(socket, :interviews, interviews)
  end

  defp load_interviews_for_month(scope, date) do
    start_date = Date.beginning_of_month(date)
    # Include first week of next month
    end_date =
      date
      |> Date.end_of_month()
      |> Date.add(7)

    BemedaPersonal.Scheduling.list_interviews(scope, %{
      from_date: DateTime.new!(start_date, ~T[00:00:00]),
      to_date: DateTime.new!(end_date, ~T[23:59:59])
    })
  end
end
