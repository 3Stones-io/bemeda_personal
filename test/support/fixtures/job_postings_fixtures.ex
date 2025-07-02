defmodule BemedaPersonal.JobPostingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.JobPostings` and `BemedaPersonal.JobApplications` contexts.
  """

  import BemedaPersonal.TestUtils

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostings.JobPosting

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type user :: User.t()

  @spec job_posting_fixture(company(), attrs()) :: job_posting()
  def job_posting_fixture(%Companies.Company{} = company, attrs \\ %{}) do
    attrs = stringify_keys(attrs)

    job_posting_attrs =
      %{
        "currency" => "USD",
        "department" => ["Administration"],
        "description" => "some description that is long enough to meet validation requirements",
        "employment_type" => "Permanent Position",
        "gender" => ["Male"],
        "language" => ["English"],
        "location" => "some location",
        "part_time_details" => ["Min"],
        "position" => "Employee",
        "profession" => "Anesthesiologist",
        "region" => ["Zurich"],
        "remote_allowed" => true,
        "salary_max" => 42_000,
        "salary_min" => 42_000,
        "shift_type" => ["Day Shift"],
        "title" => "some title",
        "years_of_experience" => "2-5 years"
      }

    {:ok, job_posting} =
      JobPostings.create_job_posting(company, Map.merge(job_posting_attrs, attrs))

    job_posting
  end
end
