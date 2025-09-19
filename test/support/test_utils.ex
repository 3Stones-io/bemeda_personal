defmodule BemedaPersonal.TestUtils do
  @moduledoc false

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.ChatFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Repo

  @spec update_struct_inserted_at(struct(), integer()) :: struct()
  def update_struct_inserted_at(struct, seconds_offset) do
    {:ok, updated_struct} =
      struct
      |> Ecto.Changeset.change(%{inserted_at: time_before_or_after(seconds_offset)})
      |> Repo.update()

    updated_struct
  end

  defp time_before_or_after(seconds_offset) do
    DateTime.utc_now()
    |> DateTime.add(seconds_offset)
    |> DateTime.truncate(:second)
  end

  @spec stringify_keys(map() | any()) :: map()
  def stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  def stringify_keys(value), do: value

  @spec create_complete_test_setup() :: map()
  def create_complete_test_setup do
    employer = employer_user_fixture()
    company = company_fixture(employer)
    job_posting = job_posting_fixture(company)
    job_seeker = user_fixture()
    job_application = job_application_fixture(job_seeker, job_posting)
    message = message_fixture(job_seeker, job_application)
    employer_scope = Scope.for_user(employer)
    scope = Scope.put_company(employer_scope, company)

    %{
      company: company,
      job_application: job_application,
      job_posting: job_posting,
      message: message,
      employer: employer,
      job_seeker: job_seeker,
      # For backward compatibility with existing tests
      user: job_seeker,
      scope: scope
    }
  end
end
