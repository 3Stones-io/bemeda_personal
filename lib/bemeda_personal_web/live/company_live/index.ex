defmodule BemedaPersonalWeb.CompanyLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.CompanyTemplates
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.Media
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias BemedaPersonalWeb.RatingComponent
  alias BemedaPersonalWeb.SharedComponents
  alias BemedaPersonalWeb.SharedHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.Socket.Broadcast

  @allowed_file_types [
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ]

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    company = Companies.get_company_by_user(current_user)

    if connected?(socket) && company do
      Endpoint.subscribe("company:#{current_user.id}")
      Endpoint.subscribe("job_application:company:#{company.id}")
      Endpoint.subscribe("job_posting:company:#{company.id}")
      Endpoint.subscribe("rating:Company:#{company.id}")
    end

    template =
      if company do
        CompanyTemplates.get_active_template(company.id)
      end

    {:ok,
     socket
     |> stream_configure(:job_postings, dom_id: &"job-#{&1.id}")
     |> stream_configure(:recent_applicants, dom_id: &"applicant-#{&1.id}")
     |> assign(:company, company)
     |> assign(:template, template)
     |> assign(:template_data, %{})
     |> assign_job_count(company)
     |> assign_job_postings(company)
     |> assign_recent_applicants(company)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"company_id" => company_id}) do
    company = Companies.get_company!(company_id)

    socket
    |> assign(:company, company)
    |> assign(:page_title, dgettext("companies", "Edit Company Profile"))
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket, :page_title, dgettext("companies", "Edit Company Profile"))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:company, %Company{})
    |> assign(:page_title, dgettext("companies", "Create Company Profile"))
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, dgettext("companies", "Company Dashboard"))
  end

  @impl Phoenix.LiveView
  def handle_event("upload_file", params, socket) do
    case validate_file_type(params) do
      {:ok, params} ->
        {:reply, response, updated_socket} = SharedHelpers.create_file_upload(socket, params)

        updated_socket_with_template_data =
          assign(updated_socket, :template_data, updated_socket.assigns.media_data)

        {:reply, response, updated_socket_with_template_data}

      {:error, error} ->
        {:reply, %{error: error}, socket}
    end
  end

  def handle_event("upload_completed", _params, socket) do
    template_data = socket.assigns.template_data

    template_attrs = %{
      name: template_data.file_name
    }

    media_attrs = %{
      file_name: template_data.file_name,
      upload_id: Map.get(template_data, :upload_id),
      status: :uploaded,
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    }

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:template, fn _repo, _changes ->
        CompanyTemplates.replace_active_template(socket.assigns.company, template_attrs)
      end)
      |> Ecto.Multi.run(:media_asset, fn _repo, %{template: template} ->
        Media.create_media_asset(template, media_attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{template: template}} ->
        template_with_media = Repo.preload(template, :media_asset)

        {:noreply,
         socket
         |> assign(:template, template_with_media)
         |> assign(:template_data, %{})
         |> put_flash(:info, dgettext("companies", "Template uploaded successfully"))}

      {:error, _operation, _changeset, _changes} ->
        {:noreply,
         socket
         |> assign(:template_data, %{})
         |> put_flash(:error, dgettext("companies", "Failed to upload template"))}
    end
  end

  def handle_event("delete_file", _params, socket) do
    {:noreply, assign(socket, :template_data, %{})}
  end

  def handle_event("delete_template", _params, socket) do
    case CompanyTemplates.delete_template(socket.assigns.template) do
      {:ok, _deleted_template} ->
        {:noreply,
         socket
         |> assign(:template, nil)
         |> put_flash(:info, dgettext("companies", "Template deleted successfully"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("companies", "Failed to delete template"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "company_updated", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:company, payload.company)
     |> assign_job_postings(payload.company)}
  end

  def handle_info(%Broadcast{event: event, payload: payload}, socket)
      when event in [
             "job_posting_created",
             "job_posting_updated"
           ] do
    {:noreply,
     socket
     |> assign(:job_count, JobPostings.company_jobs_count(socket.assigns.company.id))
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

  defp assign_job_postings(socket, nil), do: stream(socket, :job_postings, [])

  defp assign_job_postings(socket, company) do
    job_postings = JobPostings.list_job_postings(%{company_id: company.id}, 5)

    stream(socket, :job_postings, job_postings)
  end

  defp assign_recent_applicants(socket, nil), do: stream(socket, :recent_applicants, [])

  defp assign_recent_applicants(socket, company) do
    recent_applicants = JobApplications.list_job_applications(%{company_id: company.id}, 10)

    stream(socket, :recent_applicants, recent_applicants)
  end

  defp assign_job_count(socket, nil), do: assign(socket, :job_count, 0)

  defp assign_job_count(socket, company),
    do: assign(socket, :job_count, JobPostings.company_jobs_count(company.id))

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
end
