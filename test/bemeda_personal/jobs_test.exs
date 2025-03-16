defmodule BemedaPersonal.JobsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Jobs
  alias BemedaPersonal.Jobs.JobPosting

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

  defp create_multiple_job_postings(company, count) do
    Enum.map(1..count, fn i ->
      job_posting_fixture(company, %{
        title: "Job Posting #{i}",
        description: "Description for job posting #{i}",
        employment_type: "Full-time #{i}",
        experience_level: "Senior #{i}",
        location: "Location #{i}",
        remote_allowed: rem(i, 2) == 0,
        salary_min: i * 10000,
        salary_max: i * 15000
      })
    end)
  end

  describe "list_job_postings/2" do
    test "returns all job_postings when no filter is passed" do
      %{job_posting: job_posting} = create_job_posting(%{})

      assert [result] = Jobs.list_job_postings()
      assert result.id == job_posting.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by company_id" do
      %{company: company, job_posting: job_posting} = create_job_posting(%{})

      user2 = user_fixture(%{email: "user2@example.com"})
      company2 = company_fixture(user2)
      job_posting_fixture(company2, %{title: "Job Posting for Company 2"})

      assert [result] = Jobs.list_job_postings(%{company_id: company.id})
      assert result.id == job_posting.id
      assert result.company_id == company.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list when a company has no job_postings" do
      user = user_fixture()
      company = company_fixture(user)
      non_existing_company_id = Ecto.UUID.generate()

      assert [] = Jobs.list_job_postings(%{company_id: non_existing_company_id})
      assert [] = Jobs.list_job_postings(%{company_id: company.id})
    end

    test "can filter job_postings by title" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{title: "Software Engineer"})
      job_posting_fixture(company, %{title: "Product Manager"})

      assert [result] = Jobs.list_job_postings(%{title: "Engineer"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by employment_type" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{employment_type: "Full-time"})
      job_posting_fixture(company, %{employment_type: "Part-time"})

      assert [result] = Jobs.list_job_postings(%{employment_type: "Full"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by experience_level" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{experience_level: "Senior"})
      job_posting_fixture(company, %{experience_level: "Junior"})

      assert [result] = Jobs.list_job_postings(%{experience_level: "Senior"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by remote_allowed" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{remote_allowed: true})
      job_posting_fixture(company, %{remote_allowed: false})

      assert [result] = Jobs.list_job_postings(%{remote_allowed: true})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by location" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{location: "New York"})
      job_posting_fixture(company, %{location: "San Francisco"})

      assert [result] = Jobs.list_job_postings(%{location: "New"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by salary_range" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{salary_min: 50000, salary_max: 100000})
      job_posting2 = job_posting_fixture(company, %{salary_min: 30000, salary_max: 60000})
      job_posting_fixture(company, %{salary_min: 120000, salary_max: 150000})

      assert results = Jobs.list_job_postings(%{salary_range: [55000, 70000]})
      assert length(results) == 2

      job_ids = Enum.map(results, & &1.id)
      assert job_posting1.id in job_ids
      assert job_posting2.id in job_ids
      assert length(job_ids) == 2

      results = Jobs.list_job_postings(%{salary_range: [40000, 1000000]})
      assert length(results) == 3

      results = Jobs.list_job_postings(%{salary_range: [0, 70000]})
      assert length(results) == 2

      job_ids = Enum.map(results, & &1.id) |> Enum.sort()
      assert job_posting2.id in job_ids
    end

    test "can filter job_postings by multiple parameters" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{
        title: "Senior Software Engineer",
        employment_type: "Full-time",
        remote_allowed: true,
        salary_min: 80000,
        salary_max: 120000
      })

      job_posting_fixture(company, %{
        title: "Junior Software Engineer",
        employment_type: "Full-time",
        remote_allowed: false,
        salary_min: 50000,
        salary_max: 70000
      })

      job_posting_fixture(company, %{
        title: "Senior Product Manager",
        employment_type: "Full-time",
        remote_allowed: true,
        salary_min: 90000,
        salary_max: 130000
      })

      assert [result] = Jobs.list_job_postings(%{
        title: "Engineer",
        remote_allowed: true,
        salary_range: [75000, 125000]
      })

      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list for multiple filters whose conditions are not met" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        title: "Senior Software Engineer",
        employment_type: "Full-time",
        remote_allowed: true,
        salary_min: 80000,
        salary_max: 120000
      })

      assert [] = Jobs.list_job_postings(%{
        title: "Engineer",
        remote_allowed: false,
        salary_min: 100000
      })
    end

    test "defaults to listing all job_postings if a non-existent filter is passed" do
      %{job_posting: job_posting} = create_job_posting(%{})

      assert [result] = Jobs.list_job_postings(%{unknown_filter: "unknown_filter"})
      assert job_posting.id == result.id
    end

    test "limits the number of returned job_postings" do
      user = user_fixture()
      company = company_fixture(user)

      create_multiple_job_postings(company, 15)
      assert length(Jobs.list_job_postings()) == 10
      assert length(Jobs.list_job_postings(%{}, 5)) == 5
      assert length(Jobs.list_job_postings(%{}, 20)) == 15
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
