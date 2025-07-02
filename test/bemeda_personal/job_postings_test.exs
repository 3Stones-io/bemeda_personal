defmodule BemedaPersonal.JobPostingsTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @invalid_attrs %{"title" => nil}

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
        employment_type: "Permanent Position",
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

      assert [result] = JobPostings.list_job_postings()
      assert result.id == job_posting.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by company_id" do
      %{company: company, job_posting: job_posting} = create_job_posting(%{})

      user2 = user_fixture(%{email: "user2@example.com"})
      company2 = company_fixture(user2)
      job_posting_fixture(company2, %{title: "Job Posting for Company 2"})

      assert [result] = JobPostings.list_job_postings(%{company_id: company.id})
      assert result.id == job_posting.id
      assert result.company_id == company.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list when a company has no job_postings" do
      user = user_fixture()
      company = company_fixture(user)
      non_existing_company_id = Ecto.UUID.generate()

      assert [] = JobPostings.list_job_postings(%{company_id: non_existing_company_id})
      assert [] = JobPostings.list_job_postings(%{company_id: company.id})
    end

    test "can search for job_postings by title and description" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{title: "Software Engineer"})
      job_posting_fixture(company, %{title: "Product Manager"})

      assert [result] = JobPostings.list_job_postings(%{search: "Engineer"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by employment_type" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{employment_type: "Permanent Position"})
      job_posting_fixture(company, %{employment_type: "Floater"})

      assert [result] = JobPostings.list_job_postings(%{employment_type: "Permanent Position"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by remote_allowed" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{remote_allowed: true})
      job_posting_fixture(company, %{remote_allowed: false})

      assert [result] = JobPostings.list_job_postings(%{remote_allowed: true})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by location" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{location: "New York"})
      job_posting_fixture(company, %{location: "San Francisco"})

      assert [result] = JobPostings.list_job_postings(%{location: "New"})
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by salary_range" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{salary_min: 50_000, salary_max: 100_000})
      job_posting2 = job_posting_fixture(company, %{salary_min: 30_000, salary_max: 60_000})
      job_posting_fixture(company, %{salary_min: 120_000, salary_max: 150_000})

      assert results = JobPostings.list_job_postings(%{salary_range: [55_000, 70_000]})
      assert length(results) == 2

      job_ids = Enum.map(results, & &1.id)
      assert job_posting1.id in job_ids
      assert job_posting2.id in job_ids
      assert length(job_ids) == 2

      results_with_higher_range =
        JobPostings.list_job_postings(%{salary_range: [40_000, 1_000_000]})

      assert length(results_with_higher_range) == 3

      results_with_lower_range = JobPostings.list_job_postings(%{salary_range: [0, 70_000]})
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
          employment_type: "Permanent Position",
          remote_allowed: true,
          salary_max: 120_000,
          salary_min: 80_000,
          title: "Senior Software Engineer"
        })

      job_posting_fixture(company, %{
        employment_type: "Permanent Position",
        remote_allowed: false,
        salary_max: 70_000,
        salary_min: 50_000,
        title: "Junior Software Engineer"
      })

      job_posting_fixture(company, %{
        employment_type: "Permanent Position",
        remote_allowed: true,
        salary_max: 130_000,
        salary_min: 90_000,
        title: "Senior Product Manager"
      })

      assert [result] =
               JobPostings.list_job_postings(%{
                 remote_allowed: true,
                 salary_range: [75_000, 125_000],
                 search: "Engineer"
               })

      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list for multiple filters whose conditions are not met" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        employment_type: "Permanent Position",
        remote_allowed: true,
        salary_max: 120_000,
        salary_min: 80_000,
        title: "Senior Software Engineer"
      })

      assert [] =
               JobPostings.list_job_postings(%{
                 remote_allowed: false,
                 salary_min: 100_000,
                 search: "Engineer"
               })
    end

    test "can filter job_postings by newer_than and older_than timestamp" do
      user = user_fixture()
      company = company_fixture(user)

      older_timestamp = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      middle_timestamp = DateTime.from_naive!(~N[2023-02-01 00:00:00], "Etc/UTC")
      newer_timestamp = DateTime.from_naive!(~N[2023-03-01 00:00:00], "Etc/UTC")

      older_job =
        %JobPosting{}
        |> JobPosting.changeset(%{
          currency: "USD",
          description: "Description for older job",
          employment_type: "Permanent Position",
          location: "Location",
          position: "Employee",
          remote_allowed: false,
          salary_max: 70_000,
          salary_min: 50_000,
          title: "Older Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, older_timestamp)
        |> Repo.insert!()

      middle_job =
        %JobPosting{}
        |> JobPosting.changeset(%{
          currency: "USD",
          description: "Description for middle job",
          employment_type: "Permanent Position",
          location: "Location",
          position: "Employee",
          remote_allowed: false,
          salary_max: 80_000,
          salary_min: 60_000,
          title: "Middle Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, middle_timestamp)
        |> Repo.insert!()

      newer_job =
        %JobPosting{}
        |> JobPosting.changeset(%{
          currency: "USD",
          description: "Description for newer job",
          employment_type: "Permanent Position",
          location: "Location",
          position: "Employee",
          remote_allowed: false,
          salary_max: 90_000,
          salary_min: 70_000,
          title: "Newer Job"
        })
        |> Ecto.Changeset.put_assoc(:company, company)
        |> Ecto.Changeset.put_change(:inserted_at, newer_timestamp)
        |> Repo.insert!()

      assert results = JobPostings.list_job_postings(%{newer_than: middle_job})
      assert length(results) == 1
      assert hd(results).id == newer_job.id

      assert results = JobPostings.list_job_postings(%{older_than: middle_job})
      assert length(results) == 1
      assert hd(results).id == older_job.id

      another_older_job =
        %JobPosting{}
        |> JobPosting.changeset(%{
          currency: "USD",
          description: "Description for another older job",
          employment_type: "Permanent Position",
          location: "Location",
          position: "Employee",
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

      assert results =
               JobPostings.list_job_postings(%{older_than: middle_job, remote_allowed: true})

      assert length(results) == 1
      assert hd(results).id == another_older_job.id
    end

    test "defaults to listing all job_postings if a non-existent filter is passed" do
      %{job_posting: job_posting} = create_job_posting(%{})

      assert [result] = JobPostings.list_job_postings(%{unknown_filter: "unknown_filter"})
      assert job_posting.id == result.id
    end

    test "limits the number of returned job_postings" do
      user = user_fixture()
      company = company_fixture(user)

      create_multiple_job_postings(company, 15)
      assert length(JobPostings.list_job_postings()) == 10
      assert length(JobPostings.list_job_postings(%{}, 5)) == 5
      assert length(JobPostings.list_job_postings(%{}, 20)) == 15
    end
  end

  describe "count_job_postings/1" do
    setup :create_job_posting

    test "returns count of all job_postings when no filter is passed", %{
      job_posting: _job_posting
    } do
      assert JobPostings.count_job_postings() == 1
      assert JobPostings.count_job_postings(%{}) == 1
    end

    test "can count job_postings by company_id", %{job_posting: job_posting} do
      user = user_fixture()
      other_company = company_fixture(user)
      job_posting_fixture(other_company)

      assert JobPostings.count_job_postings(%{company_id: job_posting.company_id}) == 1
      assert JobPostings.count_job_postings(%{company_id: other_company.id}) == 1
      assert JobPostings.count_job_postings() == 2
    end

    test "returns zero when a company has no job_postings" do
      user = user_fixture()
      company = company_fixture(user)

      assert JobPostings.count_job_postings(%{company_id: company.id}) == 0
    end

    test "can count job_postings with search filter", %{job_posting: _job_posting} do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        title: "Healthcare Developer",
        description: "Medical software development role"
      })

      assert JobPostings.count_job_postings() == 2

      assert JobPostings.count_job_postings(%{search: "Healthcare"}) == 1
      assert JobPostings.count_job_postings(%{search: "Developer"}) == 1
      assert JobPostings.count_job_postings(%{search: "nonexistent"}) == 0
    end

    test "can count job_postings by employment_type", %{job_posting: _job_posting} do
      user = user_fixture()
      company = company_fixture(user)
      job_posting_fixture(company, %{employment_type: "Temporary Assignment"})

      assert JobPostings.count_job_postings(%{employment_type: "Permanent Position"}) == 1
      assert JobPostings.count_job_postings(%{employment_type: "Temporary Assignment"}) == 1
      assert JobPostings.count_job_postings() == 2
    end

    test "can count job_postings by remote_allowed", %{job_posting: _job_posting} do
      user = user_fixture()
      company = company_fixture(user)
      job_posting_fixture(company, %{remote_allowed: false})

      assert JobPostings.count_job_postings(%{remote_allowed: true}) == 1
      assert JobPostings.count_job_postings(%{remote_allowed: false}) == 1
      assert JobPostings.count_job_postings() == 2
    end

    test "can count job_postings by salary range" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{salary_min: 50_000, salary_max: 70_000})
      job_posting_fixture(company, %{salary_min: 80_000, salary_max: 100_000})
      job_posting_fixture(company, %{salary_min: 120_000, salary_max: 150_000})

      assert JobPostings.count_job_postings(%{salary_min: 75_000}) == 2
      assert JobPostings.count_job_postings(%{salary_min: 90_000}) == 2
      assert JobPostings.count_job_postings(%{salary_min: 125_000}) == 1

      assert JobPostings.count_job_postings(%{salary_max: 45_000}) == 1
      assert JobPostings.count_job_postings(%{salary_max: 75_000}) == 2
      assert JobPostings.count_job_postings(%{salary_max: 125_000}) == 4
    end

    test "can count job_postings by multiple filters" do
      user = user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        title: "Remote Healthcare Developer",
        employment_type: "Temporary Assignment",
        remote_allowed: true,
        salary_min: 80_000,
        salary_max: 120_000
      })

      job_posting_fixture(company, %{
        title: "On-site Developer",
        employment_type: "Permanent Position",
        remote_allowed: false,
        salary_min: 60_000,
        salary_max: 90_000
      })

      assert JobPostings.count_job_postings(%{
               search: "Healthcare",
               employment_type: "Temporary Assignment",
               remote_allowed: true
             }) == 1

      assert JobPostings.count_job_postings(%{
               employment_type: "Permanent Position",
               remote_allowed: false
             }) == 1

      assert JobPostings.count_job_postings(%{
               salary_min: 75_000,
               employment_type: "Temporary Assignment"
             }) == 1
    end

    test "count matches list_job_postings results", %{job_posting: _job_posting} do
      user = user_fixture()
      company = company_fixture(user)

      create_multiple_job_postings(company, 25)

      filters = %{company_id: company.id}
      job_list = JobPostings.list_job_postings(filters, 100)
      job_count = JobPostings.count_job_postings(filters)

      assert length(job_list) == job_count
      assert job_count == 25
    end
  end

  describe "get_job_posting!/1" do
    setup :create_job_posting

    test "returns the job_posting with given id", %{job_posting: job_posting} do
      result = JobPostings.get_job_posting!(job_posting.id)
      assert result.id == job_posting.id
      assert result.title == job_posting.title
      assert result.description == job_posting.description
    end

    test "raises error when job posting with id does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        JobPostings.get_job_posting!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_job_posting/2" do
    setup :create_job_posting

    test "with valid data creates a job_posting", %{company: company} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(company, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      assert job_posting.media_asset == nil
    end

    test "with nil media_data does not create a media asset", %{company: company} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title",
        media_data: nil
      }

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(company, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      refute job_posting.media_asset
    end

    test "with empty media_data does not create a media asset", %{company: company} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title",
        media_data: %{}
      }

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(company, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      refute job_posting.media_asset
    end

    test "with valid data including media_data creates a job_posting with media asset", %{
      company: company
    } do
      upload_id = Ecto.UUID.generate()

      valid_attrs = %{
        "currency" => "USD",
        "description" => "some description that is long enough",
        "employment_type" => "Permanent Position",
        "experience_level" => "Mid-level",
        "location" => "some location",
        "remote_allowed" => true,
        "salary_max" => 42,
        "salary_min" => 42,
        "title" => "some valid title",
        "media_data" => %{
          "file_name" => "test_file.jpg",
          "upload_id" => upload_id
        }
      }

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(company, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      assert job_posting.media_asset
      assert job_posting.media_asset.file_name == "test_file.jpg"
      assert job_posting.media_asset.upload_id == upload_id
    end

    test "with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(company, @invalid_attrs)
    end

    test "with salary_min greater than salary_max returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 50,
        salary_min: 100,
        title: "some valid title"
      }

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(company, invalid_attrs)
    end

    test "with title too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "tiny"
      }

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(company, invalid_attrs)
    end

    test "with description too short returns error changeset", %{company: company} do
      invalid_attrs = %{
        currency: "USD",
        description: "too short",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(company, invalid_attrs)
    end

    test "broadcasts job_posting_created event when creating a new job posting", %{
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      Endpoint.subscribe(company_topic)

      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: "Permanent Position",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      {:ok, job_posting} = JobPostings.create_job_posting(company, valid_attrs)

      assert_receive %Broadcast{
        event: "job_posting_created",
        topic: ^company_topic,
        payload: %{job_posting: ^job_posting}
      }
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

      assert {:ok, %JobPosting{} = updated_job_posting} =
               JobPostings.update_job_posting(job_posting, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      assert updated_job_posting.remote_allowed == false
    end

    test "with valid data including media_data updates the job_posting and creates a media asset",
         %{job_posting: job_posting} do
      update_attrs = %{
        "description" => "some updated description that is long enough",
        "title" => "some updated valid title",
        "remote_allowed" => false,
        "media_data" => %{
          "file_name" => "updated_file.jpg"
        }
      }

      assert {:ok, %JobPosting{} = updated_job_posting} =
               JobPostings.update_job_posting(job_posting, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      assert updated_job_posting.remote_allowed == false
      assert updated_job_posting.media_asset.file_name == "updated_file.jpg"
    end

    test "with nil media_data does not create or update a media asset", %{
      job_posting: job_posting
    } do
      update_attrs = %{
        "description" => "some updated description that is long enough",
        "title" => "some updated valid title",
        "media_data" => nil
      }

      assert {:ok, %JobPosting{} = updated_job_posting} =
               JobPostings.update_job_posting(job_posting, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      refute updated_job_posting.media_asset
    end

    test "with empty media_data does not create or update a media asset", %{
      job_posting: job_posting
    } do
      update_attrs = %{
        "description" => "some updated description that is long enough",
        "title" => "some updated valid title",
        "media_data" => %{}
      }

      assert {:ok, %JobPosting{} = updated_job_posting} =
               JobPostings.update_job_posting(job_posting, update_attrs)

      assert updated_job_posting.description == "some updated description that is long enough"
      assert updated_job_posting.title == "some updated valid title"
      refute updated_job_posting.media_asset
    end

    test "with valid data updates existing media asset when present", %{job_posting: job_posting} do
      upload_id = Ecto.UUID.generate()

      initial_media_attrs = %{
        "media_data" => %{
          "file_name" => "initial_file.jpg",
          "upload_id" => upload_id
        }
      }

      {:ok, job_posting_with_media} =
        JobPostings.update_job_posting(job_posting, initial_media_attrs)

      assert job_posting_with_media.media_asset.file_name == "initial_file.jpg"

      update_attrs = %{
        "description" => "some updated description that is long enough",
        "media_data" => %{
          "file_name" => "updated_file.jpg",
          "upload_id" => upload_id
        }
      }

      assert {:ok, %JobPosting{} = updated_job_posting} =
               JobPostings.update_job_posting(job_posting_with_media, update_attrs)

      assert updated_job_posting.media_asset
      assert updated_job_posting.media_asset.file_name == "updated_file.jpg"
      assert updated_job_posting.media_asset.upload_id == upload_id
    end

    test "with invalid data returns error changeset", %{job_posting: job_posting} do
      assert {:error, %Ecto.Changeset{}} =
               JobPostings.update_job_posting(job_posting, @invalid_attrs)
    end

    test "broadcasts job_posting_updated event when updating a job posting", %{
      job_posting: job_posting,
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      Endpoint.subscribe(company_topic)

      update_attrs = %{
        description: "some updated description that is long enough",
        title: "some updated valid title",
        remote_allowed: false
      }

      {:ok, updated_job_posting} = JobPostings.update_job_posting(job_posting, update_attrs)

      assert_receive %Broadcast{
        event: "job_posting_updated",
        topic: ^company_topic,
        payload: %{job_posting: ^updated_job_posting}
      }
    end
  end

  describe "delete_job_posting/1" do
    setup :create_job_posting

    test "deletes the job_posting", %{job_posting: job_posting} do
      assert {:ok, %JobPosting{}} = JobPostings.delete_job_posting(job_posting)
      assert_raise Ecto.NoResultsError, fn -> JobPostings.get_job_posting!(job_posting.id) end
    end

    test "broadcasts job_posting_deleted event when deleting a job posting", %{
      job_posting: job_posting,
      company: company
    } do
      company_topic = "job_posting:company:#{company.id}"
      Endpoint.subscribe(company_topic)

      job_posting = Repo.preload(job_posting, :company)

      {:ok, deleted_job_posting} = JobPostings.delete_job_posting(job_posting)

      assert_receive %Broadcast{
        event: "job_posting_deleted",
        topic: ^company_topic,
        payload: %{job_posting: ^deleted_job_posting}
      }
    end

    test "returns error when job posting does not exist" do
      non_existent_id = Ecto.UUID.generate()

      job_posting = %JobPosting{id: non_existent_id}

      assert_raise Ecto.StaleEntryError, fn ->
        JobPostings.delete_job_posting(job_posting)
      end
    end
  end

  describe "company_jobs_count/1" do
    test "returns the correct count of job postings for a company" do
      user = user_fixture()
      company = company_fixture(user)

      assert JobPostings.company_jobs_count(company.id) == 0

      create_multiple_job_postings(company, 3)
      assert JobPostings.company_jobs_count(company.id) == 3

      user2 = user_fixture(%{email: "another@example.com"})
      company2 = company_fixture(user2)
      create_multiple_job_postings(company2, 2)

      assert JobPostings.company_jobs_count(company.id) == 3
      assert JobPostings.company_jobs_count(company2.id) == 2
    end

    test "returns zero for company with no job postings" do
      user = user_fixture()
      company = company_fixture(user)

      assert JobPostings.company_jobs_count(company.id) == 0
    end

    test "returns zero for non-existent company ID" do
      non_existent_id = Ecto.UUID.generate()
      assert JobPostings.company_jobs_count(non_existent_id) == 0
    end
  end

  describe "change_job_posting/1" do
    setup :create_job_posting

    test "returns a job_posting changeset", %{job_posting: job_posting} do
      assert %Ecto.Changeset{} = JobPostings.change_job_posting(job_posting)
    end

    test "returns a job_posting changeset with errors when data is invalid", %{
      job_posting: job_posting
    } do
      changeset = JobPostings.change_job_posting(job_posting, @invalid_attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
      assert errors_on(changeset)[:title] == ["can't be blank"]
    end
  end

  describe "JobPosting.changeset/2 validations" do
    test "validates title length" do
      changeset_1 =
        JobPosting.changeset(%JobPosting{}, %{
          title: "abc",
          description: "Valid description that is long enough"
        })

      refute changeset_1.valid?
      assert "should be at least 5 character(s)" in errors_on(changeset_1).title

      long_title = String.duplicate("a", 260)

      changeset_2 =
        JobPosting.changeset(%JobPosting{}, %{
          title: long_title,
          description: "Valid description that is long enough"
        })

      refute changeset_2.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset_2).title
    end

    test "validates description length" do
      changeset =
        JobPosting.changeset(%JobPosting{}, %{title: "Valid Title", description: "short"})

      refute changeset.valid?
      assert "should be at least 10 character(s)" in errors_on(changeset).description
    end

    test "validates salary range" do
      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: "Valid description that is long enough",
          salary_min: 100_000,
          salary_max: 50_000
        })

      refute changeset.valid?
      assert "must be less than or equal to salary maximum" in errors_on(changeset).salary_min
    end

    test "validates salary numbers are non-negative" do
      changeset_1 =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: "Valid description that is long enough",
          salary_min: -1000
        })

      refute changeset_1.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset_1).salary_min

      changeset_2 =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: "Valid description that is long enough",
          salary_max: -5000
        })

      refute changeset_2.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset_2).salary_max
    end
  end
end
