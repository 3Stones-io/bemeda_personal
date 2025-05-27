defmodule BemedaPersonal.CompaniesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BemedaPersonal.Companies` context.
  """

  alias BemedaPersonal.Accounts.User
  alias BemedaPersonal.Companies

  @type attrs :: map()
  @type company :: Companies.Company.t()
  @type user :: User.t()

  @spec company_fixture(user(), attrs()) :: company()
  def company_fixture(%User{} = user, attrs \\ %{}) do
    company_attrs =
      Enum.into(attrs, %{
        description: "some description",
        industry: "some industry",
        location: "some location",
        name: "some name",
        size: "some size",
        website_url: "some website_url"
      })

    {:ok, company} = Companies.create_company(user, company_attrs)

    company
  end
end
