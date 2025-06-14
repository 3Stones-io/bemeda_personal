defmodule BemedaPersonal.JobOffersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.JobOffers` context.
  """

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  @doc """
  Generate a job_offer.
  """
  @spec job_offer_fixture(map()) :: BemedaPersonal.JobOffers.JobOffer.t()
  def job_offer_fixture(attrs \\ %{}) do
    {job_application_id, updated_attrs} =
      case Map.get(attrs, :job_application_id) do
        nil ->
          user = user_fixture()
          company = company_fixture(user_fixture())
          job_posting = job_posting_fixture(company)
          job_application = job_application_fixture(user, job_posting)
          {job_application.id, Map.put(attrs, :job_application_id, job_application.id)}

        id ->
          {id, attrs}
      end

    default_variables = %{
      "First_Name" => "John",
      "Last_Name" => "Doe",
      "Job_Title" => "Software Engineer",
      "Client_Company" => "Test Company",
      "Date" => Date.to_string(Date.utc_today()),
      "Serial_Number" => "JO-#{Date.utc_today().year}-123456"
    }

    final_attrs =
      Map.merge(
        %{
          job_application_id: job_application_id,
          status: :pending,
          variables: Map.get(updated_attrs, :variables, default_variables)
        },
        updated_attrs
      )

    {:ok, job_offer} = BemedaPersonal.JobOffers.create_job_offer(final_attrs)

    job_offer
  end
end
