defmodule BemedaPersonal.JobApplications do
  @moduledoc """
  The JobApplications context - interface for job application operations.
  """

  alias BemedaPersonal.JobApplications.JobApplications
  alias BemedaPersonal.JobApplications.JobApplicationStatus
  alias BemedaPersonal.JobApplications.JobApplicationTags

  # Job Applications
  defdelegate list_job_applications(filters \\ %{}, limit \\ 10), to: JobApplications
  defdelegate get_job_application!(id), to: JobApplications
  defdelegate get_user_job_application(user, job_posting), to: JobApplications
  defdelegate create_job_application(user, job_posting, attrs \\ %{}), to: JobApplications
  defdelegate update_job_application(job_application, attrs), to: JobApplications
  defdelegate change_job_application(job_application, attrs \\ %{}), to: JobApplications
  defdelegate user_has_applied_to_company_job?(user_id, company_id), to: JobApplications
  defdelegate count_user_applications(user_id), to: JobApplications

  # Status Management
  defdelegate update_job_application_status(job_application, user, attrs),
    to: JobApplicationStatus

  defdelegate change_job_application_status(job_application_state_transition, attrs \\ %{}),
    to: JobApplicationStatus

  defdelegate list_job_application_state_transitions(job_application), to: JobApplicationStatus
  defdelegate get_latest_withdraw_state_transition(job_application), to: JobApplications

  # Tags Management
  defdelegate update_job_application_tags(job_application, tags), to: JobApplicationTags
end
