defmodule BemedaPersonal.JobPostings do
  @moduledoc """
  The JobPostings context - interface for job posting operations.
  """

  alias BemedaPersonal.JobPostings.JobPostings

  defdelegate list_job_postings(filters \\ %{}, limit \\ 10), to: JobPostings
  defdelegate get_job_posting!(id), to: JobPostings
  defdelegate create_job_posting(company, attrs \\ %{}), to: JobPostings
  defdelegate update_job_posting(job_posting, attrs \\ %{}), to: JobPostings
  defdelegate delete_job_posting(job_posting), to: JobPostings
  defdelegate change_job_posting(job_posting, attrs \\ %{}), to: JobPostings
  defdelegate company_jobs_count(company_id), to: JobPostings
end
