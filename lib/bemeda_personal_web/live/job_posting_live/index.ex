defmodule BemedaPersonalWeb.JobPostingLive.Index do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user
    company_id = params["company_id"]

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:user_company, Companies.get_company_by_user(current_user))
      |> assign(:company_id, company_id)

    job_postings =
      if company_id do
        Jobs.list_company_job_postings(company_id)
      else
        Jobs.list_job_postings()
      end

    {:ok, stream(socket, :job_postings, job_postings)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    job_posting = Jobs.get_job_posting!(id)

    if can_manage_job?(socket.assigns.current_user, job_posting) do
      socket
      |> assign(:page_title, "Edit Job Posting")
      |> assign(:job_posting, job_posting)
    else
      socket
      |> put_flash(:error, "You are not authorized to edit this job posting")
      |> redirect(to: ~p"/job_postings")
    end
  end

  defp apply_action(socket, :new, params) do
    company_id = params["company_id"]
    user_company = socket.assigns.user_company

    cond do
      is_nil(user_company) ->
        socket
        |> put_flash(:error, "You need to create a company first")
        |> redirect(to: ~p"/companies")

      company_id && company_id != user_company.id ->
        socket
        |> put_flash(:error, "You can only create job postings for your own company")
        |> redirect(to: ~p"/job_postings")

      true ->
        socket
        |> assign(:page_title, "New Job Posting")
        |> assign(:job_posting, %JobPosting{})
    end
  end

  defp apply_action(socket, :index, params) do
    company_id = params["company_id"]

    title =
      if company_id do
        "Company Job Postings"
      else
        "All Job Postings"
      end

    socket
    |> assign(:page_title, title)
    |> assign(:job_posting, nil)
  end

  @impl Phoenix.LiveView
  def handle_info({BemedaPersonalWeb.JobPostingLive.FormComponent, {:saved, job_posting}}, socket) do
    {:noreply, stream_insert(socket, :job_postings, job_posting)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    job_posting = Jobs.get_job_posting!(id)
    current_user = socket.assigns.current_user

    if can_manage_job?(current_user, job_posting) do
      case Jobs.delete_job_posting(current_user, job_posting) do
        {:ok, _result} ->
          {:noreply,
           socket
           |> stream_delete(:job_postings, job_posting)
           |> put_flash(:info, "Job posting deleted successfully")}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are not authorized to delete this job posting")}

        {:error, :company_not_found} ->
          {:noreply,
           socket
           |> put_flash(:error, "You need to create a company first")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to delete this job posting")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("publish", %{"id" => id}, socket) do
    job_posting = Jobs.get_job_posting!(id)
    current_user = socket.assigns.current_user

    if can_manage_job?(current_user, job_posting) do
      case Jobs.publish_job_posting(current_user, job_posting) do
        {:ok, updated_job_posting} ->
          {:noreply,
           socket
           |> stream_insert(:job_postings, updated_job_posting)
           |> put_flash(:info, "Job posting published successfully")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to publish job posting")}

        {:error, :unauthorized} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are not authorized to publish this job posting")}

        {:error, :company_not_found} ->
          {:noreply,
           socket
           |> put_flash(:error, "You need to create a company first")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to publish this job posting")}
    end
  end

  defp can_manage_job?(user, job_posting) do
    user_company = Companies.get_company_by_user(user)

    case user_company do
      nil -> false
      company -> Jobs.can_manage_jobs?(user, job_posting.company)
    end
  end
end
