defmodule BemedaPersonal.CompaniesTest do
  use BemedaPersonal.DataCase, async: true

  import BemedaPersonal.AccountsFixtures
  import BemedaPersonal.CompaniesFixtures

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
    user = user_fixture()
    company = company_fixture(user)
    %{user: user, company: company}
  end

  describe "list_companies/0" do
    test "returns all companies", %{company: company, user: user} do
      results = Companies.list_companies()

      assert length(results) >= 1

      our_company = Enum.find(results, &(&1.id == company.id))
      assert our_company
      assert our_company.admin_user_id == user.id
      assert our_company.name == company.name
    end

    test "returns empty list when no companies exist" do
      Repo.delete_all(Company)

      assert Companies.list_companies() == []
    end
  end

  describe "get_company!/1" do
    test "returns the company with given id", %{company: company, user: user} do
      result = Companies.get_company!(company.id)

      assert company.id == result.id
      assert company.name == result.name
      assert company.admin_user_id == user.id
    end

    test "raises Ecto.NoResultsError if company does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(non_existent_id)
      end
    end
  end

  describe "get_company_by_user/1" do
    test "returns the company for a user", %{user: user, company: company} do
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
    test "with valid data creates a company", %{user: user} do
      valid_attrs = %{
        name: "some name",
        size: "some size",
        description: "some description",
        location: "some location",
        industry: "some industry",
        website_url: "https://example.com",
        logo_url: "some logo_url"
      }

      company = company_fixture(user, valid_attrs)
      assert company.name == "some name"
      assert company.size == "some size"
      assert company.description == "some description"
      assert company.admin_user_id == user.id
    end

    test "with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(user, @invalid_attrs)
    end

    test "broadcasts company_created event when creating a company", %{user: user} do
      Endpoint.subscribe("company:#{user.id}")

      valid_attrs = %{
        name: "Test Company",
        industry: "Healthcare",
        location: "Zurich, Switzerland"
      }

      {:ok, company} = Companies.create_company(user, valid_attrs)

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
    test "with valid data updates the company", %{company: company} do
      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %Company{} = company_1} = Companies.update_company(company, update_attrs)

      assert company_1.name == "some updated name"
      assert company_1.size == company.size
    end

    test "with invalid data returns error changeset", %{company: company} do
      assert {:error, %Ecto.Changeset{}} =
               Companies.update_company(company, @invalid_attrs)
    end

    test "broadcasts company_updated event when updating a company", %{
      company: company,
      user: user
    } do
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
    test "returns a company changeset", %{company: company} do
      assert %Ecto.Changeset{} = Companies.change_company(company)
    end

    test "with attrs returns a company changeset", %{company: company} do
      attrs = %{name: "updated name"}
      changeset = Companies.change_company(company, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "updated name"
    end
  end
end
