defmodule BemedaPersonal.JobOffersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.JobOffers` context.
  """

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.Scope

  @doc """
  Generate a job_offer.
  """
  @spec job_offer_fixture(map()) :: BemedaPersonal.JobOffers.JobOffer.t()
  def job_offer_fixture(attrs \\ %{}) do
    {job_application_id, updated_attrs, scope} = setup_job_application_context(attrs)

    final_attrs = build_job_offer_attrs(job_application_id, updated_attrs)

    {:ok, job_offer} = BemedaPersonal.JobOffers.create_job_offer(scope, final_attrs)

    job_offer
  end

  defp setup_job_application_context(attrs) do
    case Map.get(attrs, :job_application_id) do
      nil -> create_job_application_context(attrs)
      id -> load_existing_job_application_context(id, attrs)
    end
  end

  defp create_job_application_context(attrs) do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)

    scope =
      user
      |> Scope.for_user()
      |> Scope.put_company(company)

    updated_attrs = Map.put(attrs, :job_application_id, job_application.id)

    {job_application.id, updated_attrs, scope}
  end

  defp load_existing_job_application_context(id, attrs) do
    job_application =
      BemedaPersonal.JobApplications.JobApplication
      |> BemedaPersonal.Repo.get!(id)
      |> BemedaPersonal.Repo.preload([:user, job_posting: [:company]])

    user_scope = Scope.for_user(job_application.user)
    company = job_application.job_posting.company
    scope = Scope.put_company(user_scope, company)

    {id, attrs, scope}
  end

  defp build_job_offer_attrs(job_application_id, updated_attrs) do
    default_variables = %{
      "First_Name" => "John",
      "Last_Name" => "Doe",
      "Job_Title" => "Software Engineer",
      "Client_Company" => "Test Company",
      "Date" => Date.to_string(Date.utc_today()),
      "Serial_Number" => "JO-#{Date.utc_today().year}-123456"
    }

    Map.merge(
      %{
        job_application_id: job_application_id,
        status: :pending,
        variables: Map.get(updated_attrs, :variables, default_variables)
      },
      updated_attrs
    )
  end
end
