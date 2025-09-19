defmodule BemedaPersonal.JobPostingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.JobPostings` and `BemedaPersonal.JobApplications` contexts.
  """

  alias BemedaPersonal.Accounts.Scope
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

  @spec stringify_keys(map() | any()) :: map()
  defp stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  defp stringify_keys(value), do: value

  @spec job_posting_fixture(company(), attrs()) :: job_posting()
  @spec job_posting_fixture(user(), company(), attrs()) :: job_posting()
  def job_posting_fixture(%Companies.Company{} = company, attrs \\ %{}) do
    # Get the company with admin_user preloaded using system scope
    company_with_admin = Companies.get_company!(Scope.system(), company.id)
    job_posting_fixture(company_with_admin.admin_user, company, attrs)
  end

  def job_posting_fixture(%User{} = user, %Companies.Company{} = company, attrs) do
    attrs = stringify_keys(attrs)

    job_posting_attrs =
      %{
        "currency" => :USD,
        "department" => [:Administration],
        "description" => "some description that is long enough to meet validation requirements",
        "employment_type" => :"Permanent Position",
        "gender" => [:Male],
        "language" => [:English],
        "location" => "some location",
        "part_time_details" => [:Min],
        "position" => :Employee,
        "profession" => :Anesthesiologist,
        "region" => [:Zurich],
        "remote_allowed" => true,
        "salary_max" => 42_000,
        "salary_min" => 42_000,
        "shift_type" => [:"Day Shift"],
        "title" => "some title",
        "years_of_experience" => :"2-5 years"
      }

    # Create a scope for the user and company
    scope =
      user
      |> Scope.for_user()
      |> Scope.put_company(company)

    {:ok, job_posting} =
      JobPostings.create_job_posting(scope, Map.merge(job_posting_attrs, attrs))

    job_posting
  end
end
