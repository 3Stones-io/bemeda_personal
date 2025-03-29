defmodule BemedaPersonal.JobsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobsFixtures

  alias BemedaPersonal.Jobs
  alias Phoenix.PubSub

  @invalid_attrs %{
    currency: nil,
    description: nil,
    employment_type: nil,
    experience_level: nil,
    location: nil,
    remote_allowed: nil,
    salary_max: nil,
    salary_min: nil,
    title: nil
  }

  defp create_job_posting(_attrs) do
    user = user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(company)
    job_application = job_application_fixture(user, job_posting)

    %{
      company: company,
      job_posting: job_posting,
      user: user,
      job_application: job_application
    }
  end

  defp create_multiple_job_postings(company, count) do
    Enum.map(1..count, fn i ->
      job_posting_fixture(company, %{
        description: "Description for job posting #{i}",
        employment_type: "Full-time #{i}",
        experience_level: "Senior #{i}",
        location: "Location #{i}",
        remote_allowed: rem(i, 2) == 0,
        salary_max: i * 15_000,
        salary_min: i * 10_000,
        title: "Job Posting #{i}"
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

      job_posting1 = job_posting_fixture(company, %{salary_min: 50_000, salary_max: 100_000})
      job_posting2 = job_posting_fixture(company, %{salary_min: 30_000, salary_max: 60_000})
      job_posting_fixture(company, %{salary_min: 120_000, salary_max: 150_000})

      assert results = Jobs.list_job_postings(%{salary_range: [55_000, 70_000]})
      assert length(results) == 2

      job_ids = Enum.map(results, & &1.id)
      assert job_posting1.id in job_ids
      assert job_posting2.id in job_ids
      assert length(job_ids) == 2

      results_with_higher_range = Jobs.list_job_postings(%{salary_range: [40_000, 1_000_000]})
      assert length(results_with_higher_range) == 3

      results_with_lower_range = Jobs.list_job_postings(%{salary_range: [0, 70_000]})
      assert length(results_with_lower_range) == 2

      job_ids_for_lower_range =
        results_with_lower_range
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert job_posting2.id in job_ids_for_lower_range
    end

    test "can filter job_postings by multiple parameters" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 =
        job_posting_fixture(company, %{
          employment_type: "Full-time",
          remote_allowed: true,
          salary_max: 120_000,
          salary_min: 80_000,
          title: "Senior Software Engineer"
        })

      job_posting_fixture(company, %{
        employment_type: "Full-time",
        remote_allowed: false,
        salary_max: 70_000,
        salary_min: 50_000,
        title: "Junior Software Engineer"
      })

      job_posting_fixture(company, %{
        employment_type: "Full-time",
        remote_allowed: true,
        salary_max: 130_000,
        salary_min: 90_000,
        title: "Senior Product Manager"
      })

      assert [result] =
               Jobs.list_job_postings(%{
                 remote_allowed: true,
                 salary_range: [75_000, 125_000],
                 title: "Engineer"
               })

      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list for multiple filters whose conditions are not met" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        employment_type: "Full-time",
        remote_allowed: true,
        salary_max: 120_000,
        salary_min: 80_000,
        title: "Senior Software Engineer"
      })

      assert [] =
               Jobs.list_job_postings(%{
                 remote_allowed: false,
                 salary_min: 100_000,
                 title: "Engineer"
               })
    end

    test "can filter job_postings by newer_than and older_than timestamp" do
      user = user_fixture()
      company = company_fixture(user)

      # Create job posts with controlled timestamps
      older_timestamp = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      middle_timestamp = DateTime.from_naive!(~N[2023-02-01 00:00:00], "Etc/UTC")
      newer_timestamp = DateTime.from_naive!(~N[2023-03-01 00:00:00], "Etc/UTC")

      older_job =
        %BemedaPersonal.Jobs.JobPosting{}
        |> BemedaPersonal.Jobs.JobPosting.changeset(%{
          currency: "USD",
          description: "Description for older job",
          employment_type: "Full-time",
          experience_level: "Mid-level",
          location: "Location",
          remote_allowed: false,
          salary_max: 70_000,
          salary_min: 50_000,
          title: "Older Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, older_timestamp)
        |> Repo.insert!()

      middle_job =
        %BemedaPersonal.Jobs.JobPosting{}
        |> BemedaPersonal.Jobs.JobPosting.changeset(%{
          currency: "USD",
          description: "Description for middle job",
          employment_type: "Full-time",
          experience_level: "Mid-level",
          location: "Location",
          remote_allowed: false,
          salary_max: 80_000,
          salary_min: 60_000,
          title: "Middle Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, middle_timestamp)
        |> Repo.insert!()

      newer_job =
        %BemedaPersonal.Jobs.JobPosting{}
        |> BemedaPersonal.Jobs.JobPosting.changeset(%{
          currency: "USD",
          description: "Description for newer job",
          employment_type: "Full-time",
          experience_level: "Mid-level",
          location: "Location",
          remote_allowed: false,
          salary_max: 90_000,
          salary_min: 70_000,
          title: "Newer Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, newer_timestamp)
        |> Repo.insert!()

      # Test newer_than filter
      assert results = Jobs.list_job_postings(%{newer_than: middle_job})
      assert length(results) == 1
      assert hd(results).id == newer_job.id

      # Test older_than filter
      assert results = Jobs.list_job_postings(%{older_than: middle_job})
      assert length(results) == 1
      assert hd(results).id == older_job.id

      # Test combined filters
      another_older_job =
        %BemedaPersonal.Jobs.JobPosting{}
        |> BemedaPersonal.Jobs.JobPosting.changeset(%{
          currency: "USD",
          description: "Description for another older job",
          employment_type: "Full-time",
          experience_level: "Mid-level",
          location: "Location",
          remote_allowed: true,
          salary_max: 75_000,
          salary_min: 55_000,
          title: "Another Older Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(
          :inserted_at,
          DateTime.from_naive!(~N[2023-01-15 00:00:00], "Etc/UTC")
        )
        |> Repo.insert!()

      assert results = Jobs.list_job_postings(%{older_than: middle_job, remote_allowed: true})
      assert length(results) == 1
      assert hd(results).id == another_older_job.id
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

  describe "create_job_posting/2" do
    setup :create_job_posting

    test "with valid data creates a job_posting", %{company: company} do
      valid_attrs = %{
        currency: "some currency",
        description: "some description that is long enough",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      assert {:ok, %Jobs.JobPosting{} = job_posting} =
               Jobs.create_job_posting(company, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
    end

    test "with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} =
               Jobs.create_job_posting(company, @invalid_attrs)
    end

    test "with salary_min greater than salary_max returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "some currency",
        description: "some description that is long enough",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 50,
        salary_min: 100,
        title: "some valid title"
      }

      assert {:error, %Ecto.Changeset{}} =
               Jobs.create_job_posting(company, invalid_attrs)
    end

    test "with title too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "some currency",
        description: "some description that is long enough",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "tiny"
      }

      assert {:error, %Ecto.Changeset{}} =
               Jobs.create_job_posting(company, invalid_attrs)
    end

    test "with description too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "some currency",
        description: "too short",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      assert {:error, %Ecto.Changeset{}} =
               Jobs.create_job_posting(company, invalid_attrs)
    end

    test "broadcasts job_posting_updated event when creating a new job posting", %{
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      PubSub.subscribe(BemedaPersonal.PubSub, company_topic)

      valid_attrs = %{
        currency: "some currency",
        description: "some description that is long enough",
        employment_type: "some employment_type",
        experience_level: "some experience_level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      {:ok, job_posting} = Jobs.create_job_posting(company, valid_attrs)

      assert_receive {:job_posting_updated, ^job_posting}
    end
  end

  describe "update_job_posting/2" do
    setup :create_job_posting

    test "with valid data updates the job_posting", %{job_posting: job_posting} do
      update_attrs = %{
        description: "some updated description that is long enough",
        title: "some updated valid title",
        remote_allowed: false
      }

      assert {:ok, %Jobs.JobPosting{} = updated_job_posting} =
               Jobs.update_job_posting(job_posting, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      assert updated_job_posting.remote_allowed == false
    end

    test "with invalid data returns error changeset", %{job_posting: job_posting} do
      assert {:error, %Ecto.Changeset{}} =
               Jobs.update_job_posting(job_posting, @invalid_attrs)
    end

    test "broadcasts job_posting_updated event when updating a job posting", %{
      job_posting: job_posting,
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      PubSub.subscribe(BemedaPersonal.PubSub, company_topic)

      update_attrs = %{
        description: "some updated description that is long enough",
        title: "some updated valid title",
        remote_allowed: false
      }

      {:ok, updated_job_posting} = Jobs.update_job_posting(job_posting, update_attrs)

      assert_receive {:job_posting_updated, ^updated_job_posting}
    end
  end

  describe "delete_job_posting/1" do
    setup :create_job_posting

    test "deletes the job_posting", %{job_posting: job_posting} do
      assert {:ok, %Jobs.JobPosting{}} = Jobs.delete_job_posting(job_posting)
      assert_raise Ecto.NoResultsError, fn -> Jobs.get_job_posting!(job_posting.id) end
    end

    test "broadcasts job_posting_deleted event when deleting a job posting", %{
      job_posting: job_posting,
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      PubSub.subscribe(BemedaPersonal.PubSub, company_topic)

      job_posting = Repo.preload(job_posting, :company)

      {:ok, deleted_job_posting} = Jobs.delete_job_posting(job_posting)

      assert_receive {:job_posting_deleted, ^deleted_job_posting}
    end

    test "returns error when job posting does not exist" do
      non_existent_id = Ecto.UUID.generate()

      job_posting = %Jobs.JobPosting{id: non_existent_id}

      assert_raise Ecto.StaleEntryError, fn ->
        Jobs.delete_job_posting(job_posting)
      end
    end
  end

  describe "company_jobs_count/1" do
    test "returns the correct count of job postings for a company" do
      user = user_fixture()
      company = company_fixture(user)

      assert Jobs.company_jobs_count(company.id) == 0

      create_multiple_job_postings(company, 3)
      assert Jobs.company_jobs_count(company.id) == 3

      user2 = user_fixture(%{email: "another@example.com"})
      company2 = company_fixture(user2)
      create_multiple_job_postings(company2, 2)

      assert Jobs.company_jobs_count(company.id) == 3
      assert Jobs.company_jobs_count(company2.id) == 2
    end

    test "returns zero for company with no job postings" do
      user = user_fixture()
      company = company_fixture(user)

      assert Jobs.company_jobs_count(company.id) == 0
    end

    test "returns zero for non-existent company ID" do
      non_existent_id = Ecto.UUID.generate()
      assert Jobs.company_jobs_count(non_existent_id) == 0
    end
  end

  describe "change_job_posting/1" do
    setup :create_job_posting

    test "returns a job_posting changeset", %{job_posting: job_posting} do
      assert %Ecto.Changeset{} = Jobs.change_job_posting(job_posting)
    end

    test "returns a job_posting changeset with errors when data is invalid", %{
      job_posting: job_posting
    } do
      changeset = Jobs.change_job_posting(job_posting, @invalid_attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
      assert errors_on(changeset)[:title] == ["can't be blank"]
    end
  end

  # Job Applications
  describe "create_job_application/3" do
    setup [:create_job_posting]

    test "creates a job_application with valid data", %{job_posting: job_posting, user: user} do
      valid_attrs = %{
        cover_letter: "some cover letter"
      }

      assert {:ok, %Jobs.JobApplication{} = job_application} =
               Jobs.create_job_application(user, job_posting, valid_attrs)

      assert job_application.cover_letter == "some cover letter"
      assert job_application.job_posting_id == job_posting.id
      assert job_application.user_id == user.id
    end

    test "returns error changeset when data is invalid", %{job_posting: job_posting, user: user} do
      invalid_attrs = %{
        cover_letter: nil
      }

      assert {:error, %Ecto.Changeset{}} =
               Jobs.create_job_application(user, job_posting, invalid_attrs)
    end
  end

  describe "change_job_posting_application/1" do
    setup [:create_job_posting]

    test "returns a job_posting changeset", %{job_application: job_application} do
      assert %Ecto.Changeset{} = Jobs.change_job_application(job_application)
    end

    test "returns a job_posting changeset with errors when data is invalid", %{
      job_application: job_application
    } do
      changeset = Jobs.change_job_application(job_application, %{cover_letter: nil})
      assert %Ecto.Changeset{valid?: false} = changeset
      assert errors_on(changeset)[:cover_letter] == ["can't be blank"]
    end
  end

  describe "update_job_application/2" do
    setup [:create_job_posting]

    test "updates the job_application with valid data", %{job_application: job_application} do
      update_attrs = %{
        cover_letter: "updated cover letter"
      }

      assert {:ok, %Jobs.JobApplication{} = updated_job_application} =
               Jobs.update_job_application(job_application, update_attrs)

      assert updated_job_application.cover_letter == "updated cover letter"
      assert updated_job_application.id == job_application.id
    end

    test "returns error changeset with invalid data", %{job_application: job_application} do
      invalid_attrs = %{
        cover_letter: nil
      }

      assert {:error, %Ecto.Changeset{}} =
               Jobs.update_job_application(job_application, invalid_attrs)

      # The job application should remain unchanged
      unchanged_job_application = Jobs.get_job_application!(job_application.id)
      assert unchanged_job_application.cover_letter == job_application.cover_letter
    end
  end

  describe "get_job_application!/1" do
    setup [:create_job_posting]

    test "returns the job_application with given id", %{job_application: job_application} do
      result = Jobs.get_job_application!(job_application.id)
      assert result.id == job_application.id
      assert result.cover_letter == job_application.cover_letter
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "raises error when job application with id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Jobs.get_job_application!(Ecto.UUID.generate())
      end
    end
  end

  describe "list_job_applications/2" do
    setup [:create_job_posting]

    test "returns all job applications when no filter is passed", %{
      job_application: job_application
    } do
      assert [result] = Jobs.list_job_applications()
      assert result.id == job_application.id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "can filter job applications by user_id", %{job_application: job_application, user: user} do
      # Create another user with an application
      user2 = user_fixture(%{email: "user2@example.com"})
      job_application_fixture(user2, job_application.job_posting)

      assert [result] = Jobs.list_job_applications(%{user_id: user.id})
      assert result.id == job_application.id
      assert result.user_id == user.id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "can filter job applications by job_posting_id", %{
      job_application: job_application,
      user: user
    } do
      # Create another job posting with an application
      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)
      job_application_fixture(user, another_job_posting)

      assert [result] =
               Jobs.list_job_applications(%{job_posting_id: job_application.job_posting_id})

      assert result.id == job_application.id
      assert result.job_posting_id == job_application.job_posting_id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "can filter job applications by company_id", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      company_id = job_posting.company_id

      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)
      job_application_fixture(user, another_job_posting)

      results = Jobs.list_job_applications(%{company_id: company_id})

      assert length(results) == 1
      [result] = results
      assert result.id == job_application.id
      assert result.job_posting.company_id == company_id
      assert Ecto.assoc_loaded?(result.job_posting)
      assert Ecto.assoc_loaded?(result.user)
    end

    test "returns empty list when a user has no job applications" do
      user = user_fixture(%{email: "no_applications@example.com"})
      non_existing_user_id = Ecto.UUID.generate()

      assert %{user_id: non_existing_user_id}
             |> Jobs.list_job_applications()
             |> Enum.empty?()

      assert %{user_id: user.id}
             |> Jobs.list_job_applications()
             |> Enum.empty?()
    end

    test "returns empty list when a job posting has no applications" do
      user = user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)
      non_existing_job_posting_id = Ecto.UUID.generate()

      assert %{job_posting_id: non_existing_job_posting_id}
             |> Jobs.list_job_applications()
             |> Enum.empty?()

      assert %{job_posting_id: job_posting.id}
             |> Jobs.list_job_applications()
             |> Enum.empty?()
    end

    test "can filter job applications by multiple parameters", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      user2 = user_fixture(%{email: "user2@example.com"})

      another_company = company_fixture(user)
      another_job_posting = job_posting_fixture(another_company)

      # Create job applications with different combinations
      job_application_fixture(user2, job_posting)
      job_application_fixture(user, another_job_posting)
      job_application_fixture(user2, another_job_posting)

      assert [result] =
               Jobs.list_job_applications(%{
                 user_id: user.id,
                 job_posting_id: job_posting.id,
                 company_id: job_posting.company_id
               })

      assert result.id == job_application.id
      assert result.user_id == user.id
      assert result.job_posting_id == job_posting.id
    end

    test "defaults to listing all job applications if a non-existent filter is passed", %{
      job_application: job_application
    } do
      assert [result] = Jobs.list_job_applications(%{unknown_filter: "unknown_filter"})
      assert job_application.id == result.id
    end

    test "limits the number of returned job applications" do
      user = user_fixture()
      company = company_fixture(user)
      job_posting = job_posting_fixture(company)

      # Create multiple job applications
      Enum.each(1..15, fn _application ->
        job_application_fixture(user, job_posting, %{
          cover_letter: "Cover letter #{:rand.uniform(1000)}"
        })
      end)

      assert length(Jobs.list_job_applications()) == 10
      assert length(Jobs.list_job_applications(%{}, 5)) == 5
    end
  end

  describe "get_user_job_application/2" do
    setup [:create_job_posting]

    test "returns the job_application for a user and job posting", %{
      job_application: job_application,
      user: user,
      job_posting: job_posting
    } do
      result = Jobs.get_user_job_application(user, job_posting)
      assert result.id == job_application.id
      assert result.user_id == user.id
      assert result.job_posting_id == job_posting.id
    end

    test "returns nil when a user has not applied to a job posting", %{job_posting: job_posting} do
      another_user = user_fixture(%{email: "no_application@example.com"})
      refute Jobs.get_user_job_application(another_user, job_posting)
    end
  end
end
