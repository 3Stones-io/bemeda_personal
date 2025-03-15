defmodule BemedaPersonal.JobsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Jobs

  @invalid_attrs %{
    description: nil,
    title: nil,
    location: nil,
    currency: nil,
    employment_type: nil,
    experience_level: nil,
    salary_min: nil,
    salary_max: nil,
    remote_allowed: nil
  }

  defp create_job_posting(_attrs) do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company)
    %{company: company, job_posting: job_posting, user: user}
  end

  describe "list_job_postings/0" do
    setup :create_job_posting

    test "returns all job_postings", %{job_posting: job_posting} do
      result = Jobs.list_job_postings()
      assert length(result) == 1

      [result_job] = result
      assert result_job.id == job_posting.id
      assert result_job.title == job_posting.title
      assert result_job.description == job_posting.description
    end

    test "returns empty list when no job postings exist" do
      # Delete all job postings first
      Repo.delete_all(Jobs.JobPosting)
      assert Enum.empty?(Jobs.list_job_postings())
    end
  end

  describe "list_company_job_postings/1" do
    setup :create_job_posting

    test "returns all job postings for a company", %{company: company, job_posting: job_posting} do
      result = Jobs.list_company_job_postings(company)
      assert length(result) == 1

      [result_job] = result
      assert result_job.id == job_posting.id
      assert result_job.title == job_posting.title
      assert result_job.description == job_posting.description
    end

    test "returns empty list when company has no job postings" do
      user = user_fixture()
      company = company_fixture(user)
      assert Enum.empty?(Jobs.list_company_job_postings(company))
    end
  end

  describe "get_job_posting!/1" do
    setup :create_job_posting

    test "returns the job_posting with given id", %{job_posting: job_posting} do
      result = Jobs.get_job_posting!(job_posting.id)
      assert result.id == job_posting.id
      assert result.title == job_posting.title
      assert result.description == job_posting.description
    end

    test "raises error when job posting with id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Jobs.get_job_posting!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_or_update_job_posting/2" do
    setup :create_job_posting

    test "with valid data creates a job_posting", %{company: company} do
      valid_attrs = %{
        description: "some description that is long enough",
        title: "some valid title",
        location: "some location",
        currency: "some currency",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        salary_min: 42,
        salary_max: 42,
        remote_allowed: true
      }

      assert {:ok, %Jobs.JobPosting{} = job_posting} = Jobs.create_or_update_job_posting(company, valid_attrs)
      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
    end

    test "with valid data updates the job_posting", %{company: company, job_posting: job_posting} do
      update_attrs = %{
        id: job_posting.id,
        description: "some updated description that is long enough",
        title: "some updated valid title",
        remote_allowed: false
      }

      assert {:ok, %Jobs.JobPosting{} = updated_job_posting} =
               Jobs.create_or_update_job_posting(company, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      assert updated_job_posting.remote_allowed == false
    end

    test "with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} = Jobs.create_or_update_job_posting(company, @invalid_attrs)
    end

    test "with salary_min greater than salary_max returns error changeset", %{company: company} do
      invalid_attrs = %{
        description: "some description that is long enough",
        title: "some valid title",
        location: "some location",
        currency: "some currency",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        salary_min: 100,
        salary_max: 50,
        remote_allowed: true
      }

      assert {:error, %Ecto.Changeset{}} = Jobs.create_or_update_job_posting(company, invalid_attrs)
    end

    test "with title too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        description: "some description that is long enough",
        title: "tiny",
        location: "some location",
        currency: "some currency",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        salary_min: 42,
        salary_max: 42,
        remote_allowed: true
      }

      assert {:error, %Ecto.Changeset{}} = Jobs.create_or_update_job_posting(company, invalid_attrs)
    end

    test "with description too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        description: "too short",
        title: "some valid title",
        location: "some location",
        currency: "some currency",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        salary_min: 42,
        salary_max: 42,
        remote_allowed: true
      }

      assert {:error, %Ecto.Changeset{}} = Jobs.create_or_update_job_posting(company, invalid_attrs)
    end
  end

  describe "delete_job_posting/1" do
    setup :create_job_posting

    test "deletes the job_posting", %{job_posting: job_posting} do
      assert {:ok, %Jobs.JobPosting{}} = Jobs.delete_job_posting(job_posting)
      assert_raise Ecto.NoResultsError, fn -> Jobs.get_job_posting!(job_posting.id) end
    end

    test "returns error when job posting does not exist" do
      non_existent_id = Ecto.UUID.generate()

      job_posting = %Jobs.JobPosting{id: non_existent_id}

      assert_raise Ecto.StaleEntryError, fn ->
        Jobs.delete_job_posting(job_posting)
      end
    end
  end

  describe "change_job_posting/1" do
    setup :create_job_posting

    test "returns a job_posting changeset", %{job_posting: job_posting} do
      assert %Ecto.Changeset{} = Jobs.change_job_posting(job_posting)
    end

    test "returns a job_posting changeset with errors when data is invalid", %{job_posting: job_posting} do
      changeset = Jobs.change_job_posting(job_posting, @invalid_attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
      assert errors_on(changeset)[:title] == ["can't be blank"]
    end
  end
end
