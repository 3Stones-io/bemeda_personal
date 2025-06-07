defmodule BemedaPersonal.Jobs do
  @moduledoc """
  The Jobs context.
  """

  alias BemedaPersonal.Jobs.JobApplications
  alias BemedaPersonal.Jobs.JobApplicationStatus
  alias BemedaPersonal.Jobs.JobApplicationTags
  alias BemedaPersonal.Jobs.JobPostings

  # Job Postings
  defdelegate list_job_postings(filters \\ %{}, limit \\ 10), to: JobPostings
  defdelegate get_job_posting!(id), to: JobPostings
  defdelegate create_job_posting(company, attrs \\ %{}), to: JobPostings
  defdelegate update_job_posting(job_posting, attrs \\ %{}), to: JobPostings
  defdelegate delete_job_posting(job_posting), to: JobPostings
  defdelegate change_job_posting(job_posting, attrs \\ %{}), to: JobPostings
  defdelegate company_jobs_count(company_id), to: JobPostings

  # Job Applications
  defdelegate list_job_applications(filters \\ %{}, limit \\ 10), to: JobApplications
  defdelegate get_job_application!(id), to: JobApplications
  defdelegate get_user_job_application(user, job_posting), to: JobApplications
  defdelegate create_job_application(user, job_posting, attrs \\ %{}), to: JobApplications
  defdelegate update_job_application(job_application, attrs), to: JobApplications
  defdelegate change_job_application(job_application, attrs \\ %{}), to: JobApplications
  defdelegate user_has_applied_to_company_job?(user_id, company_id), to: JobApplications

  # Job Application Status
  defdelegate update_job_application_status(job_application, user, attrs),
    to: JobApplicationStatus

  defdelegate change_job_application_status(job_application_state_transition, attrs \\ %{}),
    to: JobApplicationStatus

  defdelegate list_job_application_state_transitions(job_application), to: JobApplicationStatus

  # Job Application Tags
  defdelegate update_job_application_tags(job_application, tags), to: JobApplicationTags
end
