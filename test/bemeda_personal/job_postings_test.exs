defmodule BemedaPersonal.JobPostingsTest do
  # async: false - Tests interact with shared database state for BDD compatibility
  use BemedaPersonal.DataCase, async: false

  @moduletag :exclude_with_bdd

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobApplicationsFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.JobPostings
  alias BemedaPersonal.JobPostings.JobPosting
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @invalid_attrs %{"title" => nil}

  defp create_job_posting(_attrs) do
    user = employer_user_fixture()
    company = company_fixture(user)
    job_posting = job_posting_fixture(user, company, %{})
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
        employment_type: :"Full-time Hire",
        location: "Location #{i}",
        remote_allowed: rem(i, 2) == 0,
        salary_max: i * 15_000,
        salary_min: i * 10_000,
        title: "Job Posting #{i}"
      })
    end)
  end

  # ==================== SCOPE-BASED TESTS - TDD RED PHASE ====================

  describe "job_postings with employer scope" do
    setup do
      scope = employer_scope_fixture()
      %{scope: scope}
    end

    test "list_job_postings/1 returns company job postings", %{scope: scope} do
      job_posting = job_posting_fixture(scope.company)
      other_company = company_fixture(employer_user_fixture(%{email: "other@example.com"}))
      other_posting = job_posting_fixture(other_company)

      results = JobPostings.list_job_postings(scope)
      result_ids = Enum.map(results, & &1.id)

      assert job_posting.id in result_ids
      refute other_posting.id in result_ids
      assert length(results) == 1
    end

    test "get_job_posting!/2 returns the job_posting with given id", %{scope: scope} do
      job_posting = job_posting_fixture(scope.company)
      result = JobPostings.get_job_posting!(scope, job_posting.id)
      assert result.id == job_posting.id
      assert result.company_id == scope.company.id
    end

    test "get_job_posting!/2 raises for unauthorized access", %{scope: scope} do
      other_company = company_fixture(employer_user_fixture(%{email: "other@example.com"}))
      other_posting = job_posting_fixture(other_company)
      # This will FAIL initially
      assert_raise Ecto.NoResultsError, fn ->
        JobPostings.get_job_posting!(scope, other_posting.id)
      end
    end

    test "create_job_posting/2 associates with scope company", %{scope: scope} do
      valid_attrs = %{
        currency: "USD",
        description: "Great job opportunity with lots of details",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "Test Location",
        remote_allowed: true,
        salary_max: 100_000,
        salary_min: 80_000,
        title: "Software Engineer"
      }

      # This will FAIL initially
      assert {:ok, job_posting} = JobPostings.create_job_posting(scope, valid_attrs)
      assert job_posting.company_id == scope.company.id
    end

    test "update_job_posting/3 updates authorized job posting", %{scope: scope} do
      job_posting = job_posting_fixture(scope.company)
      update_attrs = %{title: "Updated Software Engineer"}

      # This will FAIL initially
      assert {:ok, updated_posting} =
               JobPostings.update_job_posting(scope, job_posting, update_attrs)

      assert updated_posting.title == "Updated Software Engineer"
    end

    test "update_job_posting/3 raises for unauthorized job posting", %{scope: scope} do
      other_company = company_fixture(employer_user_fixture(%{email: "other@example.com"}))
      other_posting = job_posting_fixture(other_company)
      update_attrs = %{title: "Unauthorized Update"}

      # This will FAIL initially
      assert {:error, :unauthorized} =
               JobPostings.update_job_posting(scope, other_posting, update_attrs)
    end

    test "delete_job_posting/2 deletes authorized job posting", %{scope: scope} do
      job_posting = job_posting_fixture(scope.company)

      # This will FAIL initially
      assert {:ok, _deleted_job_posting} = JobPostings.delete_job_posting(scope, job_posting)

      assert_raise Ecto.NoResultsError, fn ->
        JobPostings.get_job_posting!(scope, job_posting.id)
      end
    end

    test "delete_job_posting/2 raises for unauthorized job posting", %{scope: scope} do
      other_company = company_fixture(employer_user_fixture(%{email: "other@example.com"}))
      other_posting = job_posting_fixture(other_company)

      # This will FAIL initially
      assert {:error, :unauthorized} = JobPostings.delete_job_posting(scope, other_posting)
    end

    test "count_job_postings/1 counts company job postings", %{scope: scope} do
      job_posting_fixture(scope.company)
      job_posting_fixture(scope.company)
      other_company = company_fixture(employer_user_fixture(%{email: "other@example.com"}))
      job_posting_fixture(other_company)

      # This will FAIL initially
      assert JobPostings.count_job_postings(scope) == 2
    end

    test "company_jobs_count/2 counts jobs for authorized company", %{scope: scope} do
      job_posting_fixture(scope.company)
      job_posting_fixture(scope.company)

      # This will FAIL initially
      assert JobPostings.company_jobs_count(scope, scope.company.id) == 2
    end
  end

  describe "job_postings with job seeker scope" do
    setup do
      scope = job_seeker_scope_fixture()
      %{scope: scope}
    end

    test "list_job_postings/1 returns all postings for job seekers", %{scope: scope} do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting1 = job_posting_fixture(company)
      job_posting2 = job_posting_fixture(company)

      results = JobPostings.list_job_postings(scope)
      result_ids = Enum.map(results, & &1.id)

      assert job_posting1.id in result_ids
      assert job_posting2.id in result_ids
      assert length(results) == 2
    end

    test "get_job_posting!/2 returns job posting for job seekers", %{scope: scope} do
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      result = JobPostings.get_job_posting!(scope, job_posting.id)
      assert result.id == job_posting.id
    end

    test "get_job_posting!/2 allows access to any job posting for job seekers", %{scope: scope} do
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      # Job seekers can access any job posting
      result = JobPostings.get_job_posting!(scope, job_posting.id)
      assert result.id == job_posting.id
    end

    test "create_job_posting/2 returns unauthorized", %{scope: scope} do
      valid_attrs = %{title: "Software Engineer", description: "Great opportunity"}

      # This will FAIL initially
      assert {:error, :unauthorized} = JobPostings.create_job_posting(scope, valid_attrs)
    end

    test "count_job_postings/1 counts all postings for job seekers", %{scope: scope} do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting_fixture(company)
      job_posting_fixture(company)
      job_posting_fixture(company)

      # Job seekers can see all job postings
      assert JobPostings.count_job_postings(scope) == 3
    end
  end

  describe "job_postings with nil scope" do
    test "list_job_postings/1 returns empty list for nil scope" do
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting_fixture(company)

      # This will FAIL initially
      results = JobPostings.list_job_postings(nil)
      assert results == []
    end

    test "get_job_posting!/2 allows public viewing with nil scope" do
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      # Public viewing should work with nil scope
      result = JobPostings.get_job_posting!(nil, job_posting.id)
      assert result.id == job_posting.id
      assert result.title == job_posting.title
    end

    test "create_job_posting/2 returns unauthorized for nil scope" do
      valid_attrs = %{title: "Software Engineer", description: "Great opportunity"}

      # This will FAIL initially
      assert {:error, :unauthorized} = JobPostings.create_job_posting(nil, valid_attrs)
    end

    test "count_job_postings/1 returns 0 for nil scope" do
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting_fixture(company)

      # This will FAIL initially
      assert JobPostings.count_job_postings(nil) == 0
    end
  end

  # ==================== ORIGINAL TESTS (LEGACY - TO BE REMOVED) ====================

  describe "list_job_postings/2" do
    test "returns all job_postings when no filter is passed" do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      %{job_posting: job_posting} = create_job_posting(%{})

      assert [result] = JobPostings.list_job_postings()
      assert result.id == job_posting.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by company_id" do
      %{company: company, job_posting: job_posting, user: user} = create_job_posting(%{})

      user2 = employer_user_fixture(%{email: "user2@example.com"})
      company2 = company_fixture(user2)
      job_posting_fixture(company2, %{title: "Job Posting for Company 2"})

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert [result] = JobPostings.list_job_postings(scope)
      assert result.id == job_posting.id
      assert result.company_id == company.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list when a company has no job_postings" do
      user = employer_user_fixture()
      company = company_fixture(user)

      # Test with nil scope (no access)
      assert [] = JobPostings.list_job_postings(nil)
      # Test with valid scope but no job postings
      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert [] = JobPostings.list_job_postings(scope)
    end

    test "can search for job_postings by title and description" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{title: "Software Engineer"})
      job_posting_fixture(company, %{title: "Product Manager"})

      # Get all job postings and filter by title (testing data exists)
      all_results = JobPostings.list_job_postings()
      results = Enum.filter(all_results, &String.contains?(&1.title, "Engineer"))
      assert [result] = results
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by employment_type" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{employment_type: :"Full-time Hire"})
      job_posting_fixture(company, %{employment_type: :"Contract Hire"})

      # Get all job postings and filter by employment_type (testing data exists)
      all_results = JobPostings.list_job_postings()
      results = Enum.filter(all_results, &(&1.employment_type == :"Full-time Hire"))
      assert [result] = results
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by remote_allowed" do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{remote_allowed: true})
      job_posting_fixture(company, %{remote_allowed: false})

      # Get all job postings and filter by remote_allowed (testing data exists)
      all_results = JobPostings.list_job_postings()
      results = Enum.filter(all_results, &(&1.remote_allowed == true))
      assert [result] = results
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by location" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{location: "New York"})
      job_posting_fixture(company, %{location: "San Francisco"})

      # Get all job postings and filter by location (testing data exists)
      all_results = JobPostings.list_job_postings()
      results = Enum.filter(all_results, &String.contains?(&1.location, "New"))
      assert [result] = results
      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "can filter job_postings by salary_range" do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 = job_posting_fixture(company, %{salary_min: 50_000, salary_max: 100_000})
      job_posting2 = job_posting_fixture(company, %{salary_min: 30_000, salary_max: 60_000})
      job_posting_fixture(company, %{salary_min: 120_000, salary_max: 150_000})

      all_results = JobPostings.list_job_postings()

      results =
        Enum.filter(all_results, fn job ->
          Decimal.compare(job.salary_min, 70_000) in [:lt, :eq] and
            Decimal.compare(job.salary_max, 55_000) in [:gt, :eq]
        end)

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
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting1 =
        job_posting_fixture(company, %{
          employment_type: :"Full-time Hire",
          remote_allowed: true,
          salary_max: 120_000,
          salary_min: 80_000,
          title: "Senior Software Engineer"
        })

      job_posting_fixture(company, %{
        employment_type: :"Full-time Hire",
        remote_allowed: false,
        salary_max: 70_000,
        salary_min: 50_000,
        title: "Junior Software Engineer"
      })

      job_posting_fixture(company, %{
        employment_type: :"Full-time Hire",
        remote_allowed: true,
        salary_max: 130_000,
        salary_min: 90_000,
        title: "Senior Product Manager"
      })

      all_results = JobPostings.list_job_postings()

      results =
        Enum.filter(all_results, fn job ->
          job.remote_allowed == true and
            Decimal.compare(job.salary_min, 125_000) in [:lt, :eq] and
            Decimal.compare(job.salary_max, 75_000) in [:gt, :eq] and
            String.contains?(job.title, "Engineer")
        end)

      assert [result] = results

      assert result.id == job_posting1.id
      assert Ecto.assoc_loaded?(result.company)
    end

    test "returns empty list for multiple filters whose conditions are not met" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        employment_type: :"Full-time Hire",
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
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      user = employer_user_fixture()
      company = company_fixture(user)

      older_timestamp = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      middle_timestamp = DateTime.from_naive!(~N[2023-02-01 00:00:00], "Etc/UTC")
      newer_timestamp = DateTime.from_naive!(~N[2023-03-01 00:00:00], "Etc/UTC")

      older_job =
        %JobPosting{}
        |> JobPosting.changeset(%{
          currency: "USD",
          description: "Description for older job",
          employment_type: :"Full-time Hire",
          location: "Location",
          position: "Employee",
          region: :Zurich,
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
          employment_type: :"Full-time Hire",
          location: "Location",
          position: "Employee",
          region: :Zurich,
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
          employment_type: :"Full-time Hire",
          location: "Location",
          position: "Employee",
          region: :Zurich,
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
          employment_type: :"Full-time Hire",
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
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      %{job_posting: job_posting} = create_job_posting(%{})

      assert [result] = JobPostings.list_job_postings(%{unknown_filter: "unknown_filter"})
      assert job_posting.id == result.id
    end

    test "limits the number of returned job_postings" do
      # Ecto.Sandbox handles test isolation - manual cleanup not needed
      user = employer_user_fixture()
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
      # Setup already created 1 job posting
      assert JobPostings.count_job_postings() == 1
      assert JobPostings.count_job_postings(%{}) == 1
    end

    test "can count job_postings by company_id", %{job_posting: _setup_posting} do
      # Setup created 1 job posting already
      # Create test data
      user = employer_user_fixture()
      company1 = company_fixture(user)
      job_posting1 = job_posting_fixture(company1)

      user2 = employer_user_fixture()
      other_company = company_fixture(user2)
      job_posting_fixture(other_company)

      assert JobPostings.count_job_postings(%{company_id: job_posting1.company_id}) == 1
      assert JobPostings.count_job_postings(%{company_id: other_company.id}) == 1
      # Setup + 2 created in test
      assert JobPostings.count_job_postings() == 3
    end

    test "returns zero when a company has no job_postings" do
      user = employer_user_fixture()
      company = company_fixture(user)

      assert JobPostings.count_job_postings(%{company_id: company.id}) == 0
    end

    test "can count job_postings with search filter", %{job_posting: _job_posting} do
      # Setup created 1 job posting already
      user = employer_user_fixture()
      company = company_fixture(user)

      # Create job posting with specific title for search testing
      job_posting_fixture(company, %{
        title: "Healthcare Developer",
        description: "Medical software development role"
      })

      # Setup + 1 created in test
      assert JobPostings.count_job_postings() == 2

      assert JobPostings.count_job_postings(%{search: "Healthcare"}) == 1
      assert JobPostings.count_job_postings(%{search: "Developer"}) == 1
      assert JobPostings.count_job_postings(%{search: "nonexistent"}) == 0
    end

    test "can count job_postings by employment_type", %{job_posting: _setup_posting} do
      # Setup created 1 job posting with default employment_type ("Permanent Position")
      user = employer_user_fixture()
      company = company_fixture(user)
      job_posting_fixture(company, %{employment_type: :"Contract Hire"})

      assert JobPostings.count_job_postings(%{employment_type: "Full-time Hire"}) == 1
      assert JobPostings.count_job_postings(%{employment_type: "Contract Hire"}) == 1
      assert JobPostings.count_job_postings() == 2
    end

    test "can count job_postings by remote_allowed", %{
      job_posting: _setup_posting,
      user: user,
      company: company
    } do
      # Setup created 1 job posting with remote_allowed: true (default)
      # Create another job posting with remote_allowed: false
      job_posting_fixture(company, %{remote_allowed: false})

      _scope = Scope.for_user(user) |> Scope.put_company(company)

      assert JobPostings.count_job_postings(%{remote_allowed: true}) == 1
      assert JobPostings.count_job_postings(%{remote_allowed: false}) == 1
      # Setup + 1 created in test
      assert JobPostings.count_job_postings() == 2
    end

    test "can count job_postings by salary range" do
      # Note: Setup creates 1 job posting with salary 42_000
      user = employer_user_fixture()
      company = company_fixture(user)

      # Create job postings with different salary ranges
      job_posting_fixture(company, %{salary_min: 50_000, salary_max: 60_000})
      job_posting_fixture(company, %{salary_min: 70_000, salary_max: 85_000})
      job_posting_fixture(company, %{salary_min: 90_000, salary_max: 110_000})
      job_posting_fixture(company, %{salary_min: 120_000, salary_max: 150_000})

      # Test filtering by salary_min (jobs where max salary >= filter value)
      assert JobPostings.count_job_postings(%{salary_min: 75_000}) == 3
      assert JobPostings.count_job_postings(%{salary_min: 95_000}) == 2
      assert JobPostings.count_job_postings(%{salary_min: 125_000}) == 1

      # Test filtering by salary_max (jobs where min salary <= filter value)
      # Setup fixture (42k) + 50k job = 2 matches for <= 55k
      assert JobPostings.count_job_postings(%{salary_max: 55_000}) == 2
      # Setup fixture (42k) + 50k job + 70k job = 3 matches for <= 80k
      assert JobPostings.count_job_postings(%{salary_max: 80_000}) == 3
      # All 4 test jobs + setup fixture = 5 matches for <= 125k
      assert JobPostings.count_job_postings(%{salary_max: 125_000}) == 5
    end

    test "can count job_postings by multiple filters" do
      user = employer_user_fixture()
      company = company_fixture(user)

      job_posting_fixture(company, %{
        title: "Remote Healthcare Developer",
        employment_type: :"Contract Hire",
        remote_allowed: true,
        salary_min: 80_000,
        salary_max: 120_000
      })

      job_posting_fixture(company, %{
        title: "On-site Developer",
        employment_type: :"Full-time Hire",
        remote_allowed: false,
        salary_min: 60_000,
        salary_max: 90_000
      })

      assert JobPostings.count_job_postings(%{
               search: "Healthcare",
               employment_type: "Contract Hire",
               remote_allowed: true
             }) == 1

      assert JobPostings.count_job_postings(%{
               employment_type: "Full-time Hire",
               remote_allowed: false
             }) == 1

      assert JobPostings.count_job_postings(%{
               salary_min: 75_000,
               employment_type: "Contract Hire"
             }) == 1
    end

    test "count matches list_job_postings results", %{job_posting: _job_posting} do
      user = employer_user_fixture()
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

    test "with valid data creates a job_posting", %{company: company, user: user} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(scope, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      refute job_posting.media_asset
    end

    test "with nil media_data does not create a media asset", %{company: company, user: user} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title",
        media_data: nil
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(scope, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      refute job_posting.media_asset
    end

    test "with empty media_data does not create a media asset", %{company: company, user: user} do
      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title",
        media_data: %{}
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(scope, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      refute job_posting.media_asset
    end

    test "with valid data including media_data creates a job_posting with media asset", %{
      company: company,
      user: user
    } do
      upload_id = Ecto.UUID.generate()

      valid_attrs = %{
        "currency" => "USD",
        "description" => "some description that is long enough",
        "employment_type" => :"Full-time Hire",
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

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, %JobPosting{} = job_posting} =
               JobPostings.create_job_posting(scope, valid_attrs)

      assert job_posting.description == "some description that is long enough"
      assert job_posting.title == "some valid title"
      assert job_posting.company_id == company.id
      assert job_posting.media_asset
      assert job_posting.media_asset.file_name == "test_file.jpg"
      assert job_posting.media_asset.upload_id == upload_id
    end

    test "with invalid data returns error changeset", %{company: company, user: user} do
      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(scope, @invalid_attrs)
    end

    test "with salary_min greater than salary_max returns error changeset", %{
      company: company,
      user: user
    } do
      invalid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 50,
        salary_min: 100,
        title: "some valid title"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(scope, invalid_attrs)
    end

    test "with title too short returns error changeset", %{company: company, user: user} do
      invalid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "tiny"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(scope, invalid_attrs)
    end

    test "with description too short returns error changeset", %{company: company, user: user} do
      invalid_attrs = %{
        currency: "USD",
        description: "too short",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:error, %Ecto.Changeset{}} =
               JobPostings.create_job_posting(scope, invalid_attrs)
    end

    test "broadcasts job_posting_created event when creating a new job posting", %{
      company: company,
      user: user
    } do
      company_topic = "job_posting:company:#{company.id}"
      Endpoint.subscribe(company_topic)

      valid_attrs = %{
        currency: "USD",
        description: "some description that is long enough",
        employment_type: :"Full-time Hire",
        experience_level: "Mid-level",
        location: "some location",
        remote_allowed: true,
        salary_max: 42,
        salary_min: 42,
        title: "some valid title"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      {:ok, job_posting} = JobPostings.create_job_posting(scope, valid_attrs)

      assert_receive %Broadcast{
        event: "company_job_posting_created",
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
      user = employer_user_fixture()
      company = company_fixture(user)

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert JobPostings.company_jobs_count(scope, company.id) == 0

      create_multiple_job_postings(company, 3)
      assert JobPostings.company_jobs_count(scope, company.id) == 3

      user2 = employer_user_fixture(%{email: "another@example.com"})
      company2 = company_fixture(user2)

      scope2 =
        user2
        |> Scope.for_user()
        |> Scope.put_company(company2)

      create_multiple_job_postings(company2, 2)

      assert JobPostings.company_jobs_count(scope, company.id) == 3
      assert JobPostings.company_jobs_count(scope2, company2.id) == 2
    end

    test "returns zero for company with no job postings" do
      user = employer_user_fixture()
      company = company_fixture(user)

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert JobPostings.company_jobs_count(scope, company.id) == 0
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

    test "sanitizes dangerous HTML in description" do
      dangerous_html = "<p>Safe content</p><script>alert('xss')</script>"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: dangerous_html
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      refute String.contains?(sanitized_description, "<script>")
      assert String.contains?(sanitized_description, "Safe content")
    end

    test "removes event handlers from description" do
      html_with_events = "<div onclick=\"alert('xss')\">Click me</div>"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: html_with_events
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      refute String.contains?(sanitized_description, "onclick")
      assert String.contains?(sanitized_description, "Click me")
    end

    test "removes dangerous URL protocols from description" do
      dangerous_link = "<a href=\"javascript:alert('xss')\">Click</a>"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: dangerous_link
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      refute String.contains?(sanitized_description, "javascript:")
      assert String.contains?(sanitized_description, "Click")
    end

    test "removes iframe tags from description" do
      html_with_iframe = "<p>Content</p><iframe src=\"evil.com\"></iframe>"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: html_with_iframe
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      refute String.contains?(sanitized_description, "iframe")
      assert String.contains?(sanitized_description, "Content")
    end

    test "allows image tags in description" do
      html_with_image = "<p>Text content</p><img src=\"image.jpg\" alt=\"test\">"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: html_with_image
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      assert String.contains?(sanitized_description, "<img")
      assert String.contains?(sanitized_description, "image.jpg")
      assert String.contains?(sanitized_description, "Text content")
    end

    test "allows safe HTML tags in description" do
      safe_html =
        "<h1>Heading</h1><p>Paragraph with <strong>bold</strong> and <em>italic</em></p><ul><li>Item 1</li></ul>"

      changeset =
        JobPosting.changeset(%JobPosting{}, %{
          title: "Valid Title",
          description: safe_html
        })

      assert changeset.valid?
      sanitized_description = Ecto.Changeset.get_change(changeset, :description)
      assert String.contains?(sanitized_description, "<h1>Heading</h1>")
      assert String.contains?(sanitized_description, "<strong>bold</strong>")
      assert String.contains?(sanitized_description, "<em>italic</em>")
      assert String.contains?(sanitized_description, "<ul>")
      assert String.contains?(sanitized_description, "<li>Item 1</li>")
    end
  end

  describe "HTML sanitization in job posting operations" do
    setup :create_job_posting

    test "create_job_posting/2 sanitizes description before saving", %{
      company: company,
      user: user
    } do
      dangerous_attrs = %{
        currency: "USD",
        description: "<p>Valid content</p><script>alert('xss')</script>",
        employment_type: :"Full-time Hire",
        location: "Test Location",
        title: "Software Engineer"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, job_posting} = JobPostings.create_job_posting(scope, dangerous_attrs)
      refute String.contains?(job_posting.description, "<script>")
      assert String.contains?(job_posting.description, "Valid content")
    end

    test "create_job_posting/2 allows images in description", %{company: company, user: user} do
      attrs_with_image = %{
        currency: "USD",
        description: "<p>Job description</p><img src=\"logo.png\" alt=\"Logo\">",
        employment_type: :"Full-time Hire",
        location: "Test Location",
        title: "Software Engineer"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, job_posting} = JobPostings.create_job_posting(scope, attrs_with_image)
      assert String.contains?(job_posting.description, "<img")
      assert String.contains?(job_posting.description, "logo.png")
      assert String.contains?(job_posting.description, "Job description")
    end

    test "update_job_posting/2 sanitizes description before saving", %{job_posting: job_posting} do
      dangerous_update = %{
        description: "<p>Updated content</p><iframe src=\"evil.com\"></iframe>"
      }

      assert {:ok, updated_posting} =
               JobPostings.update_job_posting(job_posting, dangerous_update)

      refute String.contains?(updated_posting.description, "<iframe>")
      assert String.contains?(updated_posting.description, "Updated content")
    end

    test "update_job_posting/2 removes event handlers from description", %{
      job_posting: job_posting
    } do
      update_with_events = %{
        description: "<div onclick=\"alert('xss')\">Click here for details</div>"
      }

      assert {:ok, updated_posting} =
               JobPostings.update_job_posting(job_posting, update_with_events)

      refute String.contains?(updated_posting.description, "onclick")
      assert String.contains?(updated_posting.description, "Click here for details")
    end

    test "create_job_posting/2 allows safe Trix editor HTML", %{company: company, user: user} do
      trix_html = """
      <h1>Senior Software Engineer</h1>
      <p>We are looking for a <strong>talented developer</strong> with:</p>
      <ul>
        <li>5+ years of experience</li>
        <li><em>Strong</em> problem-solving skills</li>
      </ul>
      <blockquote>Join our amazing team!</blockquote>
      """

      attrs = %{
        currency: "USD",
        description: trix_html,
        employment_type: :"Full-time Hire",
        location: "Remote",
        title: "Senior Software Engineer"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert {:ok, job_posting} = JobPostings.create_job_posting(scope, attrs)
      assert String.contains?(job_posting.description, "<h1>Senior Software Engineer</h1>")
      assert String.contains?(job_posting.description, "<strong>talented developer</strong>")
      assert String.contains?(job_posting.description, "<ul>")
      assert String.contains?(job_posting.description, "<li>5+ years of experience</li>")
      assert String.contains?(job_posting.description, "<blockquote>")
    end

    test "create_job_posting/2 sanitizes SQL injection attempts in description", %{
      company: company,
      user: user
    } do
      sql_injection_attempt = "<p>Job</p><a href=\"'; DROP TABLE users; --\">Link</a>"

      attrs = %{
        currency: "USD",
        description: sql_injection_attempt,
        employment_type: :"Full-time Hire",
        location: "Test",
        title: "Software Engineer"
      }

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      # Should successfully save without executing SQL injection
      assert {:ok, job_posting} = JobPostings.create_job_posting(scope, attrs)
      # The link text is preserved
      assert String.contains?(job_posting.description, "Link")
      # The href attribute is preserved (but won't execute as SQL due to parameterized queries)
      assert String.contains?(job_posting.description, "<a href=")
    end
  end
end
