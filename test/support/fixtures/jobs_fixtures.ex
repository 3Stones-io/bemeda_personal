defmodule BemedaPersonal.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Jobs` context.
  """

  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_posting :: Jobs.JobPosting.t()

  @spec job_posting_fixture(company(), attrs()) :: job_posting()
  def job_posting_fixture(company = %Companies.Company{}, attrs \\ %{}) do
    job_posting_attrs =
      Enum.into(attrs, %{
        currency: "USD",
        description: "some description",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42_000,
        salary_min: 42_000,
        title: "some title"
      })

    {:ok, job_posting} = Jobs.create_or_update_job_posting(company, job_posting_attrs)

    job_posting
  end
end
