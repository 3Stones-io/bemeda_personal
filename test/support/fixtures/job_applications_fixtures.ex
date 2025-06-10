defmodule BemedaPersonal.JobApplicationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.JobPostings` and `BemedaPersonal.JobApplications` contexts.
  """

  import BemedaPersonal.TestUtils
  import Ecto.Query, only: [from: 2]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobApplications.JobApplication
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonal.Repo

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_application :: JobApplication.t()
  @type job_posting :: JobPosting.t()
  @type user :: User.t()

  @spec job_application_fixture(user(), job_posting(), attrs()) :: job_application()
  def job_application_fixture(%User{} = user, %JobPosting{} = job_posting, attrs \\ %{}) do
    stringified_attrs = stringify_keys(attrs)
    {inserted_at, attrs_without_inserted_at} = Map.pop(stringified_attrs, "inserted_at")
    cover_letter_attrs = %{"cover_letter" => "some cover letter"}
    job_application_attrs = Map.merge(cover_letter_attrs, attrs_without_inserted_at)

    {:ok, job_application} =
      JobApplications.create_job_application(user, job_posting, job_application_attrs)

    if inserted_at do
      query = from(a in JobApplication, where: a.id == ^job_application.id)
      Repo.update_all(query, set: [inserted_at: inserted_at])

      JobApplication
      |> Repo.get!(job_application.id)
      |> Repo.preload([:user, job_posting: [:company]])
    else
      job_application
    end
  end
end
