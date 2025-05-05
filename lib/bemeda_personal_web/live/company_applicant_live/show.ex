defmodule BemedaPersonalWeb.CompanyApplicantLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Resumes
  alias BemedaPersonalWeb.Endpoint
  alias BemedaPersonalWeb.JobsComponents
  alias BemedaPersonalWeb.Live.Hooks.RatingHooks
  alias Phoenix.Socket.Broadcast

  on_mount {RatingHooks, :default}

  @impl Phoenix.LiveView
  def handle_params(%{"company_id" => company_id, "id" => applicant_id}, _url, socket) do
    company = Companies.get_company!(company_id)
    application = Jobs.get_job_application!(applicant_id)
    job_posting = application.job_posting
    resume = Resumes.get_user_resume(application.user)
    full_name = "#{application.user.first_name} #{application.user.last_name}"

    if connected?(socket) do
      Endpoint.subscribe("job_application_assets_#{application.id}")
      Endpoint.subscribe("rating:User:#{application.user.id}")
    end

    tags_form_fields = %{"tags" => ""}

    {:noreply,
     socket
     |> assign(:application, application)
     |> assign(:company, company)
     |> assign(:job_posting, job_posting)
     |> assign(:page_title, "Applicant: #{full_name}")
     |> assign(:rating_modal_open, false)
     |> assign(:resume, resume)
     |> assign(:tags_form, to_form(tags_form_fields))}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "open-rating-modal",
        %{"entity_id" => _entity_id, "entity_type" => _entity_type},
        socket
      ) do
    current_user = socket.assigns.current_user
    company = socket.assigns.company

    if company_admin?(current_user, company) do
      {:noreply, assign(socket, :rating_modal_open, true)}
    else
      {:noreply, put_flash(socket, :error, "You need to be a company admin to rate applicants.")}
    end
  end

  def handle_event("close-rating-modal", _params, socket) do
    {:noreply, assign(socket, :rating_modal_open, false)}
  end

  def handle_event("update_tags", %{"tags" => tags}, socket) do
    application = socket.assigns.application

    case Jobs.update_job_application_tags(application, tags) do
      {:ok, updated_application} ->
        {:noreply, assign(socket, :application, updated_application)}

      _error ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(%{job_application: job_application}, socket) do
    {:noreply, assign(socket, :application, job_application)}
  end

  def handle_info(%Broadcast{event: "media_asset_updated", payload: payload}, socket) do
    {:noreply, assign(socket, :application, payload.job_application)}
  end

  @spec company_admin?(
          BemedaPersonal.Accounts.User.t() | nil,
          BemedaPersonal.Companies.Company.t() | nil
        ) :: boolean()
  defp company_admin?(user, company) do
    user && company && company.admin_user_id == user.id
  end
end
