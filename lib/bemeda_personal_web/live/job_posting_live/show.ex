defmodule BemedaPersonalWeb.JobPostingLive.Show do
  use BemedaPersonalWeb, :live_view

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:user_company, Companies.get_company_by_user(current_user))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    job_posting = Jobs.get_job_posting!(id)

    socket =
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:job_posting, job_posting)

    socket =
      if socket.assigns.live_action == :edit do
        if can_manage_job?(socket.assigns.current_user, job_posting) do
          socket
        else
          socket
          |> put_flash(:error, "You are not authorized to edit this job posting")
          |> push_navigate(to: ~p"/job_postings/#{job_posting}")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  defp page_title(:show), do: "Job Posting Details"
  defp page_title(:edit), do: "Edit Job Posting"

  defp can_manage_job?(user, job_posting) do
    user_company = Companies.get_company_by_user(user)

    case user_company do
      nil -> false
      company -> Jobs.can_manage_jobs?(user, job_posting.company)
    end
  end
end
