defmodule BemedaPersonal.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Jobs` context.
  """

  import Ecto.Query, only: [from: 2]

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Jobs

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type job_application :: Jobs.JobApplication.t()
  @type job_posting :: Jobs.JobPosting.t()
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
        "experience_level" => "Mid-level",
        "gender" => ["Male"],
        "language" => ["English"],
        "location" => "some location",
        "part_time_details" => ["Min"],
        "position" => "Employee",
        "region" => ["Zurich"],
        "remote_allowed" => true,
        "salary_max" => 42_000,
        "salary_min" => 42_000,
        "shift_type" => ["Day Shift"],
        "title" => "some title",
        "workload" => ["Full-time"],
        "years_of_experience" => "2-5 years"
      }

    {:ok, job_posting} = Jobs.create_job_posting(company, Map.merge(job_posting_attrs, attrs))

    job_posting
  end

  @spec job_application_fixture(user(), job_posting(), attrs()) :: job_application()
  def job_application_fixture(%User{} = user, %Jobs.JobPosting{} = job_posting, attrs \\ %{}) do
    stringified_attrs = stringify_keys(attrs)
    {inserted_at, attrs_without_inserted_at} = Map.pop(stringified_attrs, "inserted_at")
    cover_letter_attrs = %{"cover_letter" => "some cover letter"}
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

  defp stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  defp stringify_keys(value), do: value
end
