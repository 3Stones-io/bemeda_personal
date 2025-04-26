defmodule BemedaPersonal.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Jobs` context.
  """

  import Ecto.Query, only: [from: 2]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_application :: Jobs.JobApplication.t()
  @type job_posting :: Jobs.JobPosting.t()
  @type user :: User.t()

  @spec job_posting_fixture(company(), attrs()) :: job_posting()
  def job_posting_fixture(%Companies.Company{} = company, attrs \\ %{}) do
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

    {:ok, job_posting} = Jobs.create_job_posting(company, job_posting_attrs)

    job_posting
  end

  @spec job_application_fixture(user(), job_posting(), attrs()) :: job_application()
  def job_application_fixture(%User{} = user, %Jobs.JobPosting{} = job_posting, attrs \\ %{}) do
    {inserted_at, attrs_without_inserted_at} = Map.pop(attrs, :inserted_at)
    cover_letter_attrs = %{cover_letter: "some cover letter"}
    job_application_attrs = Map.merge(cover_letter_attrs, attrs_without_inserted_at)

    {:ok, job_application} = Jobs.create_job_application(user, job_posting, job_application_attrs)

    if inserted_at do
      query = from(a in Jobs.JobApplication, where: a.id == ^job_application.id)
      BemedaPersonal.Repo.update_all(query, set: [inserted_at: inserted_at])

      Jobs.JobApplication
      |> BemedaPersonal.Repo.get!(job_application.id)
      |> BemedaPersonal.Repo.preload([:user, job_posting: [:company]])
    else
      job_application
    end
  end
end
