defmodule BemedaPersonal.CompaniesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.CompaniesFixtures
  import BemedaPersonal.AccountsFixtures

  alias BemedaPersonal.Companies

  describe "companies" do
    alias BemedaPersonal.Companies.Company

    @invalid_attrs %{
      name: nil,
      size: nil,
      description: nil,
      location: nil,
      industry: nil,
      website_url: nil,
      logo_url: nil
    }

    test "list_companies/0 returns all companies" do
      company = company_fixture()
      # Get the company without preloaded associations for comparison
      db_company = List.first(Companies.list_companies())

      assert db_company.id == company.id
      assert db_company.name == company.name
      assert db_company.description == company.description
      assert db_company.industry == company.industry
      assert db_company.location == company.location
      assert db_company.logo_url == company.logo_url
      assert db_company.size == company.size
      assert db_company.website_url == company.website_url
      assert db_company.admin_user_id == company.admin_user_id
    end

    test "get_company!/1 returns the company with given id" do
      company = company_fixture()
      # Get the company without preloaded associations for comparison
      db_company = Companies.get_company!(company.id)

      assert db_company.id == company.id
      assert db_company.name == company.name
      assert db_company.description == company.description
      assert db_company.industry == company.industry
      assert db_company.location == company.location
      assert db_company.logo_url == company.logo_url
      assert db_company.size == company.size
      assert db_company.website_url == company.website_url
      assert db_company.admin_user_id == company.admin_user_id
    end

    test "get_company_by_user/1 returns the company for a user" do
      user = user_fixture()

      {:ok, company} =
        Companies.create_company(user, %{
          name: "some name",
          size: "some size",
          description: "some description",
          location: "some location",
          industry: "some industry",
          website_url: "some website_url",
          logo_url: "some logo_url"
        })

      db_company = Companies.get_company_by_user(user)

      assert db_company.id == company.id
      assert db_company.name == company.name
      assert db_company.admin_user_id == user.id
    end

    test "get_company_by_user/1 returns nil when user has no company" do
      user = user_fixture()

      assert Companies.get_company_by_user(user) == nil
    end

    test "create_company/2 with valid data creates a company" do
      user = user_fixture()

      valid_attrs = %{
        name: "some name",
        size: "some size",
        description: "some description",
        location: "some location",
        industry: "some industry",
        website_url: "some website_url",
        logo_url: "some logo_url"
      }

      assert {:ok, %Company{} = company} = Companies.create_company(user, valid_attrs)
      assert company.name == "some name"
      assert company.size == "some size"
      assert company.description == "some description"
      assert company.location == "some location"
      assert company.industry == "some industry"
      assert company.website_url == "some website_url"
      assert company.logo_url == "some logo_url"
      assert company.admin_user_id == user.id
    end

    test "create_company/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(user, @invalid_attrs)
    end

    test "update_company/2 with valid data updates the company" do
      company = company_fixture()

      update_attrs = %{
        name: "some updated name",
        size: "some updated size",
        description: "some updated description",
        location: "some updated location",
        industry: "some updated industry",
        website_url: "some updated website_url",
        logo_url: "some updated logo_url"
      }

      assert {:ok, %Company{} = company} =
               Companies.update_company(company, update_attrs)

      assert company.name == "some updated name"
      assert company.size == "some updated size"
      assert company.description == "some updated description"
      assert company.location == "some updated location"
      assert company.industry == "some updated industry"
      assert company.website_url == "some updated website_url"
      assert company.logo_url == "some updated logo_url"
    end

    test "update_company/2 with invalid data returns error changeset" do
      company = company_fixture()
      assert {:error, %Ecto.Changeset{}} = Companies.update_company(company, @invalid_attrs)

      # Get the company without preloaded associations for comparison
      db_company = Companies.get_company!(company.id)

      assert db_company.id == company.id
      assert db_company.name == company.name
      assert db_company.description == company.description
      assert db_company.industry == company.industry
      assert db_company.location == company.location
      assert db_company.logo_url == company.logo_url
      assert db_company.size == company.size
      assert db_company.website_url == company.website_url
      assert db_company.admin_user_id == company.admin_user_id
    end

    test "change_company/1 returns a company changeset" do
      company = company_fixture()
      assert %Ecto.Changeset{} = Companies.change_company(company)
    end

    test "change_company/2 with attrs returns a company changeset" do
      company = company_fixture()
      attrs = %{name: "updated name"}
      changeset = Companies.change_company(company, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "updated name"
    end
  end
end
