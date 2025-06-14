defmodule BemedaPersonal.JobOffersTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobOffersFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Chat
  alias BemedaPersonal.JobOffers
  alias BemedaPersonal.JobOffers.JobOffer

  @invalid_attrs %{status: nil, variables: nil}

  describe "get_job_offer!/1" do
    test "returns the job_offer with given id" do
      job_offer = job_offer_fixture()
      assert JobOffers.get_job_offer!(job_offer.id) == job_offer
    end
  end

  describe "get_job_offer_by_application/1" do
    test "returns job offer for application" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      job_offer = job_offer_fixture(%{job_application_id: job_application.id})

      result = JobOffers.get_job_offer_by_application(job_application.id)
      assert result.id == job_offer.id
      assert result.job_application_id == job_application.id
    end

    test "returns nil when no offer exists" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      assert JobOffers.get_job_offer_by_application(job_application.id) == nil
    end
  end

  describe "create_job_offer/1" do
    test "with valid data creates a job_offer" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      valid_attrs = %{
        job_application_id: job_application.id,
        status: :pending,
        variables: %{"First_Name" => "John", "Last_Name" => "Doe"}
      }

      assert {:ok, %JobOffer{} = job_offer} = JobOffers.create_job_offer(valid_attrs)
      assert job_offer.status == :pending
      assert job_offer.variables == %{"First_Name" => "John", "Last_Name" => "Doe"}
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = JobOffers.create_job_offer(@invalid_attrs)
    end
  end

  describe "create_job_offer/2" do
    test "with message and invalid data returns error changeset" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)

      {:ok, message} =
        Chat.create_message(user, job_application, %{content: "Test message", media_data: %{}})

      assert {:error, %Ecto.Changeset{}} = JobOffers.create_job_offer(message, @invalid_attrs)
    end
  end

  describe "update_job_offer/3" do
    test "with valid data updates the job_offer" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)
      job_offer = job_offer_fixture(%{job_application_id: job_application.id})

      {:ok, message} =
        Chat.create_message(user, job_application, %{content: "Update message", media_data: %{}})

      update_attrs = %{status: :extended, variables: %{"Updated" => "data"}}

      assert {:ok, %JobOffer{} = job_offer} =
               JobOffers.update_job_offer(job_offer, message, update_attrs)

      assert job_offer.status == :extended
      assert job_offer.variables == %{"Updated" => "data"}
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      company = company_fixture(user_fixture())
      job_posting = job_posting_fixture(company)
      job_application = job_application_fixture(user, job_posting)
      job_offer = job_offer_fixture(%{job_application_id: job_application.id})

      {:ok, message} =
        Chat.create_message(user, job_application, %{content: "Update message", media_data: %{}})

      assert {:error, %Ecto.Changeset{}} =
               JobOffers.update_job_offer(job_offer, message, @invalid_attrs)

      assert job_offer == JobOffers.get_job_offer!(job_offer.id)
    end
  end

  describe "auto_populate_variables/1" do
    test "returns populated variables map" do
      user = user_fixture(%{first_name: "John", last_name: "Doe", city: "Zurich"})
      company = company_fixture(user_fixture(), %{name: "Test Company", location: "Switzerland"})

      job_posting =
        job_posting_fixture(company, %{title: "Software Engineer", location: "Remote"})

      job_application = job_application_fixture(user, job_posting)

      variables = JobOffers.auto_populate_variables(job_application)

      assert variables["First_Name"] == "John"
      assert variables["Last_Name"] == "Doe"
      assert variables["Client_Company"] == "Test Company"
      assert variables["Job_Title"] == "Software Engineer"
      assert variables["Work_Location"] == "Remote"
      assert variables["City"] == "Zurich"
      assert variables["Employer_Country"] == "Switzerland"
      assert variables["Date"] == Date.to_string(Date.utc_today())
      assert String.starts_with?(variables["Serial_Number"], "JO-#{Date.utc_today().year}-")
    end
  end
end
