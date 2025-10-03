defmodule BemedaPersonal.CompaniesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Companies` context.
  """

  alias BemedaPersonal.Accounts.Scope
  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type user :: User.t()

  @spec company_fixture(user(), attrs()) :: company()
  def company_fixture(user, attrs \\ %{})

  def company_fixture(%User{user_type: :employer} = user, attrs) do
    company_attrs =
      Enum.into(attrs, %{
        description: "some description",
        industry: "some industry",
        location: "some location",
        name: "some name",
        phone_number: "+41234738475",
        size: "some size",
        website_url: "https://example.com"
      })

    scope = Scope.for_user(user)
    {:ok, company} = Companies.create_company(scope, company_attrs)

    company
  end

  def company_fixture(%User{user_type: user_type}, _attrs) when user_type != :employer do
    raise ArgumentError,
          "company_fixture requires an employer user, got user_type: #{inspect(user_type)}. Use employer_user_fixture() instead."
  end

  @doc """
  Generate a company with a default employer user
  """
  @spec company_fixture() :: company()
  def company_fixture do
    employer = BemedaPersonal.AccountsFixtures.employer_user_fixture()
    company_fixture(employer)
  end
end
