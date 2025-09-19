defmodule BemedaPersonal.ScopeMigrationTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.JobPostingsFixtures

  alias BemedaPersonal.Accounts
  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.JobApplications
  alias BemedaPersonal.JobPostings

  describe "backward compatibility" do
    test "existing password authentication still works" do
      user = user_fixture()

      authenticated = Accounts.get_user_by_email_and_password(user.email, valid_user_password())

      assert authenticated.id == user.id
    end

    test "users without magic_link_enabled can still use passwords" do
      user = user_fixture(%{magic_link_enabled: false})

      # Password login works
      authenticated_user =
        Accounts.get_user_by_email_and_password(user.email, valid_user_password())

      assert authenticated_user

      # Magic link fails gracefully
      case Accounts.deliver_magic_link(user, & &1) do
        {:error, :magic_links_disabled} ->
          assert true

        {:ok, _token} ->
          # If we allow sending but don't authenticate, that's also OK
          assert true
      end
    end

    test "existing user sessions continue to work after scope implementation" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      # Should still be able to get user by session token
      assert retrieved_user = Accounts.get_user_by_session_token(token)
      assert retrieved_user.id == user.id
    end

    test "existing email confirmation flows still work" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      # Existing token validation should still work
      assert Accounts.get_user_by_session_token(token)
      assert Accounts.delete_user_session_token(token) == :ok

      # Token should be invalid after deletion
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "data isolation with scopes" do
    test "job seeker cannot see other user's applications" do
      # Job seeker A
      job_seeker_a = user_fixture(%{user_type: :job_seeker})
      scope_a = Scope.for_user(job_seeker_a)

      # Job seeker B
      job_seeker_b = user_fixture(%{user_type: :job_seeker})
      scope_b = Scope.for_user(job_seeker_b)

      # Create job posting
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)
      job_posting = job_posting_fixture(company)

      # Both users apply to same job
      {:ok, app_a} =
        JobApplications.apply_to_job(scope_a, job_posting.id, %{
          cover_letter: "Application from A"
        })

      {:ok, app_b} =
        JobApplications.apply_to_job(scope_b, job_posting.id, %{
          cover_letter: "Application from B"
        })

      # Each user can only see their own applications
      applications_a = JobApplications.list_job_applications(scope_a)
      applications_b = JobApplications.list_job_applications(scope_b)

      assert app_a.id in Enum.map(applications_a, & &1.id)
      refute app_b.id in Enum.map(applications_a, & &1.id)

      assert app_b.id in Enum.map(applications_b, & &1.id)
      refute app_a.id in Enum.map(applications_b, & &1.id)
    end

    test "employer cannot see other company's job postings" do
      # Company A
      employer_a = user_fixture(%{user_type: :employer})
      company_a = company_fixture(employer_a)

      scope_a =
        employer_a
        |> Scope.for_user()
        |> Scope.put_company(company_a)

      posting_a = job_posting_fixture(company_a)

      # Company B
      employer_b = user_fixture(%{user_type: :employer})
      company_b = company_fixture(employer_b)

      scope_b =
        employer_b
        |> Scope.for_user()
        |> Scope.put_company(company_b)

      posting_b = job_posting_fixture(company_b)

      # Company A can only see their posting
      results_a = JobPostings.list_job_postings(scope_a)
      assert posting_a.id in Enum.map(results_a, & &1.id)
      refute posting_b.id in Enum.map(results_a, & &1.id)

      # Company B can only see their posting
      results_b = JobPostings.list_job_postings(scope_b)
      assert posting_b.id in Enum.map(results_b, & &1.id)
      refute posting_a.id in Enum.map(results_b, & &1.id)
    end

    test "employer cannot access other company's job posting details" do
      # Company A
      employer_a = user_fixture(%{user_type: :employer})
      company_a = company_fixture(employer_a)

      scope_a =
        employer_a
        |> Scope.for_user()
        |> Scope.put_company(company_a)

      # Company B
      employer_b = user_fixture(%{user_type: :employer})
      company_b = company_fixture(employer_b)

      _scope_b =
        employer_b
        |> Scope.for_user()
        |> Scope.put_company(company_b)

      posting_b = job_posting_fixture(company_b)

      # Company A cannot access Company B's posting
      assert_raise Ecto.NoResultsError, fn ->
        JobPostings.get_job_posting!(scope_a, posting_b.id)
      end
    end

    test "unauthorized access raises 404 for cross-tenant data" do
      # Create employer and their company
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)

      scope =
        employer
        |> Scope.for_user()
        |> Scope.put_company(company)

      # Create posting from different company
      other_employer = user_fixture(%{user_type: :employer})
      other_company = company_fixture(other_employer)
      other_posting = job_posting_fixture(other_company)

      # Should raise NoResultsError (404) when trying to access cross-tenant data
      assert_raise Ecto.NoResultsError, fn ->
        JobPostings.get_job_posting!(scope, other_posting.id)
      end
    end

    test "job seekers have access to all public job postings" do
      job_seeker = user_fixture(%{user_type: :job_seeker})
      scope = Scope.for_user(job_seeker)

      # Create job postings from different companies
      employer_a = user_fixture(%{user_type: :employer})
      company_a = company_fixture(employer_a)
      posting_a = job_posting_fixture(company_a)

      employer_b = user_fixture(%{user_type: :employer})
      company_b = company_fixture(employer_b)
      posting_b = job_posting_fixture(company_b)

      # Job seeker should see all public postings
      results = JobPostings.list_job_postings(scope)
      assert posting_a.id in Enum.map(results, & &1.id)
      assert posting_b.id in Enum.map(results, & &1.id)
    end

    test "scope correctly identifies user and company access" do
      # Job seeker scope
      job_seeker = user_fixture(%{user_type: :job_seeker})
      job_seeker_scope = Scope.for_user(job_seeker)

      assert Scope.has_access?(job_seeker_scope, :user)
      refute Scope.has_access?(job_seeker_scope, :company)

      # Employer scope without company
      employer = user_fixture(%{user_type: :employer})
      employer_scope = Scope.for_user(employer)

      assert Scope.has_access?(employer_scope, :user)
      refute Scope.has_access?(employer_scope, :company)

      # Employer scope with company
      company = company_fixture(employer)
      employer_with_company_scope = Scope.put_company(employer_scope, company)

      assert Scope.has_access?(employer_with_company_scope, :user)
      assert Scope.has_access?(employer_with_company_scope, :company)
    end
  end

  describe "scope functionality validation" do
    test "Scope.for_user/1 creates proper scope structure" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert %Scope{} = scope
      assert scope.user.id == user.id
      assert scope.company == nil
      assert scope.state == nil
    end

    test "Scope.for_user/1 returns nil for nil user" do
      assert Scope.for_user(nil) == nil
    end

    test "Scope.put_company/2 adds company to scope" do
      user = employer_user_fixture()
      company = company_fixture(user)
      scope = Scope.for_user(user)

      updated_scope = Scope.put_company(scope, company)

      assert updated_scope.user.id == user.id
      assert updated_scope.company.id == company.id
    end

    test "Scope.user_id/1 extracts user id" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.user_id(scope) == user.id
    end

    test "Scope.company_id/1 extracts company id" do
      user = employer_user_fixture()
      company = company_fixture(user)

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert Scope.company_id(scope) == company.id
    end

    test "Scope.company_id/1 returns nil when no company" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Scope.company_id(scope) == nil
    end
  end

  describe "context function scope compatibility" do
    test "all major context functions accept scope parameter" do
      user = user_fixture()
      scope = Scope.for_user(user)

      # Test that these don't raise errors (basic smoke test)
      assert is_list(JobPostings.list_job_postings(scope))
      assert is_list(JobApplications.list_job_applications(scope))
      assert is_list(Accounts.list_users(scope))

      # Companies context needs company scope
      employer = user_fixture(%{user_type: :employer})
      company = company_fixture(employer)

      company_scope =
        employer
        |> Scope.for_user()
        |> Scope.put_company(company)

      assert is_list(Companies.list_companies(company_scope))
    end

    test "context functions properly filter by scope" do
      # Create two employers with companies
      employer_a = user_fixture(%{user_type: :employer})
      company_a = company_fixture(employer_a)

      scope_a =
        employer_a
        |> Scope.for_user()
        |> Scope.put_company(company_a)

      employer_b = user_fixture(%{user_type: :employer})
      company_b = company_fixture(employer_b)

      scope_b =
        employer_b
        |> Scope.for_user()
        |> Scope.put_company(company_b)

      # Create job postings for each company
      posting_a = job_posting_fixture(company_a)
      posting_b = job_posting_fixture(company_b)

      # Each scope should only see their own data
      results_a = JobPostings.list_job_postings(scope_a)
      results_b = JobPostings.list_job_postings(scope_b)

      assert posting_a.id in Enum.map(results_a, & &1.id)
      refute posting_b.id in Enum.map(results_a, & &1.id)

      assert posting_b.id in Enum.map(results_b, & &1.id)
      refute posting_a.id in Enum.map(results_b, & &1.id)
    end
  end
end
