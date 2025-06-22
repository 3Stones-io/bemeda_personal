defmodule BemedaPersonalWeb.JobApplicationLive.Authorization do
  @moduledoc """
  Shared authorization logic for job application LiveViews.
  """

  use BemedaPersonalWeb, :live_view

  @doc """
  Authorizes access to a job application based on user type and ownership.

  Returns:
  - `:ok` if access is authorized
  - `{:error, {redirect_path, error_message}}` if access is denied
  """
  @spec authorize_job_application_access(Phoenix.LiveView.Socket.t(), map()) ::
          :ok | {:error, {String.t(), String.t()}}
  def authorize_job_application_access(socket, job_application) do
    current_user = socket.assigns.current_user
    job_posting = job_application.job_posting
    job_seeker_user_id = job_application.user_id
    company_admin_user_id = job_posting.company.admin_user_id

    case {current_user.user_type, current_user.id} do
      # Job seeker: must own the application
      {:job_seeker, ^job_seeker_user_id} ->
        :ok

      # Employer: must own the company that posted the job
      {:employer, ^company_admin_user_id} ->
        :ok

      # No access - return appropriate error
      {:job_seeker, _unauthorized_user_id} ->
        {:error,
         {~p"/job_applications",
          dgettext("auth", "You can only access your own job applications.")}}

      {:employer, _unauthorized_user_id} ->
        {:error,
         {~p"/company/applicants",
          dgettext("auth", "You can only access job applications for your company.")}}

      _unknown_user_type ->
        {:error,
         {~p"/users/log_in", dgettext("auth", "You must be logged in to access this page.")}}
    end
  end
end
