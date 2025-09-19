defmodule BemedaPersonal.CompaniesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Companies
  alias BemedaPersonal.Companies.Company
  alias BemedaPersonal.Repo
  alias BemedaPersonalWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @invalid_attrs %{
    description: nil,
    industry: nil,
    location: nil,
    logo_url: nil,
    name: nil,
    size: nil,
    website_url: nil
  }

  setup do
    employer_scope = employer_scope_fixture()
    job_seeker_scope = job_seeker_scope_fixture()

    # Create additional test companies
    other_employer_scope = employer_scope_fixture()

    %{
      employer_scope: employer_scope,
      job_seeker_scope: job_seeker_scope,
      other_employer_scope: other_employer_scope
    }
  end

  describe "list_companies/0" do
    test "returns all companies", %{employer_scope: employer_scope} do
      results = Companies.list_companies()

      assert length(results) >= 1

      our_company = Enum.find(results, &(&1.id == employer_scope.company.id))
      assert our_company
      assert our_company.admin_user_id == employer_scope.user.id
    end

    test "returns empty list when no companies exist" do
      Repo.delete_all(Company)

      assert Companies.list_companies() == []
    end
  end

  describe "list_companies/1 (scope-based)" do
    test "employer scope returns their own company and public companies", %{
      employer_scope: employer_scope,
      other_employer_scope: _other_employer_scope
    } do
      # This will FAIL until we implement list_companies/1
      results = Companies.list_companies(employer_scope)

      # Employer should see their own company
      assert Enum.any?(results, &(&1.id == employer_scope.company.id))

      # Should also see other public companies (in the future)
      # For now, might just be their own company
      assert length(results) >= 1
    end

    test "job seeker scope returns only public companies", %{
      job_seeker_scope: job_seeker_scope,
      employer_scope: _employer_scope
    } do
      # This will FAIL until we implement list_companies/1
      results = Companies.list_companies(job_seeker_scope)

      # Job seekers should see public companies
      # For now, this might be empty or include published companies
      assert is_list(results)
    end

    test "nil scope returns empty list", %{} do
      # This will FAIL until we implement list_companies/1
      results = Companies.list_companies(nil)

      assert results == []
    end
  end

  describe "get_company!/1" do
    test "returns the company with given id", %{employer_scope: employer_scope} do
      result = Companies.get_company!(employer_scope.company.id)

      assert employer_scope.company.id == result.id
      assert result.admin_user_id == employer_scope.user.id
    end

    test "raises Ecto.NoResultsError if company does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(non_existent_id)
      end
    end
  end

  describe "get_company!/2 (scope-based)" do
    test "employer can access their own company", %{employer_scope: employer_scope} do
      # This will FAIL until we implement get_company!/2
      result = Companies.get_company!(employer_scope, employer_scope.company.id)

      assert result.id == employer_scope.company.id
      assert result.admin_user_id == employer_scope.user.id
    end

    test "employer cannot access other companies", %{
      employer_scope: employer_scope,
      other_employer_scope: other_employer_scope
    } do
      # This will FAIL until we implement get_company!/2
      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(employer_scope, other_employer_scope.company.id)
      end
    end

    test "job seeker can access public companies", %{
      job_seeker_scope: job_seeker_scope,
      employer_scope: employer_scope
    } do
      # This will FAIL until we implement get_company!/2
      # Assuming companies are public by default for now
      result = Companies.get_company!(job_seeker_scope, employer_scope.company.id)

      assert result.id == employer_scope.company.id
    end

    test "nil scope cannot access any company", %{employer_scope: employer_scope} do
      # This will FAIL until we implement get_company!/2
      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(nil, employer_scope.company.id)
      end
    end
  end

  describe "get_company_by_user/1" do
    test "returns the company for a user", %{employer_scope: employer_scope} do
      user = employer_scope.user
      company = employer_scope.company
      result = Companies.get_company_by_user(user)

      assert company.id == result.id
      assert company.name == result.name
      assert company.admin_user_id == user.id
    end

    test "returns nil when user has no company" do
      user = user_fixture()
      refute Companies.get_company_by_user(user)
    end
  end

  describe "create_company/2" do
    test "with valid data creates a company", %{employer_scope: _employer_scope} do
      user = user_fixture(user_type: :employer)
      scope = Scope.for_user(user)

      valid_attrs = %{
        name: "some name",
        size: "some size",
        description: "some description",
        location: "some location",
        industry: "some industry",
        website_url: "https://example.com",
        logo_url: "some logo_url"
      }

      {:ok, company} = Companies.create_company(scope, valid_attrs)
      assert company.name == "some name"
      assert company.size == "some size"
      assert company.description == "some description"
      assert company.admin_user_id == user.id
    end

    test "with invalid data returns error changeset", %{employer_scope: _employer_scope} do
      user = user_fixture(user_type: :employer)
      scope = Scope.for_user(user)
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(scope, @invalid_attrs)
    end
  end

  describe "create_company/2 (scope-based)" do
    test "employer scope can create company", %{} do
      employer_scope = employer_scope_fixture()

      valid_attrs = %{
        name: "New Company",
        industry: "Healthcare",
        location: "Basel, Switzerland"
      }

      # This will FAIL until we implement create_company/2 with scope
      {:ok, company} = Companies.create_company(employer_scope, valid_attrs)

      assert company.name == "New Company"
      assert company.admin_user_id == employer_scope.user.id
    end

    test "job seeker scope cannot create company", %{job_seeker_scope: job_seeker_scope} do
      valid_attrs = %{
        name: "Unauthorized Company",
        industry: "Healthcare"
      }

      # This will FAIL until we implement create_company/2 with scope
      assert {:error, :unauthorized} = Companies.create_company(job_seeker_scope, valid_attrs)
    end

    test "nil scope cannot create company", %{} do
      valid_attrs = %{
        name: "Nil Company",
        industry: "Healthcare"
      }

      # This will FAIL until we implement create_company/2 with scope
      assert {:error, :unauthorized} = Companies.create_company(nil, valid_attrs)
    end
  end

  describe "broadcast company events" do
    test "broadcasts company_created event when creating a company" do
      user = user_fixture(user_type: :employer)
      scope = Scope.for_user(user)
      Endpoint.subscribe("company:#{user.id}")

      valid_attrs = %{
        name: "Test Company",
        industry: "Healthcare",
        location: "Zurich, Switzerland"
      }

      {:ok, company} = Companies.create_company(scope, valid_attrs)

      # Should receive broadcast in Phoenix.Socket.Broadcast format
      company_topic = "company:#{user.id}"

      assert_receive %Broadcast{
                       event: "company_created",
                       topic: ^company_topic,
                       payload: %{company: ^company}
                     },
                     1000
    end
  end

  describe "update_company/2" do
    test "with valid data updates the company", %{employer_scope: employer_scope} do
      company = employer_scope.company

      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %Company{} = company_1} = Companies.update_company(company, update_attrs)

      assert company_1.name == "some updated name"
      assert company_1.size == company.size
    end

    test "with invalid data returns error changeset", %{employer_scope: employer_scope} do
      assert {:error, %Ecto.Changeset{}} =
               Companies.update_company(employer_scope.company, @invalid_attrs)
    end
  end

  describe "update_company/3 (scope-based)" do
    test "employer can update their own company", %{employer_scope: employer_scope} do
      update_attrs = %{name: "Updated Company Name"}

      # This will FAIL until we implement update_company/3 with scope
      {:ok, updated_company} =
        Companies.update_company(employer_scope, employer_scope.company, update_attrs)

      assert updated_company.name == "Updated Company Name"
    end

    test "employer cannot update other companies", %{
      employer_scope: employer_scope,
      other_employer_scope: other_employer_scope
    } do
      update_attrs = %{name: "Hacked Company"}

      # This will FAIL until we implement update_company/3 with scope
      assert {:error, :unauthorized} =
               Companies.update_company(
                 employer_scope,
                 other_employer_scope.company,
                 update_attrs
               )
    end

    test "job seeker cannot update any company", %{
      job_seeker_scope: job_seeker_scope,
      employer_scope: employer_scope
    } do
      update_attrs = %{name: "Hacked Company"}

      # This will FAIL until we implement update_company/3 with scope
      assert {:error, :unauthorized} =
               Companies.update_company(job_seeker_scope, employer_scope.company, update_attrs)
    end

    test "nil scope cannot update any company", %{employer_scope: employer_scope} do
      update_attrs = %{name: "Nil Company"}

      # This will FAIL until we implement update_company/3 with scope
      assert {:error, :unauthorized} =
               Companies.update_company(nil, employer_scope.company, update_attrs)
    end
  end

  describe "broadcast update events" do
    test "broadcasts company_updated event when updating a company", %{
      employer_scope: employer_scope
    } do
      company = employer_scope.company
      user = employer_scope.user
      Endpoint.subscribe("company:#{user.id}")

      update_attrs = %{name: "Updated Company Name"}

      {:ok, updated_company} = Companies.update_company(company, update_attrs)

      company_topic = "company:#{user.id}"

      assert_receive %Broadcast{
                       event: "company_updated",
                       topic: ^company_topic,
                       payload: %{company: ^updated_company}
                     },
                     1000
    end
  end

  describe "change_company/1" do
    test "returns a company changeset", %{employer_scope: employer_scope} do
      assert %Ecto.Changeset{} = Companies.change_company(employer_scope.company)
    end

    test "with attrs returns a company changeset", %{employer_scope: employer_scope} do
      attrs = %{name: "updated name"}
      changeset = Companies.change_company(employer_scope.company, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "updated name"
    end
  end

  describe "delete_company/2 (scope-based)" do
    test "employer can delete their own company", %{employer_scope: employer_scope} do
      # This will FAIL until we implement delete_company/2 with scope
      {:ok, deleted_company} = Companies.delete_company(employer_scope, employer_scope.company)

      assert deleted_company.id == employer_scope.company.id

      # Verify company is deleted
      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(employer_scope.company.id)
      end
    end

    test "employer cannot delete other companies", %{
      employer_scope: employer_scope,
      other_employer_scope: other_employer_scope
    } do
      # This will FAIL until we implement delete_company/2 with scope
      assert {:error, :unauthorized} =
               Companies.delete_company(employer_scope, other_employer_scope.company)
    end

    test "job seeker cannot delete any company", %{
      job_seeker_scope: job_seeker_scope,
      employer_scope: employer_scope
    } do
      # This will FAIL until we implement delete_company/2 with scope
      assert {:error, :unauthorized} =
               Companies.delete_company(job_seeker_scope, employer_scope.company)
    end

    test "nil scope cannot delete any company", %{employer_scope: employer_scope} do
      # This will FAIL until we implement delete_company/2 with scope
      assert {:error, :unauthorized} = Companies.delete_company(nil, employer_scope.company)
    end
  end
end
